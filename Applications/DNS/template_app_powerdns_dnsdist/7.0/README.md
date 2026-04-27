# PowerDNS dnsdist by Zabbix Agent 2

## Overview

This template monitors a [PowerDNS dnsdist](https://dnsdist.org/) instance via its built-in Prometheus metrics endpoint using Zabbix Agent 2 (active mode). It collects all metrics through a single master item and extracts individual values with Prometheus preprocessing.

Backend servers are automatically discovered via low-level discovery (LLD).

### Monitored items

**Process monitoring**
- dnsdist process status

**Query & response traffic**
- Queries received / responses from backends
- RD queries, empty queries, self-answered responses
- Frontend answers by type (NoError, NXDomain, ServFail)

**Cache**
- Global cache hits / misses
- Per-pool cache hits, misses, entries, and size

**Latency**
- Latency distribution buckets (0-1 ms, 1-10 ms, 10-50 ms, 50-100 ms, 100-1000 ms, slow >1 s)
- Average latency (last 100 / 1K / 10K / 1M packets)
- Per-protocol average latency (TCP, DoT, DoH, DoQ)

**Security & rules**
- ACL drops, dynamic blocks, noncompliant queries/responses
- Rule actions (drop, nxdomain, refused, servfail, truncated)
- Security status, proxy protocol invalid
- dnsdist version

**Backend servers (auto-discovered)**
- Status (up/down), queries, responses, drops
- Latency (UDP + TCP), send errors, outstanding queries
- TCP current connections, health check failures

**Performance & resources**
- CPU user/system time, I/O wait, steal
- Memory usage, file descriptors
- No-policy drops, truncation failures
- UDP/UDP6 network errors, TCP listen overflows
- DoH pipe full events

**Pool**
- Total and active server count in the default pool

### Triggers

| Trigger | Severity |
|---------|----------|
| dnsdist process not running | High |
| Backend server is DOWN (per-server, auto-discovered) | High |
| Queries dropped — no backend available | High |
| High backend timeout rate (>10) | Warning |
| dnsdist upgrade recommended or required | Warning |
| High memory usage (>1 GB) | Warning |

### Dashboards

The template includes a built-in dashboard with five pages:

- **Overview** — Process status, version, uptime, memory usage, and graphs for queries/responses and frontend answers.
- **Cache** — Cache and pool cache hit/miss graphs and cache entry counts.
- **Latency** — Latency distribution histogram and average latency over time.
- **Security** — Security status, dynamic block entries, pool servers, and a security events graph.
- **Performance** — CPU usage and memory usage graphs, file descriptor count, and rule action graph.

## Requirements

- Zabbix Server / Proxy **7.0** or later
- Zabbix Agent 2 installed on the dnsdist host
- PowerDNS dnsdist with the web server
- `curl` available on the monitored host

## Setup

### 1. Enable the web server in dnsdist

Add the following to your dnsdist [webserver configuration](https://www.dnsdist.org/guides/webserver.html) (e.g. `/etc/dnsdist/dnsdist.conf`):

```lua
webserver("127.0.0.1:8083")
setWebserverConfig({apiKey="YOUR-API-KEY"})
```

Replace `YOUR-API-KEY` with a long random string. Restart dnsdist after making changes. 

Verify the endpoint works:

```bash
curl -s -H 'X-API-Key: YOUR-API-KEY' http://127.0.0.1:8083/metrics
```

### 2. Configure Zabbix Agent 2

Create the file `/etc/zabbix/zabbix_agent2.d/powerdns_dnsdist.conf` with the following content (replace `YOUR-API-KEY` with the key you configured above):

```
UserParameter=pdns.dnsdist.metrics,curl -s -f -m 5 -H 'X-API-Key: YOUR-API-KEY' "http://127.0.0.1:8083/metrics"
```

### 3. Restart Zabbix Agent 2

```bash
sudo systemctl restart zabbix-agent2
```

### 4. Import and assign the template

1. In Zabbix, go to **Data collection → Templates** and import `template_app_powerdns_dnsdist.yaml`.
2. Assign the **PowerDNS dnsdist** template to your dnsdist host.

## Author

Joël de Jager (rewrite), Manuel Frei (original)
