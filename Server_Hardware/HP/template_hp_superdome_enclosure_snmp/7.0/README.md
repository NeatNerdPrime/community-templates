# HP BladeSystem Superdome Enclosure by SNMP

## Overview
This template provides comprehensive SNMP monitoring for **HP BladeSystem Superdome Enclosures** relying on the `CPQRACK-MIB`.
It is specifically engineered to bypass the massive SNMP timeout failures that occur on older Management Modules when using Zabbix's default bulk-get requests on massive asset tables like `cpqRackCommonEnclosureAssetTable`.

## Features
- Granular Low-Level Discovery (LLD) to bypass SNMP timeouts.
- **Blade Servers:** Discovers Blade Names, Models, and Operational Status.
- **Power Supplies:** Discovers PSU Serial Numbers, identifies Max Watts, and measures precise Health Status.
- **Cooling (Fans):** Discovers all Chassis Fans and reports operational Condition.
- **Temperature:** Evaluates internal temperature probes across Blade Bays, System, and Interconnect Trays.
- Pre-configured Value Mappings (`HP-MIB::PSUStatusEnum`, `HP-MIB::StatusEnum`).
- Built-in trigger prototypes for early failure detection (`Failed`, `Degraded`, `TempFailure`, etc.)

## Setup
1. Assign this template to your HP Enclosure Management IP.
2. Ensure SNMPv2 is configured on the host.
3. Disable `Use bulk requests` on the host interface in Zabbix if your management module still experiences timeout issues.

## Requirements
- Zabbix version: 7.0+
- Tested on HP CPQRACK-MIB architectures.
