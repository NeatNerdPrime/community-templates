# IBM Power HMC – Zabbix REST Monitoring
This repository provides a **working** Zabbix integration for
**IBM Power Hardware Management Console (HMC)** using the **REST UOM API**.

###Author

Rosen Georgiev (rosen.georgiev1@ibm.com)
https://github.com/rgeorgie

### Disclaimer

This project is an independent open source work.
It is not an official IBM product and is not supported by IBM.

It was built and validated against:

- **HMC V10R3**
- **Zabbix 6.2**
- Session‑based REST authentication
- Atom XML responses (HMC REST quirk safe)

> This is **not** a demo or example.
> Every script and template here has been tested against a real HMC.

---

## ✅ What this monitors

### Managed Systems
- Automatic discovery
- State monitoring (`Operating`, `Standby`, etc.)

### LPARs
- Automatic discovery
- State monitoring (`Running`, `Not Activated`, etc.)

### HMC REST availability
- Simple health check using authenticated REST login

---

## ❌ What this does NOT do (by design)

- No SSH
- No PCM / performance metrics
- No VIOS metrics
- No Quick APIs
- No UUID dependency

Those can be added later, **after** a stable base.

---

## 📁 Files

### `files/hmc_api_zb.sh`
Zabbix external script that:
- Logs in via `/rest/api/web/Logon`
- Uses `X‑Audit‑Memento` (required on HMC V10R3)
- Fetches UOM data via Atom XML
- Outputs Zabbix‑compatible discovery JSON

### `template_ibm_power_hmc_rest_external_6.2.yaml`
Zabbix **6.2‑compliant** template:
- All required UUIDs
- Valid YAML
- Valid trigger expressions
- Matches the script **exactly**

---

## 🚀 Installation

### 1️⃣ Install the external script

```bash
install -m 755 files/hmc_api_zbx.sh /usr/lib/zabbix/externalscripts/hmc_api_zbx.sh
chown zabbix:zabbix /usr/lib/zabbix/externalscripts/hmc_api_zbx.sh
