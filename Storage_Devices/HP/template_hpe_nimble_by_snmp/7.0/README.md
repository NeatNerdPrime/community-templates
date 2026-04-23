# HPE Nimble Storage by SNMP

## Overview

This template monitors **HPE Nimble Storage** (Nimble OS 5.x) and **HPE Alletra 6000** all-flash arrays via SNMP v2c/v3.

It uses the vendor's enterprise MIB (`NIMBLE-MIB`, enterprise OID `.1.3.6.1.4.1.37447`) for array-level performance and capacity metrics, `IF-MIB` for network interface monitoring, and SNMP Traps for hardware health alerting.

> **Note:** HPE Nimble OS does **not** expose hardware component sensors (fan, PSU, temperature) via polling OIDs. Hardware health events are delivered exclusively as **SNMP Traps** from the array. This template captures them via a dedicated trap item.

## Requirements

| Requirement | Details |
|---|---|
| Zabbix version | **7.0** or later |
| SNMP version | v2c or v3 |
| MIBs used | `SNMPv2-MIB`, `IF-MIB`, `NIMBLE-MIB` (`.1.3.6.1.4.1.37447`) |
| Nimble OS | 5.x / HPE Alletra 6000 OS |
| Network | UDP/161 (SNMP polling) from Zabbix Server/Proxy to array management IP |
| Trap reception | UDP/162 from array to Zabbix Server (optional, for hardware alerts) |

## Setup

### 1. Import the template

Import `HPE Nimble Storage by SNMP.yaml` into Zabbix via **Configuration → Templates → Import**.

### 2. Configure the host

1. Create or edit a host for your Nimble array.
2. Add an **SNMP interface** pointing to the array's management IP address.
3. Link this template to the host.
4. Set the SNMP community string via the host-level macro `{$SNMP_COMMUNITY}` (default: `public`).

### 3. Configure SNMP Traps (optional but recommended)

For hardware health alerting (fan failures, PSU faults, disk errors), configure the Nimble array to send SNMP Traps to your Zabbix server:

```
# On the Nimble array (CLI or GUI → Administration → SNMP):
snmp trap add --target-ip <ZABBIX_SERVER_IP> --community public --version v2c
```

Ensure the Zabbix server has `snmptrapd` configured and the Zabbix SNMP trap handler is active.

## Macros

| Macro | Default | Description |
|---|---|---|
| `{$SNMP_COMMUNITY}` | `public` | SNMP community string |
| `{$SNMP.TIMEOUT}` | `5m` | Timeout for SNMP availability check |

## Metrics collected

### System (SNMPv2-MIB)

| Item | Key | Interval |
|---|---|---|
| System name | `nimble.system.name[sysName]` | 15m |
| System description | `nimble.system.descr[sysDescr]` | 1h |
| System location | `nimble.system.location[sysLocation]` | 1h |
| System contact | `nimble.system.contact[sysContact]` | 1h |
| Uptime (network) | `nimble.system.net.uptime[sysUpTime]` | 1m |
| SNMP agent availability | `zabbix[host,snmp,available]` | 1m |

### Array Performance (NIMBLE-MIB)

| Item | Key | Interval |
|---|---|---|
| Total Read IOPS | `nimble.io.reads` | 1m |
| Total Write IOPS | `nimble.io.writes` | 1m |
| Total Read Throughput | `nimble.io.read_bps` | 1m |
| Total Write Throughput | `nimble.io.write_bps` | 1m |
| Total Read Latency | `nimble.io.read_lat` | 1m |
| Total Write Latency | `nimble.io.write_lat` | 1m |
| Sequential Read IOPS | `nimble.io.seq_reads` | 1m |
| Sequential Write IOPS | `nimble.io.seq_writes` | 1m |

### Array Capacity (NIMBLE-MIB)

| Item | Key | Interval |
|---|---|---|
| Global Volume Capacity Used | `nimble.array.vol_used` | 5m |
| Global Snapshot Capacity Used | `nimble.array.snap_used` | 5m |

### SNMP Traps

| Item | Key | Purpose |
|---|---|---|
| SNMP Trap: Hardware Alert | `nimble.trap.hardware` | Fan, PSU, disk, temperature events |
| SNMP Trap: All Events | `nimble.trap.all` | Catch-all for any array alerts |

## Discovery Rules

### Volume Discovery

Automatically discovers all volumes via `volName` OID table (`.1.3.6.1.4.1.37447.1.2.1.3`).

Item prototypes per volume:

| Prototype | Description |
|---|---|
| `Volume {#VOL_NAME}: Size` | Provisioned size in bytes |
| `Volume {#VOL_NAME}: Used` | Currently used bytes |
| `Volume {#VOL_NAME}: Status` | Online (1) / Offline (2) |
| `Volume {#VOL_NAME}: Read IOPS` | Per-volume read IOPS |
| `Volume {#VOL_NAME}: Write IOPS` | Per-volume write IOPS |

Trigger prototypes:
- `Volume {#VOL_NAME}: is Offline` — **HIGH**
- `Volume {#VOL_NAME}: Usage over 80%` — **WARNING**

### Network Interface Discovery

Discovers all network interfaces via `IF-MIB::ifDescr` (`.1.3.6.1.2.1.2.2.1.2`). Loopback (`lo`) is excluded automatically.

Item prototypes per interface:

| Prototype | Description |
|---|---|
| `Interface {#IF_NAME}: Status` | Operational status (up/down) |
| `Interface {#IF_NAME}: In` | Inbound traffic (bps) |
| `Interface {#IF_NAME}: Out` | Outbound traffic (bps) |

Trigger prototypes:
- `Interface {#IF_NAME}: Down` — **AVERAGE**

## Triggers

| Trigger | Severity | Description |
|---|---|---|
| Nimble: No SNMP data collection | WARNING | SNMP polling not reachable |
| Nimble: Device has been restarted | WARNING | Uptime < 10 minutes |
| Nimble: System name has changed | INFO | Hostname change detected |
| Nimble: Hardware alert received via SNMP Trap | HIGH | Any hardware trap received |

## Value Maps

| Name | Values |
|---|---|
| `Nimble Volume Status` | 1=Online, 2=Offline |
| `IF-MIB::ifOperStatus` | 1=up, 2=down |
| `zabbix.host.available` | 0=not available, 1=available, 2=unknown |

## Template Tags

| Tag | Value |
|---|---|
| `class` | `storage` |
| `target` | `hpe` |
| `target` | `nimble` |

## Author

Contributed by **lucthienphong1120**  
Tested on: HPE Nimble CS700 (Nimble OS 5.3), Zabbix 7.0
