# lifting-log-infra

Production cloud infrastructure configuration for [lifting-log](https://github.com/hamzahuda/lifting-log), a workout tracking application. Provisions and manages AWS resources with Terraform, orchestrates services with Docker Compose, automates deployments via GitHub Actions, and monitors the stack with Prometheus and Grafana.

<p align="center">
  <img src="readme-files/Grafana%20Dashboard.gif" width="600" alt="Grafana Dashboard 10x Speed">
  <br>
  <sub>Real-time workout metrics visualized on the Grafana dashboard (10x speed)</sub>
</p>

## Stack

| Layer                  | Technology              |
| ---------------------- | ----------------------- |
| Cloud provider         | AWS (eu-north-1)        |
| Infrastructure as Code | Terraform               |
| Remote state           | S3                      |
| Compute                | EC2 t3.micro            |
| Containerisation       | Docker / Docker Compose |
| Reverse proxy & TLS    | Nginx + Let's Encrypt   |
| Backend                | Django                  |
| Monitoring             | Prometheus + Grafana    |
| CI/CD                  | GitHub Actions          |

## Repository structure

```
lifting-log-infra/
├── .github/
│   └── workflows/        # GitHub Actions CI/CD pipelines
├── nginx/                # Nginx server configuration
├── prometheus/
│   └── prometheus.yml    # Prometheus scrape configuration
├── docker-compose.prod.yml
├── main.tf               # Terraform root module
└── .terraform.lock.hcl
```

## Infrastructure

### AWS resources (`main.tf`)

Terraform provisions two resources:

**Security group** (`lifting-log-sg`) - allows inbound TCP on:

- Port 80 (HTTP)
- Port 443 (HTTPS)
- Port 22 (SSH)
- All outbound traffic

**EC2 instance** (`lifting-log-backend-prod`) - `t3.micro`, runs the full Docker Compose stack.

Remote state is stored in an S3 bucket so the state file is shared and versioned.

### Services

`docker-compose.prod.yml` is layered on top of the base `docker-compose.yml` in the [lifting-log](https://github.com/hamzahuda/lifting-log) application repository during production deployment. The base file defines the core application services; this file extends them with production settings and adds the infrastructure services.

**Base services** (defined in `lifting-log/docker-compose.yml`, extended here):

| Service  | Image                       | Purpose                          |
| -------- | --------------------------- | -------------------------------- |
| `db`     | `mysql:8.0`                 | MySQL database with health check |
| `django` | Built from app `Dockerfile` | Django application backend       |

**Production overrides & additions** (`docker-compose.prod.yml`):

| Service      | Image                    | Purpose                                             |
| ------------ | ------------------------ | --------------------------------------------------- |
| `db`         | -                        | Adds `restart: always`                              |
| `django`     | -                        | Adds `restart: always`, mounts `static_volume`      |
| `nginx`      | `nginx:alpine`           | Reverse proxy, TLS termination, static file serving |
| `prometheus` | `prom/prometheus:latest` | Metrics collection                                  |
| `grafana`    | `grafana/grafana:latest` | Metrics visualisation                               |

**Volumes**

- `static_volume` - Django static assets served by Nginx
- `prometheus_data` - Prometheus time-series data
- `grafana_data` - Grafana dashboards and settings

Nginx mounts the host's `/etc/letsencrypt` directory (read-only) for TLS certificates and `/var/log/nginx` for access and error logs (which fail2ban uses).
