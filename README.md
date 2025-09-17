# Unbound DNS Docker Image

[![Build and Push on Unbound Release](https://github.com/rafaelperoco/unbound/actions/workflows/build-on-release.yml/badge.svg)](https://github.com/rafaelperoco/unbound/actions/workflows/build-on-release.yml)
[![Docker Build](https://github.com/rafaelperoco/unbound/actions/workflows/docker-build.yml/badge.svg)](https://github.com/rafaelperoco/unbound/actions/workflows/docker-build.yml)

Automated Docker builds for [Unbound DNS](https://github.com/NLnetLabs/unbound) resolver, compiled from source with full feature support.

## Features

- 🚀 **Automated Builds**: Automatically builds new images when Unbound releases new versions
- 🏗️ **Multi-stage Build**: Compiled from source for minimal final image size
- 🔄 **Multi-architecture**: Supports both `linux/amd64` and `linux/arm64`
- 🔒 **Security**: DNSSEC validation enabled by default
- 📊 **Full Features**: DNSTap, CacheDB, Subnet support enabled
- 📦 **GitHub Container Registry**: Images hosted on GHCR

## Quick Start

### Using Docker

```bash
# Pull the latest image
docker pull ghcr.io/rafaelperoco/unbound:latest

# Run Unbound
docker run -d \
  --name unbound \
  -p 53:53/tcp \
  -p 53:53/udp \
  ghcr.io/rafaelperoco/unbound:latest
```

### Using Docker Compose

```bash
# Clone the repository
git clone https://github.com/rafaelperoco/unbound.git
cd unbound

# Create config directory
mkdir -p config

# Start Unbound
docker-compose up -d
```

## Configuration

### Custom Configuration

Place your custom configuration files in the `config/` directory. They will be included automatically.

Example `config/custom.conf`:
```conf
server:
    # Custom upstream forwarders
    forward-zone:
        name: "."
        forward-addr: 1.1.1.1@853#cloudflare-dns.com
        forward-addr: 1.0.0.1@853#cloudflare-dns.com
        forward-tls-upstream: yes
```

### Environment Variables

The image uses these defaults which can be overridden:

- `TZ`: Timezone (default: `America/Sao_Paulo`)

## Available Tags

- `latest`: Latest stable release
- `release-X.Y.Z`: Specific Unbound release version
- `dev`: Latest development build from main branch
- `main-YYYYMMDD-SHA`: Specific builds from main branch

## Build Schedule

The image is automatically rebuilt:
- Every 6 hours to check for new Unbound releases
- On every push to the main branch
- On manual workflow dispatch

## Architecture Support

Images are built for multiple architectures:
- `linux/amd64` (x86_64)
- `linux/arm64` (ARM 64-bit)

## Security Features

- DNSSEC validation enabled by default
- Runs as non-root user (`unbound`)
- Minimal base image (Debian slim)
- Root hints automatically updated during build
- Health checks configured

## Volumes

- `/etc/unbound/conf.d`: Custom configuration files
- `/var/lib/unbound`: Unbound data directory

## Exposed Ports

- `53/tcp`: DNS over TCP
- `53/udp`: DNS over UDP

## Health Check

The container includes a health check that runs:
```bash
unbound-control status
```

## Building Locally

```bash
# Build the image
docker-compose build

# Or using Docker directly
docker build -t unbound:local .
```

## GitHub Actions Workflows

### `build-on-release.yml`
- Monitors Unbound repository for new releases
- Automatically builds and pushes images when new releases are detected
- Runs every 6 hours via cron schedule

### `docker-build.yml`
- Builds on push to main branch
- Builds on pull requests for testing
- Manual trigger available

## Contributing

Pull requests are welcome! Please ensure:
1. Docker build passes
2. Multi-architecture support is maintained
3. Security best practices are followed

## License

This Docker image build configuration is open source. Unbound itself is licensed under the BSD license.

## Links

- [Unbound Official Repository](https://github.com/NLnetLabs/unbound)
- [Unbound Documentation](https://unbound.docs.nlnetlabs.nl/)
- [Container Image](https://github.com/rafaelperoco/unbound/pkgs/container/unbound)