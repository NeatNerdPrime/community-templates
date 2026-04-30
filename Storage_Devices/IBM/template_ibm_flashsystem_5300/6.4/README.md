# IBM FlashSystem 5300 by REST API and SNMP

## Overview

Template for monitoring IBM Storage FlashSystem 5300 (Spectrum Virtualize) via REST API and SNMP traps.

Uses SCRIPT items with embedded JavaScript to call the FlashSystem REST API. Each master item authenticates independently and fetches data from a specific endpoint. Dependent items parse the JSON response using JSONPath preprocessing.

For SNMP traps, the template receives error, warning and informational events from IBM-SVC-MIB.

Tested on:
- IBM FlashSystem 5300
- Spectrum Virtualize 8.6.x / 8.7.x

## Setup

1. Create a REST API user on FlashSystem with **Monitor** or **Administrator** role.
2. (Optional) Configure SNMP trap sender on FlashSystem (`svctask mksnmpserver`).
3. Import the template and assign it to a host.
4. Set required macros: `{$IBM.API.URL}`, `{$IBM.API.USER}`, `{$IBM.API.PASSWORD}`.

## Macros used

|Name|Description|Default|Type|
|----|-----------|-------|----|
|{$IBM.API.URL}|<p>Base URL for FlashSystem REST API.</p>|`https://{HOST.CONN}:7443/rest/v1`|Text macro|
|{$IBM.API.USER}|<p>REST API username.</p>|`monitor`|Text macro|
|{$IBM.API.PASSWORD}|<p>REST API password.</p>|``|Secret macro|
|{$IBM.HTTP.PROXY}|<p>HTTP proxy for API requests (leave empty for direct connection).</p>|``|Text macro|
|{$IBM.API.INTERVAL}|<p>Default polling interval for REST API items.</p>|`5m`|Text macro|
|{$IBM.API.INTERVAL.PERF}|<p>Polling interval for performance metrics.</p>|`1m`|Text macro|
|{$IBM.API.INTERVAL.DISCOVERY}|<p>Polling interval for discovery rules.</p>|`1h`|Text macro|
|{$IBM.API.TIMEOUT}|<p>HTTP request timeout.</p>|`15s`|Text macro|
|{$IBM.CPU.UTIL.WARN}|<p>Warning threshold for CPU utilization (%).</p>|`80`|Text macro|
|{$IBM.CPU.UTIL.CRIT}|<p>Critical threshold for CPU utilization (%).</p>|`90`|Text macro|
|{$IBM.POOL.UTIL.WARN}|<p>Warning threshold for pool utilization (%).</p>|`80`|Text macro|
|{$IBM.POOL.UTIL.CRIT}|<p>Critical threshold for pool utilization (%).</p>|`90`|Text macro|
|{$IBM.CACHE.UTIL.WARN}|<p>Warning threshold for write cache utilization (%).</p>|`80`|Text macro|
|{$IBM.TEMP.WARN}|<p>Warning threshold for temperature (Celsius).</p>|`35`|Text macro|
|{$IBM.TEMP.CRIT}|<p>Critical threshold for temperature (Celsius).</p>|`40`|Text macro|
|{$IBM.VDISK.LATENCY.WARN}|<p>Warning threshold for volume latency (ms).</p>|`20`|Text macro|
|{$IBM.VDISK.LATENCY.CRIT}|<p>Critical threshold for volume latency (ms).</p>|`50`|Text macro|
|{$IBM.DRIVE.NAME.MATCHES}|<p>Filter to include drives in discovery.</p>|`.*`|Text macro|
|{$IBM.DRIVE.NAME.NOT_MATCHES}|<p>Filter to exclude drives from discovery.</p>|`CHANGE_IF_NEEDED`|Text macro|
|{$IBM.POOL.NAME.MATCHES}|<p>Filter to include storage pools in discovery.</p>|`.*`|Text macro|
|{$IBM.POOL.NAME.NOT_MATCHES}|<p>Filter to exclude storage pools from discovery.</p>|`CHANGE_IF_NEEDED`|Text macro|
|{$IBM.VOLUME.NAME.MATCHES}|<p>Filter to include volumes in discovery.</p>|`.*`|Text macro|
|{$IBM.VOLUME.NAME.NOT_MATCHES}|<p>Filter to exclude volumes from discovery.</p>|`CHANGE_IF_NEEDED`|Text macro|
|{$SNMP_COMMUNITY}|<p>SNMP community string for traps.</p>|`public`|Text macro|

