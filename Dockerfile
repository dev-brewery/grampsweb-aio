# Gramps Web All-in-One Container for Unraid
# Bundles: Gramps Web (frontend+API) + Celery worker + Redis
# Single container, no external dependencies

# Pinned to Gramps Web v26.6.1 (2026-06-20) — latest stable as of pin date
# Update: check https://github.com/gramps-project/gramps-web/releases, test before bumping
FROM ghcr.io/gramps-project/grampsweb:26.6.1

USER root

# Install Redis and supervisord
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        redis-server \
        supervisor && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create supervisord config
RUN mkdir -p /var/log/supervisor /var/run/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/grampsweb.conf
COPY start-aio.sh /start-aio.sh
RUN chmod +x /start-aio.sh

# Redis config: bind localhost, persist to the dedicated /app/persist volume
# (NOT /tmp — that host mount was slow/collision-prone on the Unraid array)
RUN sed -i 's/^bind .*/bind 127.0.0.1/' /etc/redis/redis.conf && \
    sed -i 's|^dir .*|dir /app/persist/redis|' /etc/redis/redis.conf && \
    sed -i 's/^daemonize yes/daemonize no/' /etc/redis/redis.conf

# Health check — verify Gramps Web API is responding
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/')" || exit 1

EXPOSE 5000

ENTRYPOINT ["/start-aio.sh"]
