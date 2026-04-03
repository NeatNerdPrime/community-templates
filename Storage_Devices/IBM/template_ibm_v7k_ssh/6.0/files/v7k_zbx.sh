#!/usr/bin/env bash
set -euo pipefail

# Cleaned final v7k_zbx.sh
# - Zabbix external checks merge stdout+stderr into item value. Keep stdout clean. 
# - For LLD, always emit valid JSON array at root. [2](https://community.ibm.com/community/user/discussion/storewize-v3700-lost-access-factory-reset)
# - Filter discovered IDs to numeric only to prevent garbage objects ("Could"). 

die() { echo "ZBX_ERROR: $*" >&2; exit 2; }

HOST="${1:-}"; USER="${2:-}"; PASS="${3:-}"
[[ -n "$HOST" && -n "$USER" ]] || die "Usage: HOST USER PASS [PORT KEY] MODE [ARGS...]"

PORT="22"; KEY=""; MODE=""

# Supports:
#  A) short: HOST USER PASS MODE [args...]
#  B) full : HOST USER PASS PORT KEY MODE [args...]
if [[ "${4:-}" == *.* ]]; then
  MODE="${4:-}"
  shift 4 || true
else
  PORT="${4:-22}"
  KEY="${5:-}"
  MODE="${6:-}"
  shift 6 || true
fi

[[ -n "$MODE" ]] || die "Missing MODE"

# Prevent ssh trying to create ~/.ssh under /var/lib/zabbix
export HOME="/tmp"

SSH_OPTS=(
  -p "$PORT"
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o GlobalKnownHostsFile=/dev/null
  -o LogLevel=ERROR
  -o ConnectTimeout=10
  -o ServerAliveInterval=10
  -o ServerAliveCountMax=2
  -o BatchMode=no
)

# --------------------------
# SSH runners
# --------------------------
# ssh_run: for TEXT outputs; still keeps stderr captured to diagnose if needed.
ssh_run() {
  local cmd="$1" out rc
  if [[ -n "$KEY" && -r "$KEY" ]]; then
    out=$(ssh "${SSH_OPTS[@]}" -o BatchMode=yes -o IdentitiesOnly=yes -i "$KEY" \
      "${USER}@${HOST}" "$cmd" </dev/null 2>&1) || rc=$?
    rc="${rc:-0}"
    [[ "$rc" -eq 0 ]] && { printf "%s" "$out"; return 0; }
  fi

  [[ -n "$PASS" ]] || die "No SSH key (or it failed) and no password provided"

  local askpass
  askpass="$(mktemp /tmp/v7k_askpass.XXXXXX)" || die "Cannot create askpass"
  cat >"$askpass" <<'EOF'
#!/bin/sh
echo "$SSH_ASKPASS_PASSWORD"
EOF
  chmod 700 "$askpass"

  out=$(
    DISPLAY=dummy SSH_ASKPASS="$askpass" SSH_ASKPASS_PASSWORD="$PASS" \
    /usr/bin/setsid -w ssh "${SSH_OPTS[@]}" \
      -o PreferredAuthentications=password \
      -o PasswordAuthentication=yes \
      -o KbdInteractiveAuthentication=no \
      -o PubkeyAuthentication=no \
      -o IdentitiesOnly=yes \
      "${USER}@${HOST}" "$cmd" </dev/null 2>&1
  ) || rc=$?

  rm -f "$askpass"
  rc="${rc:-0}"
  [[ "$rc" -ne 0 ]] && die "SSH command failed: $out"
  printf "%s" "$out"
}

# ssh_run_quiet: for DISCOVERY and NUMERIC outputs — suppress stderr completely.
# This avoids JSON parse errors and numeric conversion-to-0 problems in Zabbix. [1](https://teams.microsoft.com/l/meeting/details?eventId=AAMkAGIwNTI5YTZlLTM1ZTQtNDE3MS1hZmQ1LTczYTZiMGQxMTI4ZgBGAAAAAAAFnw6DG7orQoQwk4cl0bNBBwDCw56k3PKrQJreEZIvkk2-AAAAAAENAADCw56k3PKrQJreEZIvkk2-AAZmLC9wAAA%3d)
ssh_run_quiet() {
  local cmd="$1" out rc
  if [[ -n "$KEY" && -r "$KEY" ]]; then
    out=$(ssh "${SSH_OPTS[@]}" -o BatchMode=yes -o IdentitiesOnly=yes -i "$KEY" \
      "${USER}@${HOST}" "$cmd" </dev/null 2>/dev/null) || rc=$?
    rc="${rc:-0}"
    [[ "$rc" -eq 0 ]] && { printf "%s" "$out"; return 0; }
  fi

  [[ -n "$PASS" ]] || return 1

  local askpass
  askpass="$(mktemp /tmp/v7k_askpass.XXXXXX)" || return 1
  cat >"$askpass" <<'EOF'
#!/bin/sh
echo "$SSH_ASKPASS_PASSWORD"
EOF
  chmod 700 "$askpass"

  out=$(
    DISPLAY=dummy SSH_ASKPASS="$askpass" SSH_ASKPASS_PASSWORD="$PASS" \
    /usr/bin/setsid -w ssh "${SSH_OPTS[@]}" \
      -o PreferredAuthentications=password \
      -o PasswordAuthentication=yes \
      -o KbdInteractiveAuthentication=no \
      -o PubkeyAuthentication=no \
      -o IdentitiesOnly=yes \
      "${USER}@${HOST}" "$cmd" </dev/null 2>/dev/null
  ) || rc=$?

  rm -f "$askpass"
  rc="${rc:-0}"
  [[ "$rc" -ne 0 ]] && return 1
  printf "%s" "$out"
}

