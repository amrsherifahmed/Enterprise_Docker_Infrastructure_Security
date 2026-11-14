# 🏗️ Enterprise Docker Infrastructure
## Microservices for Java Web Application (Tomcat) — Secure, Hardened & Isolated

## 📌 Executive Summary

This repository contains a **production-ready, highly hardened, and isolated microservices infrastructure** built with Docker & Docker Compose for the enterprise **VProfile Web Application**.

The architecture strictly adheres to enterprise **DevSecOps** standards, implementing **Defense-in-Depth**, **Network Isolation**, **Least Privilege Access Control**, **Docker Secrets**, and **Vulnerability Scanning via Aqua Security Trivy**.

---

## 🏛️ Architecture & Network Isolation

```
                        [ Internet / Client ]
                                |
                          | HTTP (Port 80)
                                ▼
              ─────────── [ Bridge Network ] ───────────
              |                                        |
              |        NGINX Reverse Proxy              |
              |   - Port 80 Ingress only                |
              |   - Reverse proxies to Tomcat Backend   |
              |                                        |
              ──────────────────────────────────────────
                                |
                          | HTTP (Port 8080)
                                ▼
              ──────────────────────────────────────────
              |                                        |
              |     Tomcat Application Server           |
              |   - Runs Spring / Java 11 VProfile App  |
              |                                        |
              ──────────────────────────────────────────
                     |              |              |
                     ▼              ▼              ▼
              ┌──────────┐  ┌──────────┐  ┌──────────┐
              │ MariaDB  │  │Memcached │  │ RabbitMQ │
              │  (3306)  │  │ (11211)  │  │  (5672)  │
              └──────────┘  └──────────┘  └──────────┘
                     |              |              |
              ┌──────────┐  ┌──────────┐  ┌──────────┐
              │ db_data  │  │  (RAM)   │  │ rmq_data │
              │ (Volume) │  │          │  │ (Volume) │
              └──────────┘  └──────────┘  └──────────┘
```

---

## 📦 Container Inventory

| Container | Image | Role | Port | Network Exposure |
|-----------|-------|------|------|-----------------|
| **Nginx** | Custom (nginx) | Reverse Proxy & Load Balancer | 80 | External (host-mapped) |
| **Tomcat** | Custom (tomcat:9-jre11) | Java Application Server | 8080 | Internal only |
| **MariaDB** | mariadb:10.11 | Relational Database (RDBMS) | 3306 | Internal only |
| **Memcached** | memcached:1.6-alpine | In-Memory Cache | 11211 | Internal only |
| **RabbitMQ** | rabbitmq:3.13-alpine | Message Broker / Task Queue | 5672 | Internal only |

---

## 🔒 Security & Hardening

### Defense-in-Depth Controls

| Security Control | Implementation | Purpose |
|-----------------|----------------|---------|
| **Drop All Capabilities** | `cap_drop: ALL` on every container | Removes all Linux kernel capabilities by default |
| **Minimal Capability Add-back** | `cap_add:` only what's needed per service | Least privilege — each container gets only the capabilities it requires |
| **Read-Only Filesystem** | `read_only: true` where supported | Prevents runtime modification of container filesystem |
| **Temporary Filesystems** | `tmpfs:` for writable paths | Volatile storage that doesn't persist — limits attack surface |
| **Docker Secrets** | `secrets:` for database password | Credentials stored in `/run/secrets/`, never in environment variables |
| **Resource Limits** | `deploy.resources.limits` (CPU & Memory) | Prevents resource exhaustion and DoS attacks |
| **Network Isolation** | Internal bridge network | Backend services are not exposed to the host |
| **Health Checks** | `healthcheck:` on every container | Automatic detection of unhealthy containers |
| **Restart Policy** | `restart: unless-stopped` | Automatic recovery from crashes |
| **Minimal Base Images** | Alpine variants where possible | Smaller attack surface with fewer packages |

### Capability Matrix

