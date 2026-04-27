# SNMP Riello Netman208c MTA 16A

## Overview

Template for **Riello MTS / MTA 16A Automatic Transfer Switch (ATS)** monitored via SNMP using the `RIELLOMTS-MIB` (root OID `.1.3.6.1.4.1.5491.12`).

This template is designed for the Riello Netman 208c card. All OIDs are numeric to avoid any MIB dependency on the Zabbix server. It provides comprehensive monitoring of electrical parameters, hardware health, and transfer logic.

## Features

* **Full Inventory**: Tracking of manufacturer, model, software version, and hardware configuration.
* **Electrical Measurements**: Real-time monitoring of S1/S2 voltages, frequencies, output current, load percentage, and phase difference.
* **Status & Control**: Monitoring of preferred source, transfer inhibits, and synchronization status.
* **Advanced Alarming**: Detailed triggers for SCR failures, MCCB trips, auxiliary power failures, and source quality issues like blackout or phase sequence.
* **Zabbix Map Integration**: Dedicated items for active source tracking (mtsOnSourceS1 / mtsOnSourceS2) to visualize power flow.

## Requirements

* **Zabbix Version**: 6.0 or higher.

## Installation

1. Import the `template_riello_netman208c_mta.yaml` file into your Zabbix web interface.
2. Assign the template to your Riello ATS host.
3. Ensure SNMP is enabled on the Netman 208c card and the `{$SNMP_COMMUNITY}` macro is correctly set.

---

## Items

| Name | Key | Description |
| ---- | --- | ----------- |
| **MTS Manufacturer** | `mtsIdentManufacturer` | The name of the mts manufacturer. |
| **MTS Model** | `mtsIdentModel` | The mts Model designation. |
| **MTS Output Load L1** | `mtsLoadL1` | The output load of line 1 (%). |
| **MTS Output Current L1** | `mtsOutputCurrentL1` | The output load current (0.1 A). |
| **MTS S1 Voltage L1** | `mtsS1VoltageL1` | Voltage of source 1. |
| **MTS S2 Voltage L1** | `mtsS2VoltageL1` | Voltage of source 2. |
| **MTS S1 Frequency** | `mtsS1Frequency` | Frequency of source 1 (0.1 Hz). |
| **MTS S2 Frequency** | `mtsS2Frequency` | Frequency of source 2 (0.1 Hz). |
| **MTS Device Temperature** | `mtsTemperature` | Internal temperature of the device. |
| **MTS On Source S1/S2** | `mtsOnSourceS1/S2` | Indicators for which source is currently powering the load. |

## Triggers

| Name | Severity | Description |
| ---- | -------- | ----------- |
| **BOTH SOURCES IN BLACKOUT** | Disaster | S1 and S2 are both down; load is unprotected. |
| **General Failure Detected** | Disaster | Device has detected a critical internal fault. |
| **Output SCR Alternance Loss** | Disaster | Critical hardware fault in the switching circuit. |
| **Source S1/S2 BLACKOUT** | High | Complete power loss on one of the input sources. |
| **Source S1/S2 MCCB Trip** | High | Input circuit breaker has tripped and requires manual reset. |
| **MTS Locked (Transfer Disabled)** | High | Automatic transfer is disabled, removing redundancy. |
| **Using NOT preferred source** | Warning | Device is running on the secondary source while the primary is available. |
| **Output Load High** | Warning | Load exceeds 80% of nominal capacity. |

## Graphs

* **Source Voltages**: Comparison of S1 and S2 input voltages.
* **Source Frequencies**: Comparison of S1 and S2 frequencies.
* **Output Load and Current**: Visualization of power consumption.
* **Device Temperature**: Internal thermal monitoring.
* **Phase Difference**: Angle difference between sources.

## Author

Derived from Eaton ATS template (Original author Maurice Flier), converted and extended for Riello MTS.