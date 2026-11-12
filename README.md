Enterprise Docker Infrastructure — Multi-Tier Java Web Application

Containerized deployment of a multi-tier Java web application using Docker Compose with enterprise-grade security hardening, health checks, and resource controls.

Architecture
Browser → Nginx (Reverse Proxy) → Tomcat (Java App) → MariaDB / Memcached / RabbitMQ
Container	Role	Port	Image
Nginx	Reverse proxy & load balancer	80	Custom (nginx)
Tomcat	Java application server	8080 (internal)	Custom (tomcat:9-jre11)
MariaDB	Relational database	3306 (internal)	mariadb:10.11
Memcached	In-memory cache	11211 (internal)	memcached:1.6-alpine
RabbitMQ	Message broker	5672 (internal)	rabbitmq:3.13-alpine
Security Hardening
All containers drop Linux capabilities (cap_drop: ALL), adding back only what each service needs
Read-only root filesystems where supported, with targeted tmpfs mounts
Secrets managed via Docker secrets (not environment variables)
Internal bridge network — only Nginx is exposed to the host
Resource limits (CPU and memory) on every container
Health checks on all services with configurable intervals and retries
Restart policy (unless-stopped) for automatic recovery
Prerequisites
Docker Engine 20.10+
Docker Compose v2
Project Structure
├── App-Tomcat/
│   └── Dockerfile          # Multi-stage build: Maven → Tomcat
├── MariaDB/
│   └── init.sql            # Database schema and seed data
├── Nginx/
│   ├── Dockerfile          # Custom Nginx with proxy config
│   └── nginvproapp.conf    # Reverse proxy configuration
├── RabbitMQ/
│   └── rabbitmq.conf       # RabbitMQ listener and memory settings
├── secrets/
│   └── db-root-password.txt  # Database root password (not in repo)
├── docker-compose.yml      # Full stack orchestration
├── .gitignore
└── README.md
Quick Start
Clone the repository:
bash
   git clone https://github.com/amrsherifahmed/Enterprise_Docker_Infrastructure_Security.git
   cd Enterprise_Docker_Infrastructure_Security
Create the secrets directory and set the database password:
bash
   mkdir -p secrets
   echo "mariadbpass" > secrets/db-root-password.txt
Start the stack:
bash
   docker compose up -d
Wait for all containers to become healthy (about 2-3 minutes):
bash
   docker compose ps
Access the application:
   http://localhost
Login with default credentials:
Username: admin_vp
Password: admin_vp
Useful Commands
bash
# View all container statuses and health
docker compose ps

# View logs for a specific service
docker compose logs app --tail 50

# Restart a single service
docker compose restart nginx

# Rebuild after Dockerfile changes
docker compose build --no-cache app
docker compose up -d

# Stop everything
docker compose down

# Full reset (including database data)
docker compose down
docker volume rm $(docker volume ls -q --filter name=dockercompose)
docker compose up -d
How It Works
Nginx receives all incoming HTTP requests on port 80 and proxies them to the Tomcat application server.
Tomcat runs the vprofile Java application, which connects to MariaDB for persistent data, Memcached for session caching, and RabbitMQ for asynchronous messaging.
MariaDB stores user accounts and application data. The init.sql script automatically seeds the database on first startup.
Memcached provides in-memory caching to reduce database load and improve response times.
RabbitMQ handles background task queuing and asynchronous message processing.
Network Topology

All containers communicate over a private Docker bridge network (vprofile-net). Only the Nginx container maps a port to the host. Backend services (MariaDB, Memcached, RabbitMQ) are not accessible from outside the Docker network.

Host Machine
  └── port 80 ──→ Nginx ──→ [vprofile-net]
                                 ├── app (Tomcat:8080)
                                 ├── mariadb (3306)
                                 ├── memcached (11211)
                                 └── rabbitmq (5672)
Persistent Data
Volume	Container	Purpose
db_data	MariaDB	Database files
rabbitmq_data	RabbitMQ	Queue and message data

Data survives container restarts. To reset completely, remove the volumes with docker volume rm.

Customization
Database password: Edit secrets/db-root-password.txt (requires volume reset on change)
Nginx config: Edit Nginx/nginvproapp.conf and rebuild Nginx
RabbitMQ settings: Edit RabbitMQ/rabbitmq.conf
Resource limits: Adjust deploy.resources.limits in docker-compose.yml
Troubleshooting
Symptom	Cause	Fix
App shows 403 CSRF error	Stale browser session	Clear cookies or open http://localhost
App container unhealthy	Database not ready	Wait 2-3 minutes, check docker compose logs app
Nginx restarting	Missing capabilities	Ensure cap_add includes CHOWN, DAC_OVERRIDE, NET_BIND_SERVICE
Login fails	Wrong credentials	Use admin_vp / admin_vp
Built With
Java 11 + Spring Framework
Apache Tomcat 9
MariaDB 10.11
Memcached 1.6
RabbitMQ 3.13
Nginx (latest)
Docker Compose v2