## Template links

There are no template links in this template.

## Discovery rules

|Name|Description|Type|Key and additional info|
|----|-----------|----|----|
|Storage pools discovery|<p>Discovers storage pools via lsmdiskgrp REST API.</p>|`Script`|ibm.api.lsmdiskgrp.discovery<p>Update: {$IBM.API.INTERVAL.DISCOVERY}</p>|
|Drives discovery|<p>Discovers physical drives via lsdrive REST API.</p>|`Script`|ibm.api.lsdrive.discovery<p>Update: {$IBM.API.INTERVAL.DISCOVERY}</p>|
|Node canisters discovery|<p>Discovers node canisters via lsnodecanister REST API.</p>|`Script`|ibm.api.lsnodecanister.discovery<p>Update: {$IBM.API.INTERVAL.DISCOVERY}</p>|
|Enclosure PSU discovery|<p>Discovers power supply units via lsenclosurepsu REST API.</p>|`Script`|ibm.api.lsenclosurepsu<p>Update: {$IBM.API.INTERVAL.DISCOVERY}</p>|
|Enclosure battery discovery|<p>Discovers batteries via lsenclosurebattery REST API.</p>|`Script`|ibm.api.lsenclosurebattery<p>Update: {$IBM.API.INTERVAL.DISCOVERY}</p>|
|FC ports discovery|<p>Discovers Fibre Channel ports via lsportfc REST API.</p>|`Script`|ibm.api.lsportfc<p>Update: {$IBM.API.INTERVAL.DISCOVERY}</p>|
|Volumes discovery|<p>Discovers volumes (VDisks) via lsvdisk REST API.</p>|`Script`|ibm.api.lsvdisk.discovery<p>Update: {$IBM.API.INTERVAL.DISCOVERY}</p>|

## Items collected

