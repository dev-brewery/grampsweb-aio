# Gramps Web AIO (All-In-One) for Unraid

A single-container deployment of [Gramps Web](https://github.com/gramps-project/gramps-web) that bundles:
- **Gramps Web API** (Flask/Gunicorn backend)
- **Gramps Web Frontend** (static SPA)
- **Celery worker** (background task processing)
- **Redis** (Celery broker + result backend + rate limiting)

No external containers needed. Designed for [Unraid Community Applications](https://unraid.net/community/apps).

## Why AIO?

The official Gramps Web deployment uses 3 separate containers (web, celery, redis) via Docker Compose. Many Unraid users prefer single-container deployments. This AIO image uses `supervisord` to run all three processes inside one container, matching the Unraid CA model.

## Usage

### Docker Run
```bash
docker run -d \
  --name=grampsweb-aio \
  -p 5050:5000 \
  -v /mnt/user/appdata/grampsweb-aio/users:/app/users \
  -v /mnt/user/appdata/grampsweb-aio/grampsdb:/root/.gramps/grampsdb \
  -v /mnt/user/appdata/grampsweb-aio/media:/app/media \
  -v /mnt/user/appdata/grampsweb-aio/secret:/app/secret \
  -v /mnt/user/appdata/grampsweb-aio/indexdir:/app/indexdir \
  -v /mnt/user/appdata/grampsweb-aio/thumbnail_cache:/app/thumbnail_cache \
  -v /mnt/user/appdata/grampsweb-aio/cache:/app/cache \
  -v /mnt/user/appdata/grampsweb-aio/persist:/app/persist \
  -e GRAMPSWEB_TREE="Gramps Web" \
  --restart=always \
  devbrewery/grampsweb-aio:latest
```

> Redis persists to `/app/persist/redis` (inside the `persist` mount) — there is no
> separate `/tmp` mount. The Flask secret key is auto-generated into the `secret`
> mount on first run and reused on restart.

Images are published to both registries:
- Docker Hub: `devbrewery/grampsweb-aio:latest`
- GHCR (mirror): `ghcr.io/dev-brewery/grampsweb-aio:latest`

### Unraid
> **Note:** Unraid manages container restart policies automatically.
> The `--restart=always` flag is only needed for standalone Docker deployments.

1. Install from Community Applications (search "grampsweb")
2. Set your appdata paths
3. Click apply, navigate to `http://<unraid-ip>:5050`
4. Complete the setup wizard

## Building

```bash
docker build -t grampsweb-aio .
docker push ghcr.io/dev-brewery/grampsweb-aio:latest
```

## Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Builds AIO image on top of official `ghcr.io/gramps-project/grampsweb` (pinned) |
| `supervisord.conf` | Process manager config (Redis + Gunicorn + Celery) |
| `start-aio.sh` | Entrypoint script (runs migrations, starts supervisord) |
| `grampsweb-aio.xml` | Unraid CA template |

## Credits

- [Gramps Project](https://gramps-project.org) — all the actual software
- This repo just packages it for Unraid convenience
