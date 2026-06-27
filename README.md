# Gramps Web AIO (All-In-One)

A single-container build of [Gramps Web](https://www.grampsweb.org/) — the free, open-source
genealogy platform — that bundles every service into **one** container via `supervisord`:

- **Gramps Web API** (Flask/Gunicorn backend)
- **Gramps Web frontend** (static SPA)
- **Celery worker** (background tasks: imports, exports, search indexing)
- **Redis** (Celery broker/result backend + rate-limit store)

No external containers or compose stack required — ideal for Unraid and other single-container
hosts. Images are multi-arch (`linux/amd64`, `linux/arm64`).

## Why AIO?

The official Gramps Web deployment is three containers (web, celery, redis) wired together with
Docker Compose. Many Unraid users prefer one container per app. This image runs all three
processes inside a single container under `supervisord`, matching the Unraid Community
Applications model. (The classic 3-container reference still lives in [`examples/`](examples/).)

## Quick start (Docker)

```bash
docker run -d \
  --name=grampsweb-aio \
  -p 5050:5000 \
  -v /mnt/user/appdata/grampsweb-aio/users:/app/users \
  -v /mnt/user/appdata/grampsweb-aio/grampsdb:/root/.gramps/grampsdb \
  -v /mnt/user/appdata/grampsweb-aio/media:/app/media \
  -v /mnt/user/appdata/grampsweb-aio/indexdir:/app/indexdir \
  -v /mnt/user/appdata/grampsweb-aio/thumbnail_cache:/app/thumbnail_cache \
  -v /mnt/user/appdata/grampsweb-aio/cache:/app/cache \
  -v /mnt/user/appdata/grampsweb-aio/secret:/app/secret \
  -v /mnt/user/appdata/grampsweb-aio/persist:/app/persist \
  -e GRAMPSWEB_TREE="Gramps Web" \
  --restart=always \
  devbrewery/grampsweb-aio:latest
```

Open `http://YOUR_HOST:5050` and complete the setup wizard (create the admin account, import a
tree). Images:

- Docker Hub: `devbrewery/grampsweb-aio:latest`
- GHCR (mirror): `ghcr.io/dev-brewery/grampsweb-aio:latest`

A single-container `docker-compose.yml` is also included.

## Volumes

| Container path           | Holds | Notes |
|--------------------------|-------|-------|
| `/root/.gramps/grampsdb` | The family tree database | **Your data** — back this up |
| `/app/users`             | User accounts | logins, roles |
| `/app/media`             | Media files | photos, documents, scans |
| `/app/indexdir`          | Full-text search index | rebuilt if deleted |
| `/app/thumbnail_cache`   | Media thumbnails | regenerable |
| `/app/cache`             | Export/report cache | regenerable |
| `/app/secret`            | Flask secret key | auto-generated on first run, reused after |
| `/app/persist`           | App state **+ Redis** | Redis persists to `/app/persist/redis` |

There is **no `/tmp` mount** — Redis persistence was moved onto the dedicated `persist` volume
so it survives restarts without a slow host `/tmp` bind.

## Configuration

| Variable               | Default      | Description |
|------------------------|--------------|-------------|
| `GRAMPSWEB_TREE`       | `Gramps Web` | Tree/database name (created on first run). |
| `GUNICORN_NUM_WORKERS` | `4`          | API worker processes. |
| `GUNICORN_TIMEOUT`     | `120`        | API request timeout (seconds). |
| `GRAMPSWEB_SECRET_KEY` | _(auto)_     | Flask session key. Leave unset to auto-generate into `/app/secret`. |
| `GRAMPSWEB_BASE_URL`   | _(unset)_    | Set to your external URL when behind a reverse proxy, e.g. `https://tree.example.com`. |

## Install on Unraid

1. Copy `grampsweb-aio.xml` into `/boot/config/plugins/dockerMan/templates-user/` on the Unraid
   flash share.
2. **Docker** tab → **Add Container** → choose `grampsweb-aio` from the **Template:** dropdown.
3. Adjust the appdata paths/port if needed, then **Apply**.

### Behind a reverse proxy

Set `GRAMPSWEB_BASE_URL` to your external `https://...` URL, and point the proxy's upstream at
the **Unraid host IP and the published port** (e.g. `http://192.168.x.x:5050`) — not the
container name, unless the proxy shares a custom Docker network with this container (otherwise
you'll get `502 Bad Gateway`).

## Updating Gramps Web

The base image is pinned in the `Dockerfile` (`FROM ghcr.io/gramps-project/grampsweb:<version>`).
To bump it: check the [Gramps Web releases](https://github.com/gramps-project/gramps-web/releases),
update the pinned tag, rebuild, and test before publishing.

## Files

| File | Purpose |
|------|---------|
| `Dockerfile`         | Builds the AIO image on the pinned official Gramps Web base |
| `start-aio.sh`       | Entrypoint: generates the secret key, runs migrations, starts supervisord |
| `supervisord.conf`   | Runs Redis + Gunicorn (API) + Celery |
| `grampsweb-aio.xml`  | Unraid Community Applications template |
| `examples/`          | The classic 3-container (web + celery + redis) reference |

## Credits

[Gramps Project](https://gramps-project.org) — all the actual genealogy software. This repo just
packages it as a single container for convenience.
