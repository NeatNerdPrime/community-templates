***

# IBM FlashSystem / Storwize (V7K) Monitoring for Zabbix (SSH + LLD)

This repository provides a **Zabbix External Check solution** for monitoring **IBM FlashSystem / Storwize / SVC (V7K family)** systems via **SSH**.

###Author

Rosen Georgiev (rosen.georgiev1@ibm.com)
https://github.com/rgeorgie

### Disclaimer

This project is an independent open source work.
It is not an official IBM product and is not supported by IBM.

***

## Supported Zabbix versions

| Component             | Version                              |
| --------------------- | ------------------------------------ |
| Zabbix Server / Proxy | **6.2.x**                            |
| Template format       | YAML                                 |
| Item type             | External check                       |
| Discovery format      | JSON array (Zabbix ≥ 4.2 compatible) |

***

## How it works (high level)

1.  Zabbix runs `v7k_zbx.sh` as an **External Check**
2.  The script connects to the V7K system via **SSH**
3.  For discovery modes:
    *   SSH **stderr is fully suppressed**
    *   Output is **guaranteed valid JSON**
    *   Only **numeric IDs** are accepted
4.  Zabbix LLD creates items & triggers from prototypes

***

## Repository layout

    .
    ├── files/v7k_zbx.sh
    ├── template_ibm_v7k_ssh_external_6.2.yaml
    └── README.md

***

## Installation

### 1️⃣ Install the external script

Copy the script to the Zabbix external scripts directory:

```bash
cp files/v7k_zbx.sh /usr/lib/zabbix/externalscripts/
chown zabbix:zabbix /usr/lib/zabbix/externalscripts/v7k_zbx.sh
chmod 755 /usr/lib/zabbix/externalscripts/v7k_zbx.sh
```

Confirm your server config:

```bash
grep ^ExternalScripts /etc/zabbix/zabbix_server.conf
```

Expected:

    ExternalScripts=/usr/lib/zabbix/externalscripts

***

### 2️⃣ Prepare SSH environment (IMPORTANT)

Prevent SSH warnings that break discovery:

```bash
mkdir -p /var/lib/zabbix/.ssh
chown zabbix:zabbix /var/lib/zabbix/.ssh
chmod 700 /var/lib/zabbix/.ssh
```

***

### 3️⃣ Test SSH manually (as Zabbix user)

#### Password authentication

```bash
sudo -u zabbix ssh zabbix@<V7K_IP> svcinfo lsdrive
```

#### SSH key authentication

```bash
sudo -u zabbix ssh -i /var/lib/zabbix/.ssh/v7k_id_ed25519 zabbix@<V7K_IP> svcinfo lsnode
```

✅ These **must work** before using Zabbix.

***

## Zabbix Template Import

1.  Go to  
    **Data collection → Templates → Import**
2.  Import  
    `template_ibm_v7k_ssh_external_6.2.yaml`
3.  Group used: **Templates** (exists by default)

***

## Host configuration

### Interface (mandatory)

Zabbix resolves `{HOST.CONN}` from the host interface.

*   Interface type: **Agent**
*   Connect to: **IP**
*   IP address: `<V7K management IP>`
*   Port: `10050` (value irrelevant, required by UI)

***

### Host macros

Set **on the host**, not the template:

| Macro             | Description                                             |
| ----------------- | ------------------------------------------------------- |
| `{$V7K.USER}`     | SSH user                                                |
| `{$V7K.PORT}`     | SSH port (default `22`)                                 |
| `{$V7K.PASSWORD}` | SSH password (leave empty if using key)                 |
| `{$V7K.SSH_KEY}`  | Path to SSH private key (leave empty if using password) |

✅ Use **only one authentication method**.

***

## Discovery modes

The script supports:

| Mode                    | Description         |
| ----------------------- | ------------------- |
| `discover.drives`       | Discover drives     |
| `discover.nodes`        | Discover nodes      |
| `discover.enclosures`   | Discover enclosures |
| `drive.status <id>`     | Drive status        |
| `node.status <id>`      | Node status         |
| `enclosure.status <id>` | Enclosure status    |

Example (manual test):

```bash
sudo -u zabbix \
  /usr/lib/zabbix/externalscripts/v7k_zbx.sh \
  <V7K_IP> zabbix PASSWORD discover.nodes
```

Expected output:

```json
[
  {"{#NODE_ID}":"1"},
  {"{#NODE_ID}":"2"}
]
```

***

## Why discovery never breaks (important design)

### ✅ Numeric‑only discovery

Only IDs matching:

    ^[0-9]+$

are accepted.

This **prevents** discovery of:

