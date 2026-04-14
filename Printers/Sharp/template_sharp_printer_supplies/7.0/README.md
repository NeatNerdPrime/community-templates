# Sharp Printer Supplies SNMP Template

Zabbix template for monitoring printer consumables via SNMP (Printer-MIB).

## Features
- Automatic discovery of supplies (toner, drum, developer, waste toner)
- Works with monochrome and color printers
- Filters invalid values (-1, -2, -3) via preprocessing
- No manual OID configuration required

## Requirements
- SNMP v2c enabled on printer
- Printer supports Printer-MIB (RFC 3805)

## Tested on
- Sharp MX-M3570
- Sharp MX-2630N
- Sharp MX-B355W

## Notes
- Values are interpreted as percentage where supported by the device
- Some printers may return absolute values instead of percentages
