<!-- Short, focused guidance for AI coding agents working on this repository -->
# Copilot instructions — drupal-cms-docker

This repository builds a single Docker image containing a production-ready Drupal CMS (PHP-FPM + Nginx) and runs it together with Postgres via Docker Compose. Keep instructions concise and reference the files below when making changes.

Key files to read first:
- `Dockerfile` — multi-stage build (stages: `builder`, `drupal_app_base`, `final`). Composer runs in `builder` (see `composer create-project` and `composer require` lines).
- `docker-compose.yml` — defines two services: `drupal_cms` (built from this repo, image `drupal-cms-local:latest`) and `db` (Postgres 16). Volume mappings and env vars live here.
- `.docker/entrypoint.sh` — starts `php-fpm` and `nginx`, symlinks Nginx logs to stdout/stderr.
- `.docker/nginx/default.conf` — Nginx config (root `/app/web`, `fastcgi_pass 127.0.0.1:9000`).

Big-picture architecture (what to expect):
- Single container runs both PHP-FPM and Nginx (started by `entrypoint.sh`). Nginx communicates with PHP-FPM over 127.0.0.1:9000 as configured in `default.conf`.
- The image is produced by a multi-stage Dockerfile: the `builder` stage runs Composer and installs modules; `drupal_app_base` installs system packages & PHP extensions; `final` copies the built app and runtime config.
- Persistent data: `docker-compose.yml` exposes two volumes: `postgres_data` (Postgres DB data) and `drupal_sites_default` mounted at `/app/web/sites/default`.

Developer workflows (explicit commands & examples):
- Build and run locally (from repo root) using the modern Docker CLI:
```bash
docker compose up -d --build
```
- View container logs (Nginx and PHP logs are forwarded):
```bash
docker compose logs -f drupal_cms
```
- Run a shell in the running web container (image may not have bash; use `sh`):
```bash
docker compose exec drupal_cms sh
```
- Drush is installed via Composer (`drush/drush`) and available in the image `PATH` (`/app/vendor/bin`). Example (from host):
```bash
docker compose exec drupal_cms vendor/bin/drush status
```

Project-specific conventions and gotchas (do not assume defaults):
- To add contributed modules or change Drupal core version: edit the `RUN composer require ...` line in the `builder` stage of `Dockerfile`, then rebuild with `docker compose up -d --build`.
- If you need system packages or PHP extensions for modules, update both the `builder` and `drupal_app_base` stages (`apt-get install` and `docker-php-ext-install`) so build-time and runtime environments match.
- The `docker-compose` service `drupal_cms` mounts `drupal_sites_default` at `/app/web/sites/default`. A freshly mounted, empty volume will hide files baked into the image. Inspect the directory before installing, e.g. `docker compose exec drupal_cms sh -c "ls -la /app/web/sites/default"`.
- Nginx expects PHP-FPM at `127.0.0.1:9000` (see `.docker/nginx/default.conf`). Any change to how PHP-FPM listens must be coordinated with this file or with the entrypoint.
  - The entrypoint uses `php-fpm -D` (note the command name) and symlinks Nginx logs to stdout/stderr — prefer `docker compose logs` for quick debugging.

Integration points & concrete values:
-- Postgres connection (used during Drupal install):
  - Host: `db`
  - Database: value of `POSTGRES_DB` in `.env` (default: `drupal`)
  - User: value of `POSTGRES_USER` in `.env` (default: `drupal`)
  - Password: value of `POSTGRES_PASSWORD` in `.env`
  (Define canonical `POSTGRES_*` variables once in `.env` or copy from `.env.example`; `docker-compose.yml` maps them into the Drupal container as `DB_*`.)

When editing code or containers, prefer the smallest, verifiable change:
- If you change the Dockerfile, rebuild with `docker compose up -d --build`. Then confirm the site at `http://localhost:8080` and check `docker compose logs`.
- If adding packages, update both build/runtime stages and run a full rebuild.

What is not present / not discoverable here:
- There are no CI config files or automated tests in this repo. If you see references to CI in other notes, verify by searching for `.github/workflows` or similar.

If anything in these files looks ambiguous (e.g., PHP-FPM listen mode, first-run population of `sites/default`), ask for clarification or reproduce the environment locally with `docker compose up -d --build` and inspect paths listed above.

Examples (quick edits):
- Add a PHP extension: edit both stages in `Dockerfile` and add the `docker-php-ext-install` line in each. Rebuild.
- Add a module: edit `Dockerfile` builder `RUN composer require 'drupal/example'` and rebuild.

Questions for the maintainer (if unclear):
- Should the `sites/default` volume be pre-populated on first-run? If yes, provide the preferred seeding step.
- Are there intended CI or release pipelines that expect specific image tags beyond `drupal-cms-local:latest`?

End of guidance — ask for clarification if anything above is out of date.
