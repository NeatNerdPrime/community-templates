# Extreme AP SNMP — Zabbix Template

## Overview

This repository contains a Zabbix 6.4 template for monitoring **Extreme Networks Access Points** running **IQ Engine (HiveOS)** via SNMPv3. Tested on AP130 and AP4000-WW with IQ Engine 10.8r5.

---

## Templates Included

| Template Name | Description |
|---|---|
| **Extreme AP SNMP** | Monitors AP-level metrics: client count, CPU, firmware, interfaces, uptime, MAC, serial, and more via the Aerohive MIB. |

---

## Macros Used

| Macro | Default | Description |
|---|---|---|
| `{$AP_CLIENT_HIGH}` | `150` | Client count threshold for warning alert |
| `{$CPU_HIGH}` | `95` | CPU threshold for critical alert |
| `{$CPU_WARN}` | `80` | CPU threshold for warning alert |
| `{$IF_ERRORS_WARN}` | `10` | Interface error rate threshold for warning |

---

## Discovery Rules

| Name | Description | Type | Key |
|---|---|---|---|
| **Network Interface Discovery** | Discovers physical interfaces filtered to `eth0` and `wifi0–wifi2` only | `SNMP_AGENT` | `net.if.discovery` |

### Network Interface Discovery

- **OID**: `discovery[{#IFINDEX}, {#IFNAME}, {#IFALIAS}, {#IFTYPE}]` (IF-MIB)
- **Filter**: `{#IFNAME}` matches `^(eth0|wifi[0-9])$` AND `{#IFTYPE}` = `6` (ethernetCsmacd)

**Item Prototypes**

| Name | Key | Units | Notes |
|---|---|---|---|
| Interface {#IFNAME}: In Traffic | `net.if.in[{#IFNAME}]` | bps | CHANGE_PER_SECOND × 8 |
| Interface {#IFNAME}: Out Traffic | `net.if.out[{#IFNAME}]` | bps | CHANGE_PER_SECOND × 8 |
| Interface {#IFNAME}: In Errors | `net.if.in.errors[{#IFNAME}]` | eps | CHANGE_PER_SECOND |
| Interface {#IFNAME}: Out Errors | `net.if.out.errors[{#IFNAME}]` | eps | CHANGE_PER_SECOND |
| Interface {#IFNAME}: In Discards | `net.if.in.discards[{#IFNAME}]` | pps | CHANGE_PER_SECOND |
| Interface {#IFNAME}: Out Discards | `net.if.out.discards[{#IFNAME}]` | pps | CHANGE_PER_SECOND |
| Interface {#IFNAME}: Speed | `net.if.speed[{#IFNAME}]` | Mbps | — |
| Interface {#IFNAME}: Operational Status | `net.if.status[{#IFNAME}]` | — | Mapped via IF-MIB::ifOperStatus |

---

## Items Collected

| Name | Key | Interval | Type | Notes |
|---|---|---|---|---|
| AP Total Client Count | `ap.clients.total` | 3m | SNMP_AGENT | All radios/SSIDs combined |
| AP CPU Utilization | `ap.cpu.util` | 3m | SNMP_AGENT | % — Aerohive MIB |
| AP Firmware Version | `ap.firmware` | 1h | SNMP_AGENT | IQ Engine build string |
| AP Hardware Version | `ap.hw.version` | 1h | SNMP_AGENT | Hardware revision |
| AP MAC Address | `ap.mac` | 1h | SNMP_AGENT | Base MAC |
| AP Management IP | `ap.mgmt.ip` | 1h | SNMP_AGENT | Management-plane IP |
| AP Model | `ap.model` | 1h | SNMP_AGENT | e.g. AP4000-WW |
| AP Number of Radios | `ap.radio.count` | 1h | SNMP_AGENT | Total radio count |
| AP Radio Signal Info | `ap.radio.rssi` | 5m | SNMP_AGENT | RSSI string per radio |
| AP Serial Number | `ap.serial` | 1h | SNMP_AGENT | Aerohive serial |
| AP Uptime String | `ap.uptime.string` | 5m | SNMP_AGENT | Human-readable uptime |
| System Uptime | `system.uptime` | 5m | SNMP_AGENT | sysUpTime (timeticks) |
| System Name | `system.name` | 1h | SNMP_AGENT | sysName |
| System Description | `system.descr` | 1h | SNMP_AGENT | Product/firmware info |
| System Location | `system.location` | 1h | SNMP_AGENT | sysLocation |
| System Contact | `system.contact` | 1h | SNMP_AGENT | sysContact |

---

## Triggers

| Name | Expression | Severity |
|---|---|---|
| High client count on AP {HOST.NAME} | `last(ap.clients.total) > {$AP_CLIENT_HIGH}` | WARNING |
| High CPU utilization on AP {HOST.NAME} | `avg(ap.cpu.util, 5m) > {$CPU_WARN}` | WARNING |
| Critical CPU utilization on AP {HOST.NAME} | `avg(ap.cpu.util, 5m) > {$CPU_HIGH}` | HIGH |
| AP {HOST.NAME} has been restarted | `last(system.uptime) < 600` | WARNING (manual close) |
| High error rate on {#IFNAME} on {HOST.NAME} | `avg(net.if.in.errors[{#IFNAME}], 5m) > {$IF_ERRORS_WARN}` | WARNING |
| Interface {#IFNAME} went DOWN on {HOST.NAME} | `last(net.if.status[{#IFNAME}]) = 2` after being up | AVERAGE |

> CPU triggers use hysteresis — recovery fires when utilization drops back below threshold minus 5%.

---

## Value Maps

| Name | Mapping |
|---|---|
| **IF-MIB::ifOperStatus** | 1 → up, 2 → down, 3 → testing, 5 → dormant, 7 → lowerLayerDown |

---

## Tags

| Tag | Value |
|---|---|
| `class` | software |
| `target` | ap |
| `target` | extreme |
| `target` | wireless |

---

## Compatibility

- **Zabbix version**: 6.4
- **SNMP version**: v3 recommended (template uses `SNMP_AGENT` type throughout)
- **Tested hardware**: Extreme Networks AP130, AP4000-WW
- **Tested firmware**: IQ Engine 10.8r5
- **MIB**: Aerohive / Extreme Networks enterprise MIB (`1.3.6.1.4.1.26928`)
