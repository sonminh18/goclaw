# GoClaw Helm Chart

Production-ready Helm chart for deploying GoClaw — a PostgreSQL multi-tenant AI agent gateway.

## Prerequisites

- Kubernetes 1.26+
- Helm 3.10+
- PostgreSQL with pgvector extension (external or in-cluster)

## Installation

```bash
# Add dependencies
helm dependency build

# Install with external PostgreSQL (recommended for production)
helm install goclaw . \
  --set externalDatabase.dsn="postgres://user:pass@host:5432/dbname?sslmode=require" \
  --set gateway.encryptionKey="$(openssl rand -base64 32)"

# Or with in-cluster pgvector
helm install goclaw . \
  --set externalDatabase.enabled=false \
  --set pgvector.enabled=true \
  --set pgvector.auth.password="your-password" \
  --set gateway.encryptionKey="$(openssl rand -base64 32)"
```

## Bitnami container images (Redis / PostgreSQL subcharts)

Many `docker.io/bitnami/*` tags were removed from Docker Hub. This chart defaults Redis and optional PostgreSQL to **`docker.io/bitnamilegacy/*`** with `global.security.allowInsecureImages: true`, matching the Bitnami chart’s pinned versions. If pulls still fail, bump `redis.image.tag` / `postgresql.image.tag` to a tag that exists on Docker Hub for `bitnamilegacy/redis` or `bitnamilegacy/postgresql`.

## Database Options

### Option 1: External PostgreSQL (Recommended)

Use a managed PostgreSQL service with pgvector enabled:
- AWS RDS PostgreSQL with pgvector
- Google Cloud SQL with pgvector
- Azure Database for PostgreSQL Flexible Server
- Neon, Supabase, or similar

```yaml
externalDatabase:
  enabled: true
  dsn: "postgres://user:pass@host:5432/dbname?sslmode=require"
  # Or use existing secret:
  # existingSecret: "my-postgres-secret"
```

### Option 2: In-cluster pgvector StatefulSet

Deploy pgvector/pgvector:pg18 directly (closest to docker-compose):

```yaml
externalDatabase:
  enabled: false
pgvector:
  enabled: true
  auth:
    password: "secure-password"
  persistence:
    size: 50Gi
```

### Option 3: Bitnami PostgreSQL with Custom Image

Use Bitnami chart for operability but with a pgvector-enabled image:

```yaml
externalDatabase:
  enabled: false
postgresql:
  enabled: true
  image:
    registry: your-registry
    repository: postgresql-pgvector
    tag: "18"
  auth:
    password: "secure-password"
```

Build the custom image with:

```dockerfile
FROM pgvector/pgvector:pg18 AS builder
FROM bitnami/postgresql:18
COPY --from=builder /usr/lib/postgresql/18/lib/vector.so /opt/bitnami/postgresql/lib/
COPY --from=builder /usr/share/postgresql/18/extension/vector* /opt/bitnami/postgresql/share/extension/
```

## Configuration

### Gateway

| Parameter | Description | Default |
|-----------|-------------|---------|
| `gateway.token` | Authentication token for API access | `""` |
| `gateway.encryptionKey` | AES-256-GCM key for encrypting API keys in DB | `""` |
| `gateway.ownerIds` | Comma-separated owner user IDs | `""` |

### Redis (Optional)

Enable Redis caching layer (requires gateway image with `-tags redis`):

```yaml
redis:
  enabled: true
  auth:
    password: "redis-password"
```

### Browser Automation

Enable Chrome CDP sidecar:

```yaml
chrome:
  enabled: true
  resources:
    limits:
      memory: 2Gi
```

### Telemetry

Enable OpenTelemetry tracing (requires gateway image with `-tags otel`):

```yaml
telemetry:
  enabled: true
  endpoint: "jaeger:4317"
  jaeger:
    enabled: true  # Deploy Jaeger all-in-one
```

### Tailscale

Enable secure remote access (requires gateway image with `-tags tsnet`):

```yaml
tailscale:
  enabled: true
  hostname: "goclaw-gateway"
  authKey: "tskey-..."
```

### Ingress

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/proxy-read-timeout: "86400"
  hosts:
    - host: goclaw.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: goclaw-tls
      hosts:
        - goclaw.example.com
```

## Image Tags

The chart uses pre-built images from `ghcr.io/nextlevelbuilder/goclaw`. For optional features, ensure your image includes the appropriate build tags:

| Feature | Build Tag | Image Example |
|---------|-----------|---------------|
| Redis caching | `-tags redis` | `goclaw:latest-redis` |
| OpenTelemetry | `-tags otel` | `goclaw:latest-otel` |
| Tailscale | `-tags tsnet` | `goclaw:latest-tsnet` |
| All features | `-tags redis,otel,tsnet` | `goclaw:latest-full` |

## Sandbox

Docker socket mounting is not supported in Kubernetes for security reasons. The sandbox is disabled by default. For agent code execution in production, consider:

- Sysbox runtime on dedicated nodes
- Kata Containers
- Remote sandbox service
- Firecracker microVMs

## Upgrading

The chart includes a pre-install/pre-upgrade Job that runs database migrations automatically.

```bash
helm upgrade goclaw . --reuse-values
```

## Uninstalling

```bash
helm uninstall goclaw
# PVCs are not deleted automatically
kubectl delete pvc -l app.kubernetes.io/instance=goclaw
```
