# HPE Nimble Storage by HTTP

## Overview

This template monitors **HPE Nimble Storage** arrays (Nimble OS 5.x) and **HPE Alletra 6000** using the native REST API over HTTPS. It is designed for **Zabbix 7.0+** and follows the official Zabbix template coding standards.

A single `SCRIPT` master item handles authentication, queries all API endpoints, and returns a consolidated JSON payload. All metrics are extracted using `DEPENDENT` items and Low-Level Discovery (LLD), minimizing API calls and load on the storage array.

### Tested On

| Product | Firmware |
|---|---|
| HPE Nimble Storage CS-Series | Nimble OS 5.0.10.0 |
| HPE Alletra 6000 | Nimble OS 6.x compatible |

---

## Features

### Base Items (Array-level)
| Item | Key | Type |
|---|---|---|
| Array Name | `nimble.array.name` | Inventory: Name |
| Array Model | `nimble.array.model` | Inventory: Model |
| Array Serial | `nimble.array.serial` | Inventory: Serial No. A |
| OS Version | `nimble.array.version` | Inventory: Software App A |
| Array Status | `nimble.array.status` | Health trigger |
| Usable Capacity | `nimble.array.usable_capacity` | Bytes |
| Used Space | `nimble.array.usage` | Bytes |
| Volume Usage | `nimble.array.vol_usage` | Bytes |
| Snapshot Usage | `nimble.array.snap_usage` | Bytes |
| **Space Utilization %** | `nimble.array.space_pct` | Calculated, alert >90% |

### Low-Level Discovery
| Discovery Rule | Items per object | Triggers |
|---|---|---|
| **Volume** | Size, Used, Online, Connections | Volume Offline |
| **Controller** | State, Hostname, Serial, Fan, Temperature, Power, Partition Status | State abnormal, Fan/Power/Temp problem |
| **Pool** | Capacity, Usage, Savings Ratio | — |
| **Disk** | State, RAID State, Type, Size, Model, Vendor, Firmware | State abnormal |
| **Shelf** | Model, Chassis Type, Fan, PSU, Temperature Status | Fan/PSU/Temp problem |
| **Network Interface** | Link Status, Speed, Max Speed, MTU, MAC, NIC Type | Link is Down |
| **Active Alarms** | Severity, Status | Critical alarm |

### Triggers Summary
| Trigger | Severity |
|---|---|
| API errors in requests | Average |
| Array is not reachable | High |
| Array space utilization > {$HPE.NIMBLE.SPACE.WARN}% | Average |
| Volume is Offline | High |
| Controller state abnormal (not active/standby) | High |
| Controller fan/power/temperature problem | Average |
| Disk state abnormal | High |
| Shelf fan/PSU problem | High |
| Shelf temperature problem | Average |
| NIC link is down | Average |
| Active alarm with severity = critical | High |

### Inventory Auto-Population
The template automatically populates the following Zabbix host inventory fields:

| Inventory Field | Source |
|---|---|
| Name | Array name |
| Model | Array model |
| Serial Number A | Array serial number |
| Software App A | Nimble OS version |

---

## Requirements

- **Zabbix**: 7.0 or newer (requires `SCRIPT` item type with JavaScript)
- **Nimble OS**: 5.x / 6.x (REST API on port 5392)
- **Network**: Zabbix Server/Proxy must have HTTPS access to the Nimble management IP on port 5392
- **API User**: A Nimble user account with at least **Read-Only** role

---

## Setup

### 1. Import the Template
Import `Template_HPE_Nimble_Storage_by_HTTP.yaml` into Zabbix:
> **Administration → Templates → Import**

### 2. Create a Host
Create a host for your Nimble Storage array. The host interface IP should be the management IP of the array.

### 3. Link the Template
Link `HPE Nimble Storage by HTTP` to the host.

### 4. Configure Macros
Set the following macros on the **host level** (do not change the template defaults):

| Macro | Default | Description |
|---|---|---|
| `{$HPE.NIMBLE.API.HOST}` | `{HOST.CONN}` | Management IP or hostname |
| `{$HPE.NIMBLE.API.PORT}` | `5392` | REST API port |
| `{$HPE.NIMBLE.API.SCHEME}` | `https` | `https` or `http` |
| `{$HPE.NIMBLE.API.USERNAME}` | `admin` | API username |
| `{$HPE.NIMBLE.API.PASSWORD}` | *(secret)* | API password |
| `{$HPE.NIMBLE.DATA.TIMEOUT}` | `60s` | Script execution timeout |
| `{$HPE.NIMBLE.SPACE.WARN}` | `90` | Space utilization alert threshold (%) |

> ⚠️ **Security**: `{$HPE.NIMBLE.API.PASSWORD}` is stored as a **Secret Text** macro. Set it at the host level to avoid exposing credentials in the template.

### 5. Enable Inventory (Optional)
To enable automatic inventory population:
> **Host → Inventory → Mode: Automatic**

---

## API Authentication Flow

```
1. POST /v1/tokens          → Get session token
2. GET  /v1/arrays/<id>     → Array details
3. GET  /v1/controllers/<id>→ Controller details (per ID)
4. GET  /v1/pools/<id>      → Pool details
5. GET  /v1/volumes/<id>    → Volume details
6. GET  /v1/disks/<id>      → Disk details
7. GET  /v1/network_interfaces/<id> → NIC details
8. GET  /v1/shelves/<id>    → Shelf details
9. GET  /v1/alarms/<id>     → Active alarm details
10. DELETE /v1/tokens/<token> → Logout
```

All data is returned as a single JSON blob. The master item collects once per interval; all dependent items parse the cached data without additional API calls.

---

## Tags

| Tag | Value |
|---|---|
| `class` | `storage` |
| `target` | `hpe` |
| `target` | `nimble` |

Item-level tags:
- `component`: `system` / `capacity` / `health` / `raw` / `volume` / `controller` / `pool` / `disk` / `shelf` / `network` / `alarm`
- `scope` (triggers): `availability` / `capacity`

---

## Known Limitations

- The REST API list endpoints (`GET /v1/<collection>`) only return `id` and `name`. The template performs per-object detail lookups (`GET /v1/<collection>/<id>`), which increases API call count proportionally to object count. For arrays with many volumes/disks, consider adjusting the collection interval.
- Network interfaces do not expose IP addresses via this API endpoint. Use the Nimble GUI for IP management.
- The `alarms` discovery rule creates items for **currently active** alarms only. Resolved alarms will be removed by the LLD keep-lost-resources period.

---

## Template Generation

The template YAML is generated from a Python script:

```bash
python generate_nimble_http_template.py
```

Output: `Template_HPE_Nimble_Storage_by_HTTP.yaml`

---

## License

This template is released under the **MIT License** and is free to use, modify, and distribute.

## Author

Contributed to the [Zabbix Community Templates](https://github.com/zabbix/community-templates) repository.

- **Category**: Storage / SAN
- **Vendor**: HPE (Hewlett Packard Enterprise)
- **Product**: Nimble Storage / Alletra 6000