SVCINFO="svcinfo"

# --------------------------
# Table parsing helpers (-delim :)
# --------------------------
# Use headers to locate columns. Works across versions as long as header names exist.

table_get_field_by_id_quiet() {
  # $1: command (includes -delim :)
  # $2: id_value
  # $3: field_name
  local cmd="$1" id="$2" field="$3"
  ssh_run_quiet "$cmd" | awk -F: -v id="$id" -v want="$field" '
    function norm(s){ gsub(/^[ \t]+|[ \t]+$/, "", s); return tolower(s) }
    NR==1{
      for(i=1;i<=NF;i++) h[norm($i)]=i
      next
    }
    {
      if (("id" in h) && norm($(h["id"]))==norm(id)) {
        f=norm(want)
        if (f in h) print $(h[f])
        exit
      }
    }'
}

# LLD: output root JSON array (Zabbix ≥4.2). [2](https://community.ibm.com/community/user/discussion/storewize-v3700-lost-access-factory-reset)
lld_from_table_numeric_id() {
  # $1 cmd, $2 macro_id, $3 macro_name(optional), $4 name_field(default "name")
  local cmd="$1" mid="$2" mname="${3:-}" namefield="${4:-name}"
  local out
  out="$(ssh_run_quiet "$cmd")" || { echo "[]"; return 0; }

  echo "["
  echo "$out" | awk -F: -v mid="$mid" -v mname="$mname" -v namefield="$namefield" '
    function norm(s){ gsub(/^[ \t]+|[ \t]+$/, "", s); return tolower(s) }
    function esc(s){ gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); return s }
    NR==1{
      for(i=1;i<=NF;i++) h[norm($i)]=i
      next
    }
    {
      idcol = ("id" in h) ? h["id"] : 1
      id=$(idcol); gsub(/^[ \t]+|[ \t]+$/, "", id)
      if (id !~ /^[0-9]+$/) next   # numeric-only safety

      name=""
      if (mname != "" && (norm(namefield) in h)) {
        name=$(h[norm(namefield)]); gsub(/^[ \t]+|[ \t]+$/, "", name)
      }

      obj="{\"" mid "\":\"" esc(id) "\""
      if (mname != "" && name != "") obj=obj ",\"" mname "\":\"" esc(name) "\""
      obj=obj "}"
      print obj
    }' | awk 'BEGIN{first=1}{ if(!first)print ","; first=0; print }'
  echo "]"
}

# Sum vdisk provisioned capacity for a pool in bytes (for overcommit %)
pool_sum_vdisk_capacity_bytes() {
  local pool_id="$1"
  local out
  out="$(ssh_run_quiet "svcinfo lsvdisk -delim : -bytes -filtervalue mdisk_grp_id=$pool_id")" || { echo "0"; return 0; }

  echo "$out" | awk -F: '
    function norm(s){ gsub(/^[ \t]+|[ \t]+$/, "", s); return tolower(s) }
    NR==1{ for(i=1;i<=NF;i++) h[norm($i)]=i; next }
    {
      cap = $(h["capacity"])
      gsub(/^[ \t]+|[ \t]+$/, "", cap)
      if (cap ~ /^[0-9]+$/) sum += cap
    }
    END{ printf "%.0f\n", sum+0 }'
}