|Name|Description|Type|Key and additional info|
|----|-----------|----|----|
|ICMP: Ping|<p>Host availability check via ICMP ping.</p>|`Simple check`|icmpping<p>Update: 1m</p>|
|ICMP: Loss|<p>ICMP packet loss percentage.</p>|`Simple check`|icmppingloss<p>Update: 1m</p>|
|ICMP: Response time|<p>ICMP ping response time.</p>|`Simple check`|icmppingsec<p>Update: 1m</p>|
|API: Get system info|<p>Retrieves system information via lssystem REST API call.</p>|`Script`|ibm.api.lssystem<p>Update: {$IBM.API.INTERVAL}</p>|
|System: Name|<p>FlashSystem cluster name.</p>|`Dependent item`|ibm.system.name|
|System: Location|<p>Physical location of the system.</p>|`Dependent item`|ibm.system.location|
|System: Code level|<p>Firmware/software code level.</p>|`Dependent item`|ibm.system.code_level|
|System: Product name|<p>Product model name.</p>|`Dependent item`|ibm.system.product_name|
|System: Serial number|<p>System serial number.</p>|`Dependent item`|ibm.system.serial_number|
|System: Machine type-model|<p>Machine type and model.</p>|`Dependent item`|ibm.system.machine_type_model|
|System: Total MDisk capacity|<p>Total raw capacity of managed disks.</p>|`Dependent item`|ibm.system.total_mdisk_capacity|
|System: Total used capacity|<p>Space allocated to volumes.</p>|`Dependent item`|ibm.system.total_used_capacity|
|System: Total free capacity|<p>Available free space.</p>|`Dependent item`|ibm.system.total_free_capacity|
|System: Total nodes|<p>Number of node canisters.</p>|`Dependent item`|ibm.system.total_nodes|
|System: Statistics status|<p>Statistics collection state.</p>|`Dependent item`|ibm.system.statistics_status|
|System: Compression active|<p>Compression CPU percentage.</p>|`Dependent item`|ibm.system.compression_cpu_pc|
|API: Get system stats|<p>Retrieves performance statistics via lssystemstats REST API call.</p>|`Script`|ibm.api.lssystemstats<p>Update: {$IBM.API.INTERVAL.PERF}</p>|
|Performance: CPU utilization|<p>Total CPU usage (%).</p>|`Dependent item`|ibm.system.cpu_pc|
|Performance: Write cache utilization|<p>Write cache usage (%).</p>|`Dependent item`|ibm.system.write_cache_pc|
|Performance: Total cache utilization|<p>Total cache usage (%).</p>|`Dependent item`|ibm.system.total_cache_pc|
|Performance: Volume read IOPS|<p>Read operations per second.</p>|`Dependent item`|ibm.system.vdisk_r_io|
|Performance: Volume write IOPS|<p>Write operations per second.</p>|`Dependent item`|ibm.system.vdisk_w_io|
|Performance: Volume total IOPS|<p>Total I/O operations per second.</p>|`Dependent item`|ibm.system.vdisk_io|
|Performance: Volume read throughput|<p>Read throughput (Bps).</p>|`Dependent item`|ibm.system.vdisk_r_mb|
|Performance: Volume write throughput|<p>Write throughput (Bps).</p>|`Dependent item`|ibm.system.vdisk_w_mb|
|Performance: Volume read latency|<p>Average read latency (ms).</p>|`Dependent item`|ibm.system.vdisk_r_ms|
|Performance: Volume write latency|<p>Average write latency (ms).</p>|`Dependent item`|ibm.system.vdisk_w_ms|
|Performance: Volume overall latency|<p>Overall volume latency (ms).</p>|`Dependent item`|ibm.system.vdisk_ms|
|Performance: Drive total IOPS|<p>Physical drive IOPS.</p>|`Dependent item`|ibm.system.drive_io|
|Performance: Drive read latency|<p>Drive read latency (ms).</p>|`Dependent item`|ibm.system.drive_r_ms|
|Performance: Drive write latency|<p>Drive write latency (ms).</p>|`Dependent item`|ibm.system.drive_w_ms|
|Performance: FC IOPS|<p>Fibre Channel IOPS.</p>|`Dependent item`|ibm.system.fc_io|
|Performance: FC throughput|<p>FC throughput (Bps).</p>|`Dependent item`|ibm.system.fc_mb|
|Performance: Temperature|<p>Ambient temperature (Celsius).</p>|`Dependent item`|ibm.system.temp_c|
|Performance: Power consumption|<p>Power usage (Watts).</p>|`Dependent item`|ibm.system.power_w|
|SNMP trap: Error events|<p>IBM-SVC-MIB tsveETrap - Error level traps.</p>|`SNMP trap`|snmptrap["1.3.6.1.4.1.2.6.190.1"]|
|SNMP trap: Warning events|<p>IBM-SVC-MIB tsveWTrap - Warning level traps.</p>|`SNMP trap`|snmptrap["1.3.6.1.4.1.2.6.190.2"]|
|SNMP trap: Info events|<p>IBM-SVC-MIB tsveITrap - Informational traps.</p>|`SNMP trap`|snmptrap["1.3.6.1.4.1.2.6.190.3"]|
|SNMP trap: Fallback|<p>Unmatched SNMP traps.</p>|`SNMP trap`|snmptrap.fallback|

## Triggers

