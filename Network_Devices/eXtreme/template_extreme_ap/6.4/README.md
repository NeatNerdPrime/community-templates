# Extreme AP SNMP — Zabbix Template

## Overview

Zabbix 6.4 template for monitoring **Extreme Networks Access Points running IQ Engine (HiveOS)** via SNMPv3. Collects client count, CPU, firmware, interface traffic/errors, uptime, and system inventory via the Aerohive enterprise MIB and standard IF-MIB.

Tested on **AP130** and **AP4000-WW** with **IQ Engine 10.8r5**.

**SNMP version**: SNMPv3 recommended. Configure credentials directly on the host in Zabbix (Administration → Hosts → SNMP interfaces).

---

## Setup

1. Import `template_extreme_ap130-4000.yaml` into Zabbix 6.4 via **Configuration → Templates → Import**.
2. Create or edit a host for your Extreme AP and assign this template.
3. Configure an **SNMPv3 interface** on the host with the correct IP, port (161), security level, and credentials.
4. Adjust the macros below as needed for your environment.

---

## Macros

| Macro | Default | Description |
|---|---|---|
| `{$AP_CLIENT_HIGH}` | `150` | Client count threshold for warning alert |
| `{$CPU_HIGH}` | `95` | CPU utilization threshold for critical alert |
| `{$CPU_WARN}` | `80` | CPU utilization threshold for warning alert |
| `{$IF_ERRORS_WARN}` | `10` | Interface error rate (eps) threshold for warning |

---

## Items Collected

| Name | Key | Interval | Type | Notes |
|---|---|---|---|---|
| AP Total Client Count | `ap.clients.total` | 3m | SNMP_AGENT | All radios/SSIDs combined |
| AP CPU Utilization | `ap.cpu.util` | 3m | SNMP_AGENT | % — Aerohive MIB |
| AP Firmware Version | `ap.firmware` | 1h | SNMP_AGENT | IQ Engine build string |
| AP Hardware Version | `ap.hw.version` | 1h | SNMP_AGENT | Hardware revision |
| AP MAC Address | `ap.mac` | 1h | SNMP_AGENT | Base MAC address |
| AP Management IP | `ap.mgmt.ip` | 1h | SNMP_AGENT | Management-plane IP |
| AP Model | `ap.model` | 1h | SNMP_AGENT | e.g. AP4000-WW |
| AP Number of Radios | `ap.radio.count` | 1h | SNMP_AGENT | Total radio count |
| AP Radio Signal Info | `ap.radio.rssi` | 5m | SNMP_AGENT | RSSI string per radio (informational) |
| AP Serial Number | `ap.serial` | 1h | SNMP_AGENT | Aerohive serial number |
| System Uptime | `system.uptime` | 5m | SNMP_AGENT | sysUpTime (timeticks) |
| System Name | `system.name` | 1h | SNMP_AGENT | sysName |
| System Description | `system.descr` | 1h | SNMP_AGENT | Product/firmware info string |
| System Location | `system.location` | 1h | SNMP_AGENT | sysLocation |
| System Contact | `system.contact` | 1h | SNMP_AGENT | sysContact |

---

## Discovery Rules

| Name | Type | Key | Interval |
|---|---|---|---|
| Network Interface Discovery | SNMP_AGENT | `net.if.discovery` | 1h |

**Filter**: `{#IFNAME}` matches `^(eth[0-9]+|wifi[0-9]+)$` AND `{#IFTYPE}` = `6` (ethernetCsmacd only; discovers `eth0`, `wifi0`, `wifi1`, `wifi2`, etc.)

### Interface Item Prototypes

| Name | Key | Units | Notes |
|---|---|---|---|
| Interface {#IFNAME}: In Traffic | `net.if.in[{#IFNAME}]` | bps | CHANGE_PER_SECOND × 8 |
| Interface {#IFNAME}: Out Traffic | `net.if.out[{#IFNAME}]` | bps | CHANGE_PER_SECOND × 8 |
| Interface {#IFNAME}: In Errors | `net.if.in.errors[{#IFNAME}]` | eps | CHANGE_PER_SECOND |
| Interface {#IFNAME}: Out Errors | `net.if.out.errors[{#IFNAME}]` | eps | CHANGE_PER_SECOND |
| Interface {#IFNAME}: In Discards | `net.if.in.discards[{#IFNAME}]` | pps | CHANGE_PER_SECOND |
| Interface {#IFNAME}: Out Discards | `net.if.out.discards[{#IFNAME}]` | pps | CHANGE_PER_SECOND |
| Interface {#IFNAME}: Speed | `net.if.speed[{#IFNAME}]` | Mbps | ifHighSpeed |
| Interface {#IFNAME}: Operational Status | `net.if.status[{#IFNAME}]` | — | Mapped via IF-MIB::ifOperStatus |

---

## Triggers

| Name | Severity | Notes |
|---|---|---|
| High client count on AP {HOST.NAME} | WARNING | `last(ap.clients.total) > {$AP_CLIENT_HIGH}` |
| Critical CPU utilization on AP {HOST.NAME} | HIGH | avg 5m > `{$CPU_HIGH}`; hysteresis −5% |
| High CPU utilization on AP {HOST.NAME} | WARNING | avg 5m > `{$CPU_WARN}`; hysteresis −5% |
| AP {HOST.NAME} has been restarted | WARNING | `last(system.uptime) < 600`; manual close |
| High inbound error rate on {#IFNAME} | WARNING | avg 5m in errors > `{$IF_ERRORS_WARN}` |
| High outbound error rate on {#IFNAME} | WARNING | avg 5m out errors > `{$IF_ERRORS_WARN}` |
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
| `target` | ap |
| `target` | extreme |
| `target` | wireless |

---

## Compatibility

- **Zabbix version**: 6.4
- **SNMP version**: v3 recommended
- **Tested hardware**: Extreme Networks AP130, AP4000-WW
- **Tested firmware**: IQ Engine 10.8r5
- **MIBs used**: Aerohive / Extreme Networks enterprise MIB (`1.3.6.1.4.1.26928`) + IF-MIB
- **Author** Jon McLaughlin
