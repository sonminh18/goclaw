# goclaw Helm Chart Repository

This is the official Helm chart repository for goclaw.

## Usage

Add this Helm repository:

```bash
helm repo add goclaw https://sonminh18.github.io/goclaw
helm repo update
```

Install goclaw:

```bash
helm install goclaw goclaw/goclaw --version $VERSION
```

## Available Charts

- **goclaw** - $VERSION

## OCI Registry (Alternative)

You can also install directly from OCI registries:

### GitHub Container Registry

```bash
helm install goclaw oci://ghcr.io/sonminh18/helm/goclaw --version VERSION
```
