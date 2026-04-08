# Extreme Switch SNMP — Zabbix Template

## Overview

Zabbix 6.4 template for monitoring **Extreme Networks switches running VOSS** via SNMP. Collects CPU, memory, interface traffic, errors, utilization, and uptime using the Extreme Networks enterprise MIB and standard IF-MIB.

**SNMP version**: v2c or v3 supported. Configure the community string or SNMPv3 credentials directly on the host in Zabbix (Administration → Hosts → SNMP interfaces).

---

## Setup

1. Import `extreme_switch_voss.yaml` into Zabbix 6.4 via **Configuration → Templates → Import**.
2. Create or edit a host for your Extreme switch and assign this template.
3. Configure an **SNMP interface** on the host with the correct IP, port (161), and SNMP version/credentials.
4. Adjust the macros below as needed for your environment.

---

## Macros

| Macro | Default | Description |
|---|---|---|
| `{$CPU_HIGH}` | `95` | CPU utilization threshold for critical alert |
| `{$CPU_WARN}` | `80` | CPU utilization threshold for warning alert |
| `{$MEM_HIGH}` | `95` | Memory utilization threshold for critical alert |
| `{$MEM_WARN}` | `80` | Memory utilization threshold for warning alert |
| `{$IF_ERRORS_WARN}` | `10` | Interface error rate (eps) threshold for warning |
| `{$IF_UTIL_HIGH}` | `95` | Interface bandwidth utilization threshold for critical alert |
| `{$IF_UTIL_WARN}` | `80` | Interface bandwidth utilization threshold for warning alert |

---

## Items Collected

| Name | Key | Interval | Type | Notes |
|---|---|---|---|---|
| CPU Utilization | `extreme.cpu.util` | 3m | SNMP_AGENT | % — Extreme enterprise MIB |
| Memory Total | `extreme.mem.total` | 5m | SNMP_AGENT | Bytes |
| Memory Used | `extreme.mem.used` | 5m | SNMP_AGENT | Bytes |
| Memory Utilization | `extreme.mem.util` | 5m | CALCULATED | `used / total × 100` |
| System Uptime | `system.uptime` | 5m | SNMP_AGENT | sysUpTime (timeticks) |
| System Name | `system.name` | 1h | SNMP_AGENT | sysName |
| System Description | `system.descr` | 1h | SNMP_AGENT | sysDescr |
| System Location | `system.location` | 1h | SNMP_AGENT | sysLocation |

---

## Discovery Rules

| Name | Type | Key | Interval |
|---|---|---|---|
| Network Interface Discovery | SNMP_AGENT | `net.if.discovery` | 1h |

**Filter**: `{#IFNAME}` does NOT match `Mgmt` AND `{#IFTYPE}` = `6` (ethernetCsmacd only, management interfaces excluded)

### Interface Item Prototypes

| Name | Key | Units | Notes |
|---|---|---|---|
| Interface {#IFNAME} ({#IFALIAS}): In Traffic | `net.if.in[{#IFNAME}]` | bps | CHANGE_PER_SECOND × 8 |
| Interface {#IFNAME} ({#IFALIAS}): Out Traffic | `net.if.out[{#IFNAME}]` | bps | CHANGE_PER_SECOND × 8 |
| Interface {#IFNAME} ({#IFALIAS}): In Utilization | `net.if.in.util[{#IFNAME}]` | % | `in / (speed × 1,000,000) × 100` |
| Interface {#IFNAME} ({#IFALIAS}): Out Utilization | `net.if.out.util[{#IFNAME}]` | % | `out / (speed × 1,000,000) × 100` |
| Interface {#IFNAME} ({#IFALIAS}): In Errors | `net.if.in.errors[{#IFNAME}]` | eps | CHANGE_PER_SECOND |
| Interface {#IFNAME} ({#IFALIAS}): Out Errors | `net.if.out.errors[{#IFNAME}]` | eps | CHANGE_PER_SECOND |
| Interface {#IFNAME} ({#IFALIAS}): In Discards | `net.if.in.discards[{#IFNAME}]` | pps | CHANGE_PER_SECOND |
| Interface {#IFNAME} ({#IFALIAS}): Out Discards | `net.if.out.discards[{#IFNAME}]` | pps | CHANGE_PER_SECOND |
| Interface {#IFNAME} ({#IFALIAS}): Speed | `net.if.speed[{#IFNAME}]` | Mbps | ifHighSpeed |
| Interface {#IFNAME} ({#IFALIAS}): Operational Status | `net.if.status[{#IFNAME}]` | — | Mapped via IF-MIB::ifOperStatus, polled every 1m |

---

## Triggers

| Name | Severity | Notes |
|---|---|---|
| Critical CPU utilization on {HOST.NAME} | HIGH | avg 5m > `{$CPU_HIGH}`; hysteresis −5% |
| High CPU utilization on {HOST.NAME} | WARNING | avg 5m > `{$CPU_WARN}`; hysteresis −5% |
| Critical memory utilization on {HOST.NAME} | HIGH | avg 10m > `{$MEM_HIGH}`; hysteresis −5% |
| High memory utilization on {HOST.NAME} | WARNING | avg 10m > `{$MEM_WARN}`; hysteresis −5% |
| Switch {HOST.NAME} has been restarted | WARNING | `last(system.uptime) < 600`; manual close |
| Critical bandwidth utilization on interface {#IFNAME} | HIGH | avg 5m in or out > `{$IF_UTIL_HIGH}` |
| High bandwidth utilization on interface {#IFNAME} | WARNING | avg 5m in or out > `{$IF_UTIL_WARN}` |
| High error rate on interface {#IFNAME} | WARNING | avg 5m in or out errors > `{$IF_ERRORS_WARN}` |
| Interface {#IFNAME} went DOWN on {HOST.NAME} | AVERAGE | status = 2 after being up; auto-recovers |

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
| `target` | extreme |
| `target` | switch |

---

## Compatibility

- **Zabbix version**: 6.4
- **SNMP version**: v2c or v3
- **Tested hardware**: Extreme Networks switches running VOSS
- **MIBs used**: Extreme Networks enterprise MIB (`1.3.6.1.4.1.2272`) + IF-MIB
- **Author** Jon McLaughlin
