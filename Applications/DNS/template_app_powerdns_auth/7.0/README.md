# PowerDNS Authoritative Server by Zabbix Agent 2

## Overview

This template monitors a [PowerDNS Authoritative Server](https://doc.powerdns.com/authoritative/) instance via its built-in Prometheus metrics endpoint using Zabbix Agent 2 (active mode). It collects all metrics through a single master item and extracts individual values with Prometheus preprocessing.

### Monitored items

**Process monitoring**
- pdns_server process status

**Query & response traffic**
- UDP/TCP queries and answers (total + IPv4/IPv6 breakdown)
- UDP/TCP answer bytes (total + IPv4/IPv6 breakdown)
- RD queries, backend queries
- Cookie queries (UDP/TCP), DO-bit queries
- Response codes: NoError, NXDomain, ServFail, Unauthorized

**Cache**
- Packet cache hits, misses, and size
- Query cache hits, misses, and size
- Zone cache hits, misses, and size
- Deferred cache/packetcache inserts and lookups

**Latency**
- Query latency (average µs)
- Backend latency, cache latency
- Receive latency, send latency

**DNSSEC**
- Signatures made
- Key cache size, signature cache size, meta cache size

**DNS Update & Zone Transfers**
- DNS update queries, answers, changes, refused
- Incoming NOTIFY packets
- XFR queue size

**Recursion**
- Recursing answers, recursing questions, unanswered

**Performance & resources**
- CPU user/system time, I/O wait, steal
- Memory usage, file descriptors
- Open TCP connections, queue size
- Uptime
- Corrupt packets, timed-out packets, overload drops

**Network errors**
- UDP/UDP6 in errors, noport errors, recvbuf errors, sndbuf errors, checksum errors

**Ring buffers**
- Queries, log messages, servfail-queries, remotes-corrupt, unauth-queries ring sizes

### Triggers

| Trigger | Severity |
|---------|----------|
| pdns_auth process not running | High |
| Queries dropped — backends overloaded | High |
| pdns_auth upgrade recommended or required | Warning |
| High memory usage (>1 GB) | Warning |

### Dashboards

The template includes a built-in dashboard with five pages:

- **Overview** — Process status, version, uptime, memory, file descriptors, queue size, and graphs for queries/answers, response codes, errors, and bandwidth.
- **Cache** — Packet cache, query cache, and zone cache hit/miss graphs with cache sizes and deferred operations.
- **Latency** — Query, backend, cache, receive, and send latency over time.
- **Security** — Security status, DNSSEC signatures, key cache, DNS update activity, and notifications/XFR.
- **Performance** — CPU usage, memory, open TCP connections, and IPv4/IPv6 network error graphs.

## Requirements

- Zabbix Server / Proxy **7.0** or later
- Zabbix Agent 2 installed on the PowerDNS Authoritative Server host
- PowerDNS Authoritative Server with the web server and API enabled
- `curl` available on the monitored host

## Setup

### 1. Enable the web server in PowerDNS Authoritative Server

Add the following to your PowerDNS configuration (e.g. `/etc/powerdns/pdns.conf`):

```ini
webserver=yes
webserver-address=127.0.0.1
webserver-port=8081
api=yes
api-key=YOUR-API-KEY
```

Replace `YOUR-API-KEY` with a long random string. Restart PowerDNS after making changes.

Verify the endpoint works:

```bash
curl -s -H 'X-API-Key: YOUR-API-KEY' http://127.0.0.1:8081/metrics
```

### 2. Configure Zabbix Agent 2

Create the file `/etc/zabbix/zabbix_agent2.d/powerdns_auth.conf` with the following content (replace `YOUR-API-KEY` with the key you configured above):

```
UserParameter=pdns.auth.metrics,curl -s -f -m 5 -H 'X-API-Key: YOUR-API-KEY' "http://127.0.0.1:8081/metrics"
```

### 3. Restart Zabbix Agent 2

```bash
sudo systemctl restart zabbix-agent2
```

### 4. Import and assign the template

1. In Zabbix, go to **Data collection → Templates** and import `template_app_powerdns_auth.yaml`.
2. Assign the **PowerDNS Authoritative Server** template to your host.

## Author

Joël de Jager
