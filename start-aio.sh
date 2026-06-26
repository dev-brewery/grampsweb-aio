#!/bin/sh
set -e

# Gramps Web All-in-One entrypoint
# Starts Redis + Gramps Web API + Celery worker via supervisord

# Create Redis persistence directory on the dedicated /app/persist volume
# (replaces the old /tmp/redis path — see Dockerfile redis.conf)
mkdir -p /app/persist/redis

# Set default gunicorn values (AIO-specific)
export GUNICORN_NUM_WORKERS=${GUNICORN_NUM_WORKERS:-4}
export GUNICORN_TIMEOUT=${GUNICORN_TIMEOUT:-120}

# Set default tree name
export GRAMPSWEB_TREE=${GRAMPSWEB_TREE:-"Gramps Web"}

# Generate + persist a Flask secret key if one wasn't supplied, and EXPORT it so
# the supervisord-managed gunicorn/celery processes inherit it.
# NOTE: we must do this in THIS shell — delegating to `/docker-entrypoint.sh true`
# generated the key in a subshell, so the export never reached supervisord and the
# workers crash-looped with "SECRET_KEY must be specified".
if [ -z "$GRAMPSWEB_SECRET_KEY" ]; then
    if [ ! -s /app/secret/secret ]; then
        mkdir -p /app/secret
        python3 -c "import secrets; print(secrets.token_urlsafe(32))" | tr -d '\n' > /app/secret/secret
    fi
    GRAMPSWEB_SECRET_KEY="$(cat /app/secret/secret)"
    export GRAMPSWEB_SECRET_KEY
fi

# Run user database migrations (non-fatal for Unraid resilience)
cd /app/src/ 2>/dev/null && python3 -m gramps_webapi --config /app/config/config.cfg user migrate || true
cd /app/

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/grampsweb.conf
