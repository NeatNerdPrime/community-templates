# Dell M1000e CMC Enclosure by SNMP

## Overview
This template monitors **Dell M1000e Chassis Management Controllers (CMC)** via SNMP. 
It utilizes targeted Low-Level Discovery (LLD) to identify and monitor enclosure metrics while preventing standard SNMP timeout issues common when querying massive MIB trees natively.

## Features
- Target-specific LLD rules mapped against the `IDRAC-MIB-SMIv2`.
- **Power Supplies:** Discovery and monitoring of PSU Voltage, Current, Rated Power, and Health Status.
- **Blade Servers:** Discovery of Blade Enclosure modules, including Service Tags and Health Status.
- **Chassis Infrastructure:** Direct polling of overall Fan Status, Temperature Status, and IO/Switch module health.
- Detailed System information including Contact, Description, Location, and Firmware version.

## Setup
1. Link this template to your Dell CMC Host.
2. Verify SNMP (v1/v2/v3) is enabled and community strings match.

## Requirements
- Zabbix version: 7.0+
- Applicable for Dell CMC enclosures (M1000e, VRTX, FX2).