| Container | Capabilities Added | Reason |
|-----------|-------------------|--------|
| Nginx | CHOWN, DAC_OVERRIDE, SETGID, SETUID, NET_BIND_SERVICE | Cache directory ownership, user switching, bind to port 80 |
| Tomcat | SETGID, SETUID | User switching for Tomcat process |
| MariaDB | DAC_OVERRIDE, SETGID, SETUID | File permissions and user switching for database process |
| RabbitMQ | SETGID, SETUID, DAC_OVERRIDE | User switching for Erlang runtime |
| Memcached | _(none)_ | Runs with zero added capabilities |

---

## 🛡️ Vulnerability Scan Results (Trivy)

All images are scanned using [Aqua Security Trivy](https://trivy.dev/) for known CVEs at HIGH and CRITICAL severity.

**Scan Date:** November 2026  
**Trivy Version:** 0.71.2  
**Scan Command:** `./scripts/trivy-scan.sh`

| Image | OS | HIGH | CRITICAL | Status | Notes |
|-------|-----|------|----------|--------|-------|
| **App (Tomcat)** | Ubuntu | — | — | ⚠️ | Custom build — scan after each rebuild |
| **Nginx** | Debian | — | — | ⚠️ | Custom build — scan after each rebuild |
| **MariaDB 10.11** | Ubuntu 22.04 | 25 | 1 | ⚠️ | All in `gosu` binary (upstream Go stdlib) |
| **Memcached 1.6-alpine** | Alpine 3.24 | 0 | 0 | ✅ Clean | No vulnerabilities detected |
| **RabbitMQ 3.13-alpine** | Alpine 3.22 | 22 | 2 | ⚠️ | OpenSSL, musl, zlib (upstream Alpine packages) |

### Analysis

**MariaDB** — All 26 vulnerabilities originate from the `gosu` binary (a Go utility for user switching) bundled in the official MariaDB image. The Go standard library it was compiled with is outdated. The Ubuntu 22.04 OS packages are clean. This is an upstream issue tracked in the official image — no user-side fix is available until the image maintainers rebuild `gosu` with an updated Go toolchain.

**RabbitMQ** — The 24 vulnerabilities are in system-level Alpine packages (OpenSSL 3.5.4, musl 1.2.5, zlib 1.3.1). Fixed versions exist in newer Alpine releases. These will be resolved when the RabbitMQ image is rebuilt against a newer Alpine base.

**Memcached** — Fully clean. Alpine 3.24 base with zero known HIGH or CRITICAL vulnerabilities.

### Remediation Strategy

- Pin image versions and monitor for updates
- Re-run Trivy scans on every build (`./scripts/trivy-scan.sh`)
- Upgrade to newer image tags as upstream fixes are released
- The `gosu` and Alpine package vulnerabilities are mitigated by the hardening controls above (dropped capabilities, read-only filesystem, network isolation)

---

## 🚀 Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose v2
- Trivy (for security scanning)

### 1. Clone the Repository

```bash
git clone https://github.com/amrsherifahmed/Enterprise_Docker_Infrastructure_Security.git
cd Enterprise_Docker_Infrastructure_Security
```

### 2. Create Secrets

```bash
mkdir -p secrets
echo "mariadbpass" > secrets/db-root-password.txt
```

### 3. Start the Stack

```bash
docker compose up -d
```

### 4. Verify All Containers Are Healthy

```bash
docker compose ps
```

Wait 2-3 minutes for all services to initialize. Expected output:

```
NAME              STATUS
vprofile-nginx    Up (healthy)
vprofile-app      Up (healthy)
vprofile-db       Up (healthy)
vprofile-cache    Up (started)
vprofile-queue    Up (healthy)
```

### 5. Access the Application

```
http://localhost
```

**Login Credentials:**
- Username: `admin_vp`
- Password: `admin_vp`

---

## 📁 Project Structure

```
├── App-Tomcat/
│   └── Dockerfile              # Multi-stage build: Maven compile → Tomcat runtime
├── MariaDB/
│   └── init.sql                # Database schema and seed data (auto-runs on first start)
├── Nginx/
│   ├── Dockerfile              # Custom Nginx with reverse proxy config
│   └── nginvproapp.conf        # Upstream proxy to Tomcat backend
├── RabbitMQ/
│   └── rabbitmq.conf           # Listener, memory watermark settings
├── scripts/
│   └── trivy-scan.sh           # Automated Trivy vulnerability scanner
├── secrets/
│   └── db-root-password.txt    # Database root password (not in repo)
├── docker-compose.yml          # Full stack orchestration with hardening
├── .gitignore
└── README.md
```

---

## 🔧 How It Works

### Request Flow

```
Client → Nginx (port 80) → Tomcat (port 8080) → MariaDB / Memcached / RabbitMQ
```

1. **Nginx** receives all incoming HTTP requests on port 80 and reverse proxies them to the Tomcat application server. It is the only container exposed to the host network.

2. **Tomcat** runs the VProfile Java application (Spring Framework + Hibernate). It connects to three backend services over the internal Docker bridge network.

3. **MariaDB** stores user accounts and application data. The `init.sql` script automatically creates the schema and seeds data on the first container start.

4. **Memcached** provides in-memory caching for session data and frequently accessed queries, reducing database load.

5. **RabbitMQ** handles asynchronous message queuing for background tasks and event-driven processing.

### Data Persistence

| Volume | Container | Purpose |
|--------|-----------|---------|
| `db_data` | MariaDB | Database files survive container restarts |
| `rabbitmq_data` | RabbitMQ | Queue and message data persistence |

Memcached data is stored in RAM only (by design) and is not persisted.

---

## 🔐 Secrets Management

Database credentials are managed via **Docker Secrets**, not environment variables:

```yaml
secrets:
  db-root-password:
    file: ./secrets/db-root-password.txt
```

Inside the MariaDB container, the password is available at `/run/secrets/db-root-password` — a tmpfs mount that exists only in memory and is never written to disk.

The `secrets/` directory is excluded from version control via `.gitignore`.
```

### Monitoring Health Checks

Every container includes a health check. Docker automatically monitors them:

| Container | Health Check | Interval | Start Period |
|-----------|-------------|----------|--------------|
| Nginx | `curl http://localhost:80` | 30s | 10s |
| Tomcat | `curl http://localhost:8080/login` | 30s | 120s |
| MariaDB | `healthcheck.sh --connect --innodb_initialized` | 30s | 30s |
| Memcached | `echo stats \| nc localhost 11211` | 30s | 10s |
| RabbitMQ | `rabbitmq-diagnostics -q ping` | 30s | 30s |

---

## ⚠️ Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| 403 CSRF error on login | Stale browser session | Clear cookies or open `http://localhost` fresh |
| App container unhealthy | Database not ready yet | Wait 2-3 minutes, check `docker compose logs app` |
| Nginx keeps restarting | Missing capabilities | Ensure `cap_add` includes CHOWN, DAC_OVERRIDE, NET_BIND_SERVICE |
| Port 80 already in use | Another web server on host | `sudo systemctl stop apache2 nginx` or change port to 8081 |
| Login fails silently | Database connection issue | `docker compose logs app \| grep error` |
| RabbitMQ won't start | cap_drop too restrictive | Ensure `cap_add` includes SETGID, SETUID, DAC_OVERRIDE |

---

## 🏗️ Built With

| Technology | Version | Purpose |
|-----------|---------|---------|
| Java | 11 (OpenJDK) | Application runtime |
| Spring Framework | 4.2.0 | Web application framework |
| Apache Tomcat | 9.0 | Servlet container |
| MariaDB | 10.11 LTS | Relational database |
| Memcached | 1.6 | In-memory caching |
| RabbitMQ | 3.13 | Message broker |
| Nginx | Latest | Reverse proxy |
| Docker Compose | v2 | Container orchestration |
| Trivy | 0.71+ | Vulnerability scanning |
