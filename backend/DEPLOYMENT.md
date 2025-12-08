# Deployment Guide

This guide covers deploying the E-Commerce Marketplace Backend to production environments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Configuration](#environment-configuration)
- [Docker Deployment](#docker-deployment)
- [Manual Deployment](#manual-deployment)
- [Database Setup](#database-setup)
- [Security Hardening](#security-hardening)
- [Monitoring & Logging](#monitoring--logging)
- [Backup & Recovery](#backup--recovery)
- [CI/CD Pipeline](#cicd-pipeline)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Server Requirements

**Minimum**:
- 2 CPU cores
- 4GB RAM
- 20GB SSD storage
- Ubuntu 20.04+ or similar Linux distribution

**Recommended**:
- 4+ CPU cores
- 8GB+ RAM
- 50GB+ SSD storage
- Load balancer for high availability

### Software Requirements

- **Docker**: 20.10+ and Docker Compose 2.0+
- **PostgreSQL**: 14+ (managed or self-hosted)
- **Python**: 3.11+ (if not using Docker)
- **Nginx**: Latest (for reverse proxy)
- **SSL Certificate**: Let's Encrypt or commercial

## Environment Configuration

### Production Environment Variables

Create a `.env.production` file:

```env
# Application
APP_NAME=E-Commerce Marketplace API
APP_VERSION=1.0.0
ENVIRONMENT=production
DEBUG=False
API_PREFIX=/api/v1

# Security - CRITICAL: Use strong random values
SECRET_KEY=<generate-with-openssl-rand-base64-32>
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# Database
DATABASE_URL=postgresql+asyncpg://user:password@db-host:5432/marketplace_prod

# CORS - Restrict to your frontend domain
ALLOWED_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Logging
LOG_LEVEL=INFO

# Rate Limiting
RATE_LIMIT_ENABLED=True
RATE_LIMIT_PER_MINUTE=60

# File Upload
UPLOAD_DIR=./uploads
MAX_UPLOAD_SIZE=5242880

# Email (if implementing)
# SMTP_HOST=smtp.gmail.com
# SMTP_PORT=587
# SMTP_USER=your-email@gmail.com
# SMTP_PASSWORD=your-app-password

# Payment Gateway (if implementing)
# STRIPE_API_KEY=sk_live_...
# PAYPAL_CLIENT_ID=...
```

### Generate Secure Keys

```bash
# Generate SECRET_KEY
openssl rand -base64 32

# Or using Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

## Docker Deployment

### 1. Update docker-compose.yml for Production

Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        - ENV=production
    container_name: ecommerce_backend_prod
    restart: always
    ports:
      - "8000:8000"
    environment:
      - ENVIRONMENT=production
    env_file:
      - .env.production
    volumes:
      - ./uploads:/app/uploads
      - ./logs:/app/logs
    depends_on:
      - db
    networks:
      - backend_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    image: postgres:14-alpine
    container_name: ecommerce_db_prod
    restart: always
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data_prod:/var/lib/postgresql/data
    networks:
      - backend_network
    ports:
      - "127.0.0.1:5432:5432"  # Only accessible locally

  nginx:
    image: nginx:alpine
    container_name: ecommerce_nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - ./logs/nginx:/var/log/nginx
    depends_on:
      - backend
    networks:
      - backend_network

volumes:
  postgres_data_prod:
    driver: local

networks:
  backend_network:
    driver: bridge
```

### 2. Production Dockerfile

Update `Dockerfile` for multi-stage build:

```dockerfile
# Build stage
FROM python:3.11-slim as builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage
FROM python:3.11-slim

WORKDIR /app

# Copy Python dependencies from builder
COPY --from=builder /root/.local /root/.local

# Install only PostgreSQL client
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p /app/uploads /app/logs

# Set environment
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

### 3. Deploy with Docker

```bash
# Build and start services
docker-compose -f docker-compose.prod.yml up -d --build

# View logs
docker-compose -f docker-compose.prod.yml logs -f backend

# Stop services
docker-compose -f docker-compose.prod.yml down

# Update and restart
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d --build
```

## Manual Deployment

### 1. Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python and dependencies
sudo apt install -y python3.11 python3.11-venv python3-pip \
    postgresql-client nginx certbot python3-certbot-nginx

# Create app user
sudo useradd -m -s /bin/bash appuser
sudo su - appuser
```

### 2. Application Setup

```bash
# Clone repository
git clone <repository-url> /home/appuser/app
cd /home/appuser/app/backend

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Setup environment
cp .env.example .env.production
nano .env.production  # Edit with production values

# Create directories
mkdir -p uploads logs

# Run database migrations
alembic upgrade head

# Create admin user
python3 scripts/create_admin.py
```

### 3. Systemd Service

Create `/etc/systemd/system/ecommerce-backend.service`:

```ini
[Unit]
Description=E-Commerce Backend Service
After=network.target postgresql.service

[Service]
Type=notify
User=appuser
Group=appuser
WorkingDirectory=/home/appuser/app/backend
Environment="PATH=/home/appuser/app/backend/venv/bin"
EnvironmentFile=/home/appuser/app/backend/.env.production
ExecStart=/home/appuser/app/backend/venv/bin/uvicorn app.main:app \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 4 \
    --log-level info
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable ecommerce-backend
sudo systemctl start ecommerce-backend
sudo systemctl status ecommerce-backend

# View logs
sudo journalctl -u ecommerce-backend -f
```

### 4. Nginx Configuration

Create `/etc/nginx/sites-available/ecommerce-backend`:

```nginx
# Rate limiting
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

# Upstream backend
upstream backend {
    least_conn;
    server 127.0.0.1:8000 max_fails=3 fail_timeout=30s;
}

# HTTP to HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name api.yourdomain.com;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.yourdomain.com;
    
    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 10m;
    ssl_session_cache shared:SSL:10m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Logging
    access_log /var/log/nginx/ecommerce-backend-access.log;
    error_log /var/log/nginx/ecommerce-backend-error.log;
    
    # API endpoints
    location /api {
        limit_req zone=api_limit burst=20 nodelay;
        
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # Health check (no rate limit)
    location /health {
        proxy_pass http://backend;
        access_log off;
    }
    
    # Static files (if any)
    location /uploads {
        alias /home/appuser/app/backend/uploads;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

Enable site:

```bash
sudo ln -s /etc/nginx/sites-available/ecommerce-backend /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 5. SSL Certificate

```bash
# Install SSL certificate
sudo certbot --nginx -d api.yourdomain.com

# Test renewal
sudo certbot renew --dry-run

# Auto-renewal is configured by default with certbot
```

## Database Setup

### Managed PostgreSQL (Recommended)

Use managed PostgreSQL services:
- **AWS RDS**
- **Google Cloud SQL**
- **Azure Database for PostgreSQL**
- **DigitalOcean Managed Databases**

Benefits:
- Automated backups
- High availability
- Automatic updates
- Monitoring included

### Self-Hosted PostgreSQL

```bash
# Install PostgreSQL
sudo apt install postgresql-14 postgresql-contrib

# Secure PostgreSQL
sudo -u postgres psql

CREATE DATABASE marketplace_prod;
CREATE USER marketplace_user WITH PASSWORD 'strong-password';
GRANT ALL PRIVILEGES ON DATABASE marketplace_prod TO marketplace_user;
\q

# Configure PostgreSQL
sudo nano /etc/postgresql/14/main/postgresql.conf

# Recommended settings:
# max_connections = 100
# shared_buffers = 256MB
# effective_cache_size = 1GB
# maintenance_work_mem = 64MB
# checkpoint_completion_target = 0.9
# wal_buffers = 16MB
# default_statistics_target = 100
# random_page_cost = 1.1
# effective_io_concurrency = 200

sudo systemctl restart postgresql
```

### Run Migrations

```bash
# Backup current database first
pg_dump -h localhost -U marketplace_user marketplace_prod > backup_pre_migration.sql

# Run migrations
cd /home/appuser/app/backend
source venv/bin/activate
alembic upgrade head

# Verify
alembic current
```

## Security Hardening

### Application Security

1. **Strong Secret Keys**:
   ```bash
   # Generate new SECRET_KEY
   openssl rand -base64 32
   ```

2. **Environment Variables**:
   - Never commit `.env` files
   - Use secrets management (AWS Secrets Manager, Vault)

3. **Database Credentials**:
   - Use strong passwords
   - Restrict database access by IP
   - Use SSL connections

4. **CORS Configuration**:
   ```env
   ALLOWED_ORIGINS=https://yourdomain.com  # Exact domain only
   ```

5. **Rate Limiting**:
   - Enable in production
   - Configure per endpoint

### Server Security

```bash
# Firewall rules
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# Disable root SSH login
sudo nano /etc/ssh/sshd_config
# Set: PermitRootLogin no
# Set: PasswordAuthentication no  # Use SSH keys only
sudo systemctl restart sshd

# Automatic security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

### Database Security

```bash
# PostgreSQL authentication
sudo nano /etc/postgresql/14/main/pg_hba.conf

# Use scram-sha-256 authentication
# local   all   all   scram-sha-256
# host    all   all   127.0.0.1/32   scram-sha-256

# SSL connections
# hostssl all   all   0.0.0.0/0   scram-sha-256

sudo systemctl restart postgresql
```

## Monitoring & Logging

### Application Logs

```bash
# View application logs
sudo journalctl -u ecommerce-backend -f

# Or if using Docker
docker-compose -f docker-compose.prod.yml logs -f backend

# Rotate logs
sudo nano /etc/logrotate.d/ecommerce-backend

/home/appuser/app/backend/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 appuser appuser
    sharedscripts
    postrotate
        systemctl reload ecommerce-backend
    endscript
}
```

### Monitoring Stack (Optional)

**Prometheus + Grafana**:

```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    
  grafana:
    image: grafana/grafana
    volumes:
      - grafana_data:/var/lib/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin

volumes:
  prometheus_data:
  grafana_data:
```

## Backup & Recovery

### Database Backups

```bash
# Create backup script
sudo nano /home/appuser/scripts/backup_db.sh

#!/bin/bash
BACKUP_DIR="/home/appuser/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_$DATE.sql"

mkdir -p $BACKUP_DIR

pg_dump -h localhost -U marketplace_user marketplace_prod > $BACKUP_FILE

# Compress
gzip $BACKUP_FILE

# Delete backups older than 30 days
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete

echo "Backup completed: ${BACKUP_FILE}.gz"

# Make executable
chmod +x /home/appuser/scripts/backup_db.sh

# Schedule with cron
crontab -e
# Add: 0 2 * * * /home/appuser/scripts/backup_db.sh >> /home/appuser/logs/backup.log 2>&1
```

### Restore from Backup

```bash
# Stop application
sudo systemctl stop ecommerce-backend

# Restore database
gunzip -c backup_20240115_020000.sql.gz | psql -h localhost -U marketplace_user marketplace_prod

# Start application
sudo systemctl start ecommerce-backend
```

### Offsite Backups

Upload backups to cloud storage:

```bash
# Install AWS CLI
pip install awscli

# Upload to S3
aws s3 sync /home/appuser/backups s3://your-backup-bucket/database-backups/

# Or use rclone for multiple cloud providers
```

## CI/CD Pipeline

### GitHub Actions Example

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]
    tags: ['v*']

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          pip install -r backend/requirements.txt
          pip install -r backend/requirements-dev.txt
      - name: Run tests
        run: |
          cd backend
          pytest --cov=app

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - name: Deploy to production
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.PROD_HOST }}
          username: ${{ secrets.PROD_USER }}
          key: ${{ secrets.PROD_SSH_KEY }}
          script: |
            cd /home/appuser/app/backend
            git pull origin main
            source venv/bin/activate
            pip install -r requirements.txt
            alembic upgrade head
            sudo systemctl restart ecommerce-backend
```

## Troubleshooting

### Application Won't Start

```bash
# Check logs
sudo journalctl -u ecommerce-backend -n 100 --no-pager

# Check database connection
psql -h localhost -U marketplace_user -d marketplace_prod

# Verify environment
source venv/bin/activate
python -c "from app.config import settings; print(settings.DATABASE_URL)"
```

### High Memory Usage

```bash
# Check memory
free -h

# Adjust worker count in systemd service
# Reduce: --workers 2

# Or adjust in docker-compose.yml
# Add: mem_limit: 1g
```

### Slow Queries

```sql
-- Enable slow query logging in PostgreSQL
ALTER SYSTEM SET log_min_duration_statement = 1000;  -- 1 second
SELECT pg_reload_conf();

-- View slow queries
SELECT * FROM pg_stat_statements 
ORDER BY total_exec_time DESC 
LIMIT 10;
```

### SSL Certificate Issues

```bash
# Test certificate
sudo certbot certificates

# Renew manually
sudo certbot renew

# Check Nginx config
sudo nginx -t
```

---

**Last Updated**: December 2025  
**Deployment Version**: 1.0.0

For additional support, see [README.md](README.md) and [DATABASE.md](DATABASE.md).