# --------------------------
# Modes
# --------------------------
case "$MODE" in
  # --- existing ---
  discover.drives)     lld_from_table_numeric_id "svcinfo lsdrive -delim :" "{#DRIVE_ID}" ;;
  discover.nodes)      lld_from_table_numeric_id "svcinfo lsnode -delim :" "{#NODE_ID}" ;;
  discover.enclosures) lld_from_table_numeric_id "svcinfo lsenclosure -delim :" "{#ENCLOSURE_ID}" ;;

  drive.status)
    [[ $# -ge 1 ]] || die "drive.status requires <drive_id>"
    ssh_run "svcinfo lsdrive $1" | awk '$1=="status"{print $2; exit}'
    ;;

  node.status)
    [[ $# -ge 1 ]] || die "node.status requires <node_id>"
    ssh_run "svcinfo lsnode $1" | awk '$1=="status"{print $2; exit}'
    ;;

  enclosure.status)
    [[ $# -ge 1 ]] || die "enclosure.status requires <enclosure_id>"
    ssh_run "svcinfo lsenclosure $1" | awk '$1=="status"{print $2; exit}'
    ;;

  # --- pools (lsmdiskgrp) ---
  discover.pools)
    # lsmdiskgrp supports -bytes and -delim. [3](https://deverrors.com/errors/sshd-disconnecting-too-many-auth-failures)
    lld_from_table_numeric_id "svcinfo lsmdiskgrp -delim : -bytes" "{#POOL_ID}" "{#POOL_NAME}" "name"
    ;;

  pool.free_pct)
    [[ $# -ge 1 ]] || die "pool.free_pct requires <pool_id>"
    cap="$(table_get_field_by_id_quiet "svcinfo lsmdiskgrp -delim : -bytes" "$1" "capacity")"
    free="$(table_get_field_by_id_quiet "svcinfo lsmdiskgrp -delim : -bytes" "$1" "free_capacity")"
    if [[ "$cap" =~ ^[0-9]+$ && "$free" =~ ^[0-9]+$ && "$cap" -gt 0 ]]; then
      awk -v f="$free" -v c="$cap" 'BEGIN{printf "%.2f\n",(f*100.0)/c}'
    else
      echo "0"
    fi
    ;;

  pool.overcommit_pct)
    [[ $# -ge 1 ]] || die "pool.overcommit_pct requires <pool_id>"
    cap="$(table_get_field_by_id_quiet "svcinfo lsmdiskgrp -delim : -bytes" "$1" "capacity")"
    sum="$(pool_sum_vdisk_capacity_bytes "$1")"
    if [[ "$cap" =~ ^[0-9]+$ && "$cap" -gt 0 ]]; then
      awk -v s="$sum" -v c="$cap" 'BEGIN{printf "%.2f\n",(s*100.0)/c}'
    else
      echo "0"
    fi
    ;;

  # --- FC ports (lsportfc) ---
  discover.fcports)
    # lsportfc fields (status, port_speed, node_name, WWPN...) documented by IBM. [4](https://www.redhat.com/en/blog/arguments-options-bash-scripts)
    lld_from_table_numeric_id "svcinfo lsportfc -delim :" "{#FCPORT_ID}" "{#FCPORT_WWPN}" "wwpn"
    ;;

  fcport.status)
    [[ $# -ge 1 ]] || die "fcport.status requires <fcport_id>"
    v="$(table_get_field_by_id_quiet "svcinfo lsportfc -delim :" "$1" "status")"
    [[ -n "$v" ]] && echo "$v" || echo "unknown"
    ;;

  fcport.speed)
    [[ $# -ge 1 ]] || die "fcport.speed requires <fcport_id>"
    v="$(table_get_field_by_id_quiet "svcinfo lsportfc -delim :" "$1" "port_speed")"
    [[ -n "$v" ]] && echo "$v" || echo "N/A"
    ;;

  # --- volumes (lsvdisk) ---
  discover.vdisks)
    # Root JSON array accepted by Zabbix LLD. [2](https://community.ibm.com/community/user/discussion/storewize-v3700-lost-access-factory-reset)
    out="$(ssh_run_quiet "svcinfo lsvdisk -delim : -bytes")" || { echo "[]"; exit 0; }
    echo "["
    echo "$out" | awk -F: '
      function norm(s){ gsub(/^[ \t]+|[ \t]+$/, "", s); return tolower(s) }
      function esc(s){ gsub(/\\/,"\\\\",s); gsub(/"/,"\\\"",s); return s }
      NR==1{ for(i=1;i<=NF;i++) h[norm($i)]=i; next }
      {
        id=$(h["id"]); gsub(/^[ \t]+|[ \t]+$/, "", id)
        if (id !~ /^[0-9]+$/) next
        name=$(h["name"]); gsub(/^[ \t]+|[ \t]+$/, "", name)
        obj="{\"{#VDISK_ID}\":\"" esc(id) "\",\"{#VDISK_NAME}\":\"" esc(name) "\"}"
        print obj
      }' | awk 'BEGIN{first=1}{ if(!first)print ","; first=0; print }'
    echo "]"
    ;;

  vdisk.alloc_gt_prov)
    [[ $# -ge 1 ]] || die "vdisk.alloc_gt_prov requires <vdisk_id>"
    # IBM docs: internal_capacity may exceed provisioned capacity in some cases. [5](https://mhdez.com/notes/forcing-ssh-to-use-a-specific-key-with-identitiesonly/)
    cap="$(table_get_field_by_id_quiet "svcinfo lsvdisk -delim : -bytes" "$1" "capacity")"
    icap="$(table_get_field_by_id_quiet "svcinfo lsvdisk -delim : -bytes" "$1" "internal_capacity")"
    if [[ "$cap" =~ ^[0-9]+$ && "$icap" =~ ^[0-9]+$ && "$icap" -gt "$cap" ]]; then
      echo "1"
    else
      echo "0"
    fi
    ;;

  *)
    die "Unknown mode '$MODE'"
    ;;
esac