*   `Could`
*   `Warning`
*   `Permission`
*   Any SSH error text

***

### ✅ Discovery JSON is always valid

*   SSH stderr is suppressed **only for discovery**
*   On failure, discovery returns:

```json
[]
```

—not broken JSON

***

## Cleaning up old broken discoveries

If you previously had items like:

    V7K: Node Could status

They will be removed automatically:

1.  Fix script + SSH environment
2.  Run **“Check now”** on discovery rules
3.  (Optional) Temporarily lower **Keep lost resources** period

***

## Security recommendations

*   Create a **read‑only V7K user**:
        mkuser -name zabbix -role Monitor
*   Prefer **SSH key authentication**
*   Do not allow interactive shells if not required

***

## Troubleshooting

### ❌ `Invalid discovery rule value`

✅ Cause: SSH stderr leaked into discovery  
✅ Fix: Ensure `.ssh` directory exists and script is updated

***

### ❌ No discovered items

✅ Check:

*   Template linked to host
*   Host interface exists
*   Discovery rule executed (“Check now”)

***

### ❌ `Permission denied` / SSH fails

✅ Test SSH **as `zabbix` user**, not root

***

This template and script intentionally implement several non‑obvious but critical design choices required for stable monitoring of IBM FlashSystem / Storwize / SVC (V7K family) with Zabbix External Checks.
1. Zabbix external checks merge stdout + stderr (critical)
Zabbix always concatenates STDOUT and STDERR from external scripts into a single item value.
Implications:

Any SSH warning, banner, MOTD, or error text will:

break JSON Low‑Level Discovery
cause numeric items to be converted to 0



What we do:

Discovery and numeric modes use a quiet SSH runner that suppresses stderr entirely
Text items (status strings) may still use normal SSH output

✅ This is why the script has two SSH paths:

ssh_run_quiet → discovery + numeric values
ssh_run → text/status values


2. Low‑Level Discovery outputs a root JSON array (by design)
All discovery commands return JSON in the form:
JSON[  {"{#DRIVE_ID}":"0"},  {"{#DRIVE_ID}":"1"}]Show more lines
This is intentional and correct.
Zabbix (≥ 4.2) explicitly supports root‑level JSON arrays for LLD.
No { "data": [...] } wrapper is required.

3. Discovery filters numeric IDs only (prevents bogus objects)
All discovery logic accepts numeric IDs only:
Plain Text^[0-9]+$Show more lines
This prevents classic failures such as discovering objects named:

Could
Permission
Warning

…which can occur if any non‑JSON text ever leaks into discovery output.

4. FC port alerting logic is intentionally strict (important)
IBM lsportfc reports multiple port states:

StatusMeaningAlert?activePort up❌inactive_unconfiguredUnused port (normal)❌inactive_configuredConfigured but link down✅disabledAdministratively disabled✅
Why this matters:

FlashSystem systems often ship with many unused FC ports
Alerting on inactive_unconfigured causes constant false positives

What we do:

FC port triggers fire only when status is:

inactive_configured
disabled



This matches real‑world storage operations expectations and avoids alert fatigue.

5. Pool capacity & thin‑provisioning logic
The template monitors thin‑provisioning risk using two complementary signals:
Pool‑level:

pool.free_pct
pool.overcommit_pct
(sum of provisioned vdisk capacity ÷ pool capacity)

Volume‑level:

vdisk.alloc_gt_prov
(internal_capacity > provisioned capacity)

This combination detects:

real capacity exhaustion
silent thin over‑commit
pathological allocation anomalies


6. Empty macros and positional arguments (Zabbix quirk)
Zabbix passes empty macros as empty positional arguments, which can shift parameters.
Mitigation:

The script tolerates empty SSH key macros
It is safe to set:
Plain Text{$V7K.SSH_KEY} = NAShow more lines
when using password authentication


7. Required host configuration
For items to populate correctly, the monitored host must have:

A host interface (any type) so {HOST.CONN} resolves
Host macros set:

{$V7K.USER}
{$V7K.PASSWORD} or {$V7K.SSH_KEY}
{$V7K.PORT}




8. Recommended validation steps after import
After linking the template:

Go to Host → Discovery
Click “Check now” for:

Drive discovery
Pool discovery
FC Port discovery


Verify that:

No discovery errors appear
FC ports in inactive_unconfigured do not raise problems
Pool percentages show non‑zero values




9. Why this template looks “opinionated”
Every decision above exists because:

Zabbix external checks are unforgiving
FlashSystem environments have many “normal but inactive” components
Storage alert fatigue is worse than missing alerts

This template favors:
✅ Signal over noise
✅ Predictable behavior
✅ Audit‑friendly logic

