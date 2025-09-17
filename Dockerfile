# Build stage
FROM debian:bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    flex \
    bison \
    libssl-dev \
    libexpat1-dev \
    libevent-dev \
    libnghttp2-dev \
    libprotobuf-c-dev \
    protobuf-c-compiler \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone Unbound repository
WORKDIR /build
RUN git clone --depth 1 https://github.com/NLnetLabs/unbound.git

# Build Unbound
WORKDIR /build/unbound
RUN ./configure \
    --prefix=/usr/local \
    --sysconfdir=/etc/unbound \
    --disable-static \
    --enable-dnstap \
    --enable-cachedb \
    --enable-subnet \
    --with-libevent \
    --with-libnghttp2 \
    --with-pthreads \
    --with-ssl \
    && make -j$(nproc) \
    && make install DESTDIR=/install

# Final stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl3 \
    libexpat1 \
    libevent-2.1-7 \
    libnghttp2-14 \
    libprotobuf-c1 \
    ca-certificates \
    dns-root-data \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy Unbound binaries and libraries from builder
COPY --from=builder /install/usr/local /usr/local
COPY --from=builder /install/etc/unbound /etc/unbound

# Create unbound user and group
RUN groupadd -r unbound && useradd -r -g unbound -d /etc/unbound -s /sbin/nologin unbound

# Create necessary directories
RUN mkdir -p /etc/unbound/conf.d /var/lib/unbound && \
    chown -R unbound:unbound /etc/unbound /var/lib/unbound

# Download root hints
RUN wget -O /etc/unbound/root.hints https://www.internic.net/domain/named.cache && \
    chown unbound:unbound /etc/unbound/root.hints

# Create basic configuration
RUN cat > /etc/unbound/unbound.conf << EOF
server:
    # Network interface configuration
    interface: 0.0.0.0
    interface: ::0
    port: 53

    # Access control
    access-control: 0.0.0.0/0 refuse
    access-control: 127.0.0.0/8 allow
    access-control: 10.0.0.0/8 allow
    access-control: 172.16.0.0/12 allow
    access-control: 192.168.0.0/16 allow
    access-control: ::1 allow
    access-control: ::ffff:127.0.0.1 allow

    # Performance settings
    num-threads: 1
    msg-cache-slabs: 2
    rrset-cache-slabs: 2
    infra-cache-slabs: 2
    key-cache-slabs: 2

    # Cache sizes
    rrset-cache-size: 256m
    msg-cache-size: 128m

    # Security settings
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    harden-referral-path: yes

    # DNSSEC
    auto-trust-anchor-file: "/var/lib/unbound/root.key"
    root-hints: "/etc/unbound/root.hints"

    # Logging
    verbosity: 1
    logfile: ""

    # Run as unbound user
    username: "unbound"
    directory: "/etc/unbound"
    chroot: ""

    # Include additional configuration
    include: "/etc/unbound/conf.d/*.conf"
EOF

# Set ownership
RUN chown unbound:unbound /etc/unbound/unbound.conf

# Expose DNS ports
EXPOSE 53/tcp
EXPOSE 53/udp

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD /usr/local/sbin/unbound-control status || exit 1

# Run as unbound user
USER unbound

# Set entrypoint
ENTRYPOINT ["/usr/local/sbin/unbound"]
CMD ["-d", "-c", "/etc/unbound/unbound.conf"]