|Name|Description|Expression|Priority|
|----|-----------|----------|--------|
|IBM FlashSystem: Unavailable by ICMP ping|<p>Last three ICMP ping attempts failed.</p>|<p>**Expression**: max(/IBM FlashSystem 5300 by REST API and SNMP/icmpping,#3)=0</p>|high|
|IBM FlashSystem: Firmware version changed|<p>Code level has changed.</p>|<p>**Expression**: last(/IBM FlashSystem 5300 by REST API and SNMP/ibm.system.code_level,#1)<>last(/IBM FlashSystem 5300 by REST API and SNMP/ibm.system.code_level,#2) and length(last(/IBM FlashSystem 5300 by REST API and SNMP/ibm.system.code_level))>0</p>|info|
|IBM FlashSystem: CPU utilization warning|<p>CPU usage above warning threshold for 5 minutes.</p>|<p>**Expression**: min(/IBM FlashSystem 5300 by REST API and SNMP/ibm.system.cpu_pc,5m)>{$IBM.CPU.UTIL.WARN}</p>|warning|
|IBM FlashSystem: CPU utilization critical|<p>CPU usage above critical threshold for 5 minutes.</p>|<p>**Expression**: min(/IBM FlashSystem 5300 by REST API and SNMP/ibm.system.cpu_pc,5m)>{$IBM.CPU.UTIL.CRIT}</p>|high|
|IBM FlashSystem: Write cache utilization high|<p>Write cache usage above threshold for 5 minutes.</p>|<p>**Expression**: min(/IBM FlashSystem 5300 by REST API and SNMP/ibm.system.write_cache_pc,5m)>{$IBM.CACHE.UTIL.WARN}</p>|warning|
|IBM FlashSystem: Volume latency warning|<p>Volume latency above warning threshold for 5 minutes.</p>|<p>**Expression**: min(/IBM FlashSystem 5300 by REST API and SNMP/ibm.system.vdisk_ms,5m)>{$IBM.VDISK.LATENCY.WARN}</p>|warning|
|IBM FlashSystem: Volume latency critical|<p>Volume latency above critical threshold for 5 minutes.</p>|<p>**Expression**: min(/IBM FlashSystem 5300 by REST API and SNMP/ibm.system.vdisk_ms,5m)>{$IBM.VDISK.LATENCY.CRIT}</p>|high|
|IBM FlashSystem: Temperature warning|<p>Temperature above warning threshold for 5 minutes.</p>|<p>**Expression**: min(/IBM FlashSystem 5300 by REST API and SNMP/ibm.system.temp_c,5m)>{$IBM.TEMP.WARN}</p>|warning|
|IBM FlashSystem: Temperature critical|<p>Temperature above critical threshold for 5 minutes.</p>|<p>**Expression**: min(/IBM FlashSystem 5300 by REST API and SNMP/ibm.system.temp_c,5m)>{$IBM.TEMP.CRIT}</p>|high|
|IBM FlashSystem: SNMP error trap received|<p>Error-level SNMP trap received from FlashSystem.</p>|<p>**Expression**: nodata(/IBM FlashSystem 5300 by REST API and SNMP/snmptrap["1.3.6.1.4.1.2.6.190.1"],30s)=0</p>|high|
|IBM FlashSystem: SNMP warning trap received|<p>Warning-level SNMP trap received from FlashSystem.</p>|<p>**Expression**: nodata(/IBM FlashSystem 5300 by REST API and SNMP/snmptrap["1.3.6.1.4.1.2.6.190.2"],30s)=0</p>|warning|
|Pool {#NAME}: Utilization warning|<p>Pool usage above warning threshold.</p>|<p>**Expression**: min(/IBM FlashSystem 5300 by REST API and SNMP/ibm.pool.pct_used[{#NAME}],5m)>{$IBM.POOL.UTIL.WARN}</p>|warning|
|Pool {#NAME}: Utilization critical|<p>Pool usage above critical threshold.</p>|<p>**Expression**: min(/IBM FlashSystem 5300 by REST API and SNMP/ibm.pool.pct_used[{#NAME}],5m)>{$IBM.POOL.UTIL.CRIT}</p>|high|
|Pool {#NAME}: Not online|<p>Pool status is not online.</p>|<p>**Expression**: last(/IBM FlashSystem 5300 by REST API and SNMP/ibm.pool.status[{#NAME}])<>"online"</p>|high|
|Drive {#ID}: Not online|<p>Drive status is not online.</p>|<p>**Expression**: last(/IBM FlashSystem 5300 by REST API and SNMP/ibm.drive.status[{#ID}])<>"online"</p>|high|
|Node {#NAME}: Not online|<p>Node canister status is not online.</p>|<p>**Expression**: last(/IBM FlashSystem 5300 by REST API and SNMP/ibm.node.status[{#NAME}])<>"online"</p>|high|
|PSU {#PSU_ID} enclosure {#ENCLOSURE_ID}: Not online|<p>Power supply unit status is not online.</p>|<p>**Expression**: last(/IBM FlashSystem 5300 by REST API and SNMP/ibm.psu.status[{#ENCLOSURE_ID}_{#PSU_ID}])<>"online"</p>|high|
|Battery {#BATTERY_ID} enclosure {#ENCLOSURE_ID}: Not online|<p>Battery status is not online.</p>|<p>**Expression**: last(/IBM FlashSystem 5300 by REST API and SNMP/ibm.battery.status[{#ENCLOSURE_ID}_{#BATTERY_ID}])<>"online"</p>|warning|
|FC Port {#PORT_ID} node {#NODE_NAME}: Not active|<p>FC port is not in expected state.</p>|<p>**Expression**: last(/IBM FlashSystem 5300 by REST API and SNMP/ibm.fc.status[{#PORT_ID}_{#NODE_NAME}])<>"active"</p>|warning|
|Volume {#NAME}: Not online|<p>Volume status is not online.</p>|<p>**Expression**: last(/IBM FlashSystem 5300 by REST API and SNMP/ibm.vdisk.status[{#NAME}])<>"online"</p>|high|

## Author

Jakub Winkler

## License

MIT License

Copyright (c) 2021 Zabbix

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
