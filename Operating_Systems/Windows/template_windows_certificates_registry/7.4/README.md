# Zabbix Templates — Windows Certificate Monitoring

Monitor Windows machine certificates via the registry, using **Zabbix Agent 2** in active mode — no external scripts, no PowerShell, no scheduled tasks.

---

## Templates

| File | Language |
|---|---|
| `windows_certificates_registry.yaml` | English |


Only display fields (`name`, `description`, macro descriptions) differ.

---

## How It Works

A single LLD rule calls `registry.get` in **values mode**, which recursively returns all registry values under:

```
HKLM\SOFTWARE\Microsoft\SystemCertificates
```

A JavaScript preprocessing step:

1. Filters entries whose `fullkey` matches `\{store}\Certificates\{thumbprint40hex}` and whose value `name` is `Blob`
2. Decodes the base64 REG_BINARY blob (Windows CryptoAPI format)
3. Locates `propId 32` (`CERT_CERT_PROP_ID`) to extract the raw DER X.509 certificate
4. Parses the ASN.1 DER structure to extract the **Subject CN** and **NotAfter** date
5. Produces three LLD macros: `{#CERT_STORE}`, `{#CERT_THUMBPRINT}`, `{#CERT_CN}`

Each discovered certificate gets three item prototypes:

| Item | Type | Description |
|---|---|---|
| Blob | `ZABBIX_ACTIVE` | Raw REG_BINARY blob (base64). Master item, not stored. |
| Expiry date | `DEPENDENT` | NotAfter extracted from DER → Unix timestamp |
| Days until expiration | `CALCULATED` | `(expiry - now()) / 86400` |

---

## Requirements

| Component | Requirement |
|---|---|
| Zabbix Server | **7.4** |
| Zabbix Agent | **Agent 2**, active mode |
| OS | Windows (any version with CryptoAPI machine stores) |

> The template uses `ZABBIX_ACTIVE` item type throughout. The agent must be configured with `ServerActive=` pointing to your Zabbix server.

---

## Installation

1. In Zabbix: **Configuration → Templates → Import**
2. Select `windows_certificates_registry.yaml` (or the French variant)
3. Click **Import**
4. Link the template to the target Windows host

---

## Configuration

All thresholds are controlled by **host macros** — override them per host or host group as needed.

| Macro | Default | Description |
|---|---|---|
| `{$CERT.STORES}` | `^MY$` | Regex filter on store name. Default: Personal machine store only. |
| `{$CERT.EXPIRY.WARN}` | `30` | Days before expiration → WARNING alert |
| `{$CERT.EXPIRY.HIGH}` | `15` | Days before expiration → HIGH alert |
| `{$CERT.EXPIRY.DISASTER}` | `7` | Days before expiration → DISASTER alert |

### Store filter examples

| Value | Stores monitored |
|---|---|
| `^MY$` | Personal (machine) only — **default** |
| `^(MY\|ROOT)$` | Personal + Trusted Root CAs |
| `^(MY\|ROOT\|CA)$` | Personal + Root CAs + Intermediate CAs |
| `.*` | All stores (may include noise) |

> **Note:** Store names containing spaces (e.g. `Remote Desktop`, `AAD Token Issuer`) are automatically excluded because they are invalid in Zabbix item keys.

---

## Triggers

Four trigger prototypes fire in cascade (each depends on the one above it to avoid alert floods):

| Severity | Condition |
|---|---|
| 🔴 DISASTER | Certificate **already expired** (days < 0) |
| 🔴 DISASTER | Expires in less than `{$CERT.EXPIRY.DISASTER}` days |
| 🟠 HIGH | Expires in less than `{$CERT.EXPIRY.HIGH}` days |
| 🟡 WARNING | Expires in less than `{$CERT.EXPIRY.WARN}` days |

---

## Tags

| Tag | Value |
|---|---|
| `component` | `certificates` |
| `target` | `windows` |

---

## Troubleshooting

**No certificates discovered**
- Confirm Zabbix Agent 2 is running in active mode and `ServerActive` is set
- Check that `{$CERT.STORES}` matches your target store (default `^MY$` = Personal store only)
- Force discovery: Latest Data → discovery rule → *Execute now*

**`Days until expiration` shows no data**
- The CALCULATED item depends on `Expiry date` (DEPENDENT). Wait for at least one collection cycle after discovery.

**Item key error on import**
- Ensure no store name with spaces slipped through — the LLD regex `[A-Za-z0-9_-]+` already excludes them.

---

## File Reference

| File | Purpose |
|---|---|
| `windows_certificates_registry.yaml` | Production template (English) |

