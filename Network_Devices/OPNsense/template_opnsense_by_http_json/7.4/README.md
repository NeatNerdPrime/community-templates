

# OPNsense by HTTP-JSON

## Overview

This template monitors OPNsense firewalls via the built-in REST API using HTTP JSON agent requests. It collects data about system resources (CPU, memory, disk, uptime), firewall states and actions, gateway health, network interfaces, and CARP high-availability status.

The template uses OPNsense API key/secret authentication and requires no agent installation on the firewall.

## Requirements

- **Zabbix version**: 7.4 or higher
- **OPNsense version**: Tested with OPNsense 24.x+ (any version providing the used API endpoints)
- An **API key and secret** created on the OPNsense appliance (System → Access → Users → API keys)
- The Zabbix server/proxy must have **HTTPS access** to the OPNsense web interface (port 443 by default)
- The API user needs read access to the following OPNsense API modules:
  - `diagnostics/system`
  - `diagnostics/firewall`
  - `diagnostics/interface`
  - `diagnostics/traffic`
  - `routes/gateway`
  - `core/firmware`

## Setup

1. [**Create an API key** on OPNsense](https://docs.opnsense.org/development/how-tos/api.html#creating-keys):
   - Navigate to **System → Access → Users**
   - Select or create a user and click the **+** icon under *API keys*
   - Download the `apikey.txt` file – it contains the **key** and the **secret**

2. **Import the template** into Zabbix:
   - Go to **Data collection → Templates → Import** and upload the YAML file

3. **Link the template** to a host:
   - Set the host's **IP/DNS** to the OPNsense management address
   - Link the template `OPNsense by HTTP-JSON`

4. **Configure the required macros** on the host:
   - `{$OPNS.KEY}` – Your OPNsense API key
   - `{$OPNS.SECRET}` – Your OPNsense API secret

5. **Verify connectivity**:
   - After a few minutes check that the item `Meta Gatewaystatus` is receiving data

> **Note:** The Zabbix server/proxy must trust the OPNsense TLS certificate, or Zabbix must be configured to skip certificate verification for HTTP agent items.

## Macros Used

| Macro | Default Value | Description |
|-------|---------------|-------------|
| `{$OPNS.KEY}` | *(empty)* | OPNsense API key. **Required.** |
| `{$OPNS.SECRET}` | *(empty)* | OPNsense API secret. **Required.** |
| `{$OPNS.CPU.LOAD.MAX}` | `2` | Maximum CPU load average (1 min) before triggering a warning. |
| `{$OPNS.MEMORY.UTIL.MAX}` | `90` | Maximum memory utilization percentage before triggering an alert. |
| `{$OPNS.STATE.TABLE.UTIL.MAX}` | `90` | Maximum state table utilization percentage before triggering a warning. |
| `{$OPNS.GW.MIN.PACKET.LOSS}` | `10` | Minimum packet loss percentage to trigger a gateway packet loss alert. |
| `{$OPNS.GW.HIGH.PACKET.LOSS}` | `50` | Packet loss percentage to trigger a high packet loss alert. |
| `{$OPNS.LICENSE.EXPIRY.WARN}` | `30` | Number of days before OPNsense Business Edition license expiry to trigger a warning. |
| `{$OPNS.FS.FSNAME.MATCHES}` | `.+` | Regex filter for filesystem discovery – included mount points. |
| `{$OPNS.FS.FSNAME.NOT_MATCHES}` | `^(/dev\|/sys\|/run\|/proc\|.+/shm$)` | Regex filter for filesystem discovery – excluded mount points. |
| `{$OPNS.FS.FSTYPE.MATCHES}` | `^(btrfs\|ext2\|ext3\|ext4\|reiser\|xfs\|ffs\|ufs\|jfs\|jfs2\|vxfs\|hfs\|apfs\|refs\|ntfs\|fat32\|zfs)$` | Regex filter for filesystem discovery – included filesystem types. |
| `{$OPNS.FS.FSTYPE.NOT_MATCHES}` | `^\s$` | Regex filter for filesystem discovery – excluded filesystem types. |
| `{$OPNS.FS.PUSED.MAX.WARN}` | `90` | Warning threshold for filesystem space utilization (%). |
| `{$OPNS.FS.PUSED.MAX.CRIT}` | `95` | Critical threshold for filesystem space utilization (%). |

## Items Collected

### System Items

| Name | Key | Type | Update Interval | Description |
|------|-----|------|-----------------|-------------|
| CPU load | `opns.cpu.load` | Dependent | – | System load average (1 min), extracted from system time API. |
| System Uptime | `opns.system.uptime` | Dependent | – | System uptime converted from human-readable string (e.g. "1 day, 03:05:40") to seconds. Displayed in Zabbix uptime format. |
| Total Memory | `opns.memory.total` | Dependent | – | Total physical memory in bytes. |
| Used Memory | `opns.memory.used` | Dependent | – | Used memory in bytes. |
| ARC Memory | `opns.memory.arc` | Dependent | – | ZFS ARC memory usage in bytes. |
| Memory utilization in % | `opns.memory.util` | Calculated | – | Percentage of used memory relative to total memory. |
| Licensed until | `opns.product.licenseuntil` | Dependent | – | OPNsense Business Edition license expiry (Unix timestamp). Returns `NaN` if no license is present (Community Edition). |

### Firewall Items

| Name | Key | Type | Description |
|------|-----|------|-------------|
| Firewall states current | `opns.fw.states.current` | Dependent | Current number of active firewall states. |
| Firewall states max | `opns.fw.states.max` | Dependent | Maximum number of allowed firewall states (kernel limit). |
| States table utilization in % | `opns.states.util` | Calculated | Percentage of the state table currently in use. |

### Meta (Raw Data) Items

These items fetch raw JSON data from the OPNsense API and serve as master items for dependent items and discovery rules.

| Name | Key | Update Interval | API Endpoint |
|------|-----|-----------------|--------------|
| Meta Load | `opns.meta.load` | 5m | `/api/diagnostics/system/system_time` |
| Meta Memorystatus | `opns.meta.memory.status` | 5m | `/api/diagnostics/system/systemResources` |
| Meta Disk | `opns.meta.disk` | 5m | `/api/diagnostics/system/system_disk` |
| Meta Gatewaystatus | `opns.meta.gateway.status` | 1m | `/api/routes/gateway/status` |
| Meta Firewall States | `opns.meta.fw.states` | 1m | `/api/diagnostics/firewall/pfStates` |
| Meta Firewallaction | `opns.meta.fw.action` | 1m | `/api/diagnostics/firewall/stats?group_by=action` |
| Meta Firewall Interfaces | `opns.meta.fw.interface.stat` | 1m | `/api/diagnostics/firewall/pf_statistics/interfaces` |
| Meta Interfaces | `opns.meta.interfaces.stat` | 1m | `/api/diagnostics/traffic/_interface` |
| Meta Carp Interfaces | `opns.meta.interfaces.carp` | 1m | `/api/diagnostics/interface/get_vip_status` |
| Meta Product Info | `opns.meta.product.info` | 30m | `/api/core/firmware/info` |

## Triggers

| Name | Severity | Description |
|------|----------|-------------|
| No data from OPNsense | **High** | Fires when no data is received from `opns.meta.gateway.status` for 5 minutes – indicates the OPNsense API is unreachable. |
| CPU load is high | **Warning** | Fires when CPU load (1 min avg) exceeds `{$OPNS.CPU.LOAD.MAX}` (default: 2) for 5 minutes. |
| Memory utilization is high | **Average** | Fires when memory utilization exceeds `{$OPNS.MEMORY.UTIL.MAX}` % (default: 90%) for 5 minutes. |
| OPNSense Business License expires soon | **Average** | Fires when the license expires in less than `{$OPNS.LICENSE.EXPIRY.WARN}` days (default: 30). Only relevant for OPNsense Business Edition. |
| State table usage is high | **Warning** | Fires when the state table utilization exceeds `{$OPNS.STATE.TABLE.UTIL.MAX}` % for the last 3 values. |
| {HOST.NAME} has been restarted | **Info** | Fires when the system uptime is less than 10 minutes (600 seconds). |

## Discovery Rules

### 1. Disk Discovery

| Property | Value |
|----------|-------|
| Key | `opns.disk.discovery` |
| Type | Dependent (master: `opns.meta.disk`) |
| Filters | `{#FSNAME}` matches/not matches and `{#FSTYPE}` matches/not matches (configurable via macros) |
| Keep lost resources | 1h |

**Item Prototypes:**

| Name | Key | Unit | Description |
|------|-----|------|-------------|
| FS [{#FSNAME}]: Get data | `opns.disk.data[{#FSNAME},data]` | – | Raw JSON data for the filesystem (intermediate item). |
| FS [{#FSNAME}]: Space: Total | `opns.disk.size[{#FSNAME},total]` | B | Total filesystem size in bytes. |
| FS [{#FSNAME}]: Space: Used | `opns.disk.size[{#FSNAME},used]` | B | Used space in bytes. |
| FS [{#FSNAME}]: Space: Available | `opns.disk.size[{#FSNAME},available]` | B | Available space in bytes. |
| FS [{#FSNAME}]: Space: Used, in % | `opns.disk.size[{#FSNAME},pused]` | B | Used space as percentage. |

**Trigger Prototypes:**

| Name | Severity | Description |
|------|----------|-------------|
| OPNsense: FS [{#FSNAME}]: Space is low | **Warning** | Used space exceeds `{$OPNS.FS.PUSED.MAX.WARN:"{#FSNAME}"}` % (default: 90%). Depends on "Space is critically low". |
| OPNsense: FS [{#FSNAME}]: Space is critically low | **Average** | Used space exceeds `{$OPNS.FS.PUSED.MAX.CRIT:"{#FSNAME}"}` % (default: 95%). |

---

### 2. Gateway Discovery

| Property | Value |
|----------|-------|
| Key | `opns.gateway.discovery` |
| Type | Dependent (master: `opns.meta.gateway.status`) |
| LLD Macro | `{#GWSTATUSNAME}` → `$.name` |
| Keep lost resources | 1h |

**Item Prototypes:**

| Name | Key | Unit | Description |
|------|-----|------|-------------|
| Gateway Address {#GWSTATUSNAME} | `opns.gw.status.address[{#GWSTATUSNAME}]` | – | Gateway IP address. |
| Gateway Status {#GWSTATUSNAME} | `opns.gw.status.status[{#GWSTATUSNAME}]` | – | Translated gateway status string (e.g., "Online"). |
| Gateway RTT {#GWSTATUSNAME} | `opns.gw.status.delay[{#GWSTATUSNAME}]` | ms | Round-trip time in milliseconds. Returns 9999 if monitoring is disabled. |
| Gateway RTTd {#GWSTATUSNAME} | `opns.gw.status.stddev[{#GWSTATUSNAME}]` | ms | Round-trip time standard deviation in ms. Returns 9999 if monitoring is disabled. |
| Gateway loss {#GWSTATUSNAME} | `opns.gw.status.loss[{#GWSTATUSNAME}]` | % | Packet loss percentage. Returns 9999 if monitoring is disabled. |

**Trigger Prototypes:**

| Name | Severity | Description |
|------|----------|-------------|
| Gateway {#GWSTATUSNAME} Packet loss | **Average** | Packet loss > `{$OPNS.GW.MIN.PACKET.LOSS}` % (default: 10%) for 5 min. Depends on "High packet loss". |
| Gateway {#GWSTATUSNAME} High packet loss | **High** | Packet loss > `{$OPNS.GW.HIGH.PACKET.LOSS}` % (default: 50%) for 5 min. Depends on "is down". |
| Gateway {#GWSTATUSNAME} is down | **Disaster** | Packet loss > 99% for 5 min. |
| Gateway Monitoring on {#GWSTATUSNAME} is disabled | **Average** | All monitoring values (loss, stddev, delay) return 9999 – indicates gateway monitoring is not enabled in OPNsense. See [OPNsense Gateway docs](https://docs.opnsense.org/manual/gateways.html). |

---

### 3. FW Action Discovery

| Property | Value |
|----------|-------|
| Key | `opns.fw.action.discovery` |
| Type | Dependent (master: `opns.meta.fw.action`) |
| LLD Macro | `{#FWACTION}` → `$.label` |
| Keep lost resources | 1h |

**Item Prototypes:**

| Name | Key | Description |
|------|-----|-------------|
| Firewall action {#FWACTION} | `opns.fw.action[{#FWACTION}]` | Counter for the discovered firewall action (e.g., pass, block, match). |

**Graph Prototypes:**

| Name | Description |
|------|-------------|
| OPNSense Action Graph {#FWACTION} | Graph showing firewall action counts per discovered action type. |

---

### 4. Interface CARP Discovery

| Property | Value |
|----------|-------|
| Key | `opns.interface.carp.discovery` |
| Type | Dependent (master: `opns.meta.interfaces.carp`) |
| LLD Macro | `{#OPNS.INTERFACE.NAME}` → `$.interface` |
| Keep lost resources | 1d |

**Item Prototypes:**

| Name | Key | Description |
|------|-----|-------------|
| Carp Status of {#OPNS.INTERFACE.NAME} | `opns.carp.status[{#OPNS.INTERFACE.NAME}]` | CARP status of the VIP (MASTER, BACKUP, INIT). Uses discard unchanged heartbeat (2h). |

**Trigger Prototypes:**

| Name | Severity | Description |
|------|----------|-------------|
| Carp Status Changed on {#OPNS.INTERFACE.NAME} | **High** | Fires when the CARP status of an interface changes (e.g., failover event). |

> **Note:** If no CARP interfaces are configured, the discovery will return a custom error message and no items will be created.

---

### 5. Interface Stats Discovery

| Property | Value |
|----------|-------|
| Key | `opns.interface.stats.discovery` |
| Type | Dependent (master: `opns.meta.interfaces.stat`) |
| LLD Macros | `{#OPNS.INTERFACE.DEVICE}` → `$.device`, `{#OPNS.INTERFACE.NAME}` → `$.name` |

**Item Prototypes – Traffic:**

| Name | Key | Unit |
|------|-----|------|
| Interface [{#OPNS.INTERFACE.DEVICE}({#OPNS.INTERFACE.NAME})]: Bytes received | `opns.interface.bytes.received[{#OPNS.INTERFACE.DEVICE}]` | Bps |
| Interface [{#OPNS.INTERFACE.DEVICE}({#OPNS.INTERFACE.NAME})]: Bytes transmitted | `opns.interface.bytes.transmitted[{#OPNS.INTERFACE.DEVICE}]` | Bps |
| Interface [{#OPNS.INTERFACE.DEVICE}({#OPNS.INTERFACE.NAME})]: packets received | `opns.interface.packets.received[{#OPNS.INTERFACE.DEVICE}]` | – |
| Interface [{#OPNS.INTERFACE.DEVICE}({#OPNS.INTERFACE.NAME})]: packets transmitted | `opns.interface.packets.transmitted[{#OPNS.INTERFACE.DEVICE}]` | – |
| Interface [{#OPNS.INTERFACE.DEVICE}({#OPNS.INTERFACE.NAME})]: multicasts received | `opns.interface.multicast.received[{#OPNS.INTERFACE.DEVICE}]` | – |

**Item Prototypes – Errors & Drops:**

| Name | Key |
|------|-----|
| Interface [{#OPNS.INTERFACE.DEVICE}({#OPNS.INTERFACE.NAME})]: collisions | `opns.interface.collisions[{#OPNS.INTERFACE.DEVICE}]` |
| Interface [{#OPNS.INTERFACE.DEVICE}({#OPNS.INTERFACE.NAME})]: input queue drops | `opns.interface.input.queue.drops[{#OPNS.INTERFACE.DEVICE}]` |
| Interface [{#OPNS.INTERFACE.DEVICE}({#OPNS.INTERFACE.NAME})]: output errors | `opns.interface.output.errors[{#OPNS.INTERFACE.DEVICE}]` |
| Interface [{#OPNS.INTERFACE.DEVICE}({#OPNS.INTERFACE.NAME})]: packets for unknown protocol | `opns.interface.packets.unknown.protocol[{#OPNS.INTERFACE.DEVICE}]` |

**Item Prototypes – Firewall per Interface (IPv4):**

| Name | Key | Unit |
|------|-----|------|
| …blocked bytes INv4 | `opns.interface.fw.bytes.blockin.v4[{#OPNS.INTERFACE.DEVICE}]` | Bps |
| …blocked bytes OUTv4 | `opns.interface.fw.bytes.blockout.v4[{#OPNS.INTERFACE.DEVICE}]` | Bps |
| …passed bytes INv4 | `opns.interface.fw.bytes.passin.v4[{#OPNS.INTERFACE.DEVICE}]` | Bps |
| …passed bytes OUTv4 | `opns.interface.fw.bytes.passout.v4[{#OPNS.INTERFACE.DEVICE}]` | Bps |
| …blocked packets INv4 | `opns.interface.fw.packets.blockin.v4[{#OPNS.INTERFACE.DEVICE}]` | – |
| …blocked packets OUTv4 | `opns.interface.fw.packets.blockout.v4[{#OPNS.INTERFACE.DEVICE}]` | – |
| …passed packets INv4 | `opns.interface.fw.packets.passin.v4[{#OPNS.INTERFACE.DEVICE}]` | – |
| …passed packets OUTv4 | `opns.interface.fw.packets.passout.v4[{#OPNS.INTERFACE.DEVICE}]` | – |

## Dashboards

The template includes a built-in dashboard **"OPNsense Info"** with three pages:

1. **OPNSense Info** – CPU load widget, memory usage pie chart, firewall states pie chart, firewall action SVG graph, and CARP status honeycomb overview.
2. **Gateway Info** – SVG graphs for gateway round-trip time and packet loss across all discovered gateways.
3. **Interfaces** – SVG graph showing blocked and passed bytes (IPv4) per interface.

## Feedback

If you encounter any issues or have suggestions for improvement, please open an issue or pull request in the community templates repository.
