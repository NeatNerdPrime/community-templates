# Extreme Switch SNMP — Zabbix Template

## Overview

This repository contains a Zabbix 6.4 template for monitoring **Extreme VOSS/Fabric Engine Networks Switches** via SNMP. Collects CPU, memory, interface traffic, errors, utilization, and uptime metrics using the Extreme Networks enterprise MIB and standard IF-MIB.

---

## Templates Included

| Template Name | Description |
|---|---|
| **Extreme Switch SNMP** | Monitors switch-level metrics: CPU, memory, interface traffic/errors/utilization, uptime, and system info. |

---

## Macros Used

| Macro | Default | Description |
|---|---|---|
| `{$CPU_HIGH}` | `95` | CPU threshold for critical alert |
| `{$CPU_WARN}` | `80` | CPU threshold for warning alert |
| `{$MEM_HIGH}` | `95` | Memory utilization threshold for critical alert |
| `{$MEM_WARN}` | `80` | Memory utilization threshold for warning alert |
| `{$IF_ERRORS_WARN}` | `10` | Interface error rate threshold for warning |
| `{$IF_UTIL_WARN}` | `80` | Interface bandwidth utilization threshold for warning |
| `{$SNMP_COMMUNITY}` | — | SNMP community string |

---

## Discovery Rules

| Name | Description | Type | Key |
|---|---|---|---|
| **Network Interface Discovery** | Discovers physical interfaces, excluding management interfaces | `SNMP_AGENT` | `net.if.discovery` |

### Network Interface Discovery

- **OID**: `discovery[{#IFINDEX}, {#IFNAME}, {#IFALIAS}, {#IFTYPE}, {#IFSPEED}]` (IF-MIB)
- **Filter**: `{#IFNAME}` does NOT match `Mgmt` AND `{#IFTYPE}` = `6` (ethernetCsmacd)

**Item Prototypes**

| Name | Key | Units | Type | Notes |
|---|---|---|---|---|
| Interface {#IFNAME} ({#IFALIAS}): In Traffic | `net.if.in[{#IFNAME}]` | bps | SNMP_AGENT | CHANGE_PER_SECOND × 8 |
| Interface {#IFNAME} ({#IFALIAS}): Out Traffic | `net.if.out[{#IFNAME}]` | bps | SNMP_AGENT | CHANGE_PER_SECOND × 8 |
| Interface {#IFNAME} ({#IFALIAS}): In Utilization | `net.if.in.util[{#IFNAME}]` | % | CALCULATED | `in / (speed × 1,000,000) × 100` |
| Interface {#IFNAME} ({#IFALIAS}): Out Utilization | `net.if.out.util[{#IFNAME}]` | % | CALCULATED | `out / (speed × 1,000,000) × 100` |
| Interface {#IFNAME} ({#IFALIAS}): In Errors | `net.if.in.errors[{#IFNAME}]` | eps | SNMP_AGENT | CHANGE_PER_SECOND |
| Interface {#IFNAME} ({#IFALIAS}): Out Errors | `net.if.out.errors[{#IFNAME}]` | eps | SNMP_AGENT | CHANGE_PER_SECOND |
| Interface {#IFNAME} ({#IFALIAS}): In Discards | `net.if.in.discards[{#IFNAME}]` | pps | SNMP_AGENT | CHANGE_PER_SECOND |
| Interface {#IFNAME} ({#IFALIAS}): Out Discards | `net.if.out.discards[{#IFNAME}]` | pps | SNMP_AGENT | CHANGE_PER_SECOND |
| Interface {#IFNAME} ({#IFALIAS}): Speed | `net.if.speed[{#IFNAME}]` | Mbps | SNMP_AGENT | — |
| Interface {#IFNAME} ({#IFALIAS}): Operational Status | `net.if.status[{#IFNAME}]` | — | SNMP_AGENT | Mapped via IF-MIB::ifOperStatus |

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

## Triggers

| Name | Expression | Severity |
|---|---|---|
| High CPU utilization on {HOST.NAME} | `avg(extreme.cpu.util, 5m) > {$CPU_WARN}` | WARNING |
| Critical CPU utilization on {HOST.NAME} | `avg(extreme.cpu.util, 5m) > {$CPU_HIGH}` | HIGH |
| High memory utilization on {HOST.NAME} | `avg(extreme.mem.util, 10m) > {$MEM_WARN}` | WARNING |
| Critical memory utilization on {HOST.NAME} | `avg(extreme.mem.util, 10m) > {$MEM_HIGH}` | HIGH |
| Switch {HOST.NAME} has been restarted | `last(system.uptime) < 600` | WARNING (manual close) |
| High error rate on interface {#IFNAME} on {HOST.NAME} | `avg(net.if.in.errors or out.errors, 5m) > {$IF_ERRORS_WARN}` | WARNING |
| High bandwidth utilization on interface {#IFNAME} on {HOST.NAME} | `avg(net.if.in.util or out.util, 5m) > {$IF_UTIL_WARN}` | WARNING |
| Interface {#IFNAME} went DOWN on {HOST.NAME} | `last(net.if.status[{#IFNAME}]) = 2` after being up | AVERAGE |

> CPU and memory triggers use hysteresis — recovery fires when the value drops back below threshold minus 5%.

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
- **SNMP version**: v2c or v3 (set `{$SNMP_COMMUNITY}` macro accordingly)
- **Tested hardware**: Extreme Networks switches
- **MIB**: Extreme Networks enterprise MIB (`1.3.6.1.4.1.2272`) + standard IF-MIB
