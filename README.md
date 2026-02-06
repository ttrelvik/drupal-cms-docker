# Drupal Docker Project

This project builds a **production-ready, CI/CD-friendly Docker image** for Tom Trelvik's Drupal portfolio site. It is designed to run in a **Docker Swarm** environment with **Traefik** as the ingress controller.

## ✅ Architecture

- **Base Image**: `drupal/recommended-project` (via `php:8.3-fpm-bookworm`)
- **Web Server**: Nginx (bundled in the same image for simplicity)
- **Database**: PostgreSQL with `pgvector` extension (for AI embeddings)
- **Orchestration**: Docker Swarm
- **Ingress**: Traefik (with Let's Encrypt TLS)

## 🚀 Images

The project builds the following image:
- `ttrelvik/drupal-core:alpha3` (Current production tag)

This image follows a **Configuration-as-Code** strategy:
- The `config/` directory (exported from active configuration) is **burned into the image** at build time.
- `settings.local.php` is also burned in to handle environment-specific logic (secrets, Trusted Host settings).

---

## 🛠️ Usage & Workflows

### 1. Prerequisites
- Docker & Docker Compose
- Docker Swarm (initialized via `docker swarm init`)
- [Traefik](https://doc.traefik.io/traefik/) running on the swarm (connected to external network `traefik-net`)

### 2. Environment Setup
The project uses distinct environment files for Production vs. Development:
- **Production**: `.env` (References `blog.trelvik.net`, external secrets)
- **Development**: `dev.env` (References `dev-blog.trelvik.net`, development secrets)

### 3. Deploying (Production)
```bash
# 1. Create Secrets (if not existing)
docker secret create drupal_postgres_password ./secret_file
docker secret create gemini_api_key ./key_file
docker secret create openai_api_key ./key_file

# 2. Deploy Stack
docker stack deploy -c docker-compose.yml drupal
```
*Access:* `https://blog.trelvik.net`

### 4. Deploying (Development)
The development stack runs isolated from production but mirrors its architecture.
```bash
# 1. Create Dev Secrets
docker secret create drupal-dev_postgres_password ./dev_secret_file
# (API keys can be shared or separate)

# 2. Deploy Dev Stack
docker stack deploy -c docker-compose.dev.yml drupal-dev
```
*Access:* `https://dev-blog.trelvik.net`

---

## 📦 Backup & Restore

The project includes scripts to manage data persistence and environment synchronization.

### `backup.sh` (Production Backup)
Creates a full backup of the **Production** site (database + file assets).
- Puts site in Maintenance Mode.
- Dumps PostgreSQL database (including vectors).
- Archives `web/sites/default/files`.
- Saves tarball to host `backups/` directory.
```bash
./backup.sh
```

### `restore.sh` (Restore to Any Stack)
Restores a backup tarball to a specified stack (e.g., refreshing Dev with Prod data).
- automatically finds the latest backup.
- **Drops and Re-creates** the database.
- Restores file assets.
- Runs database updates (`drush updb`).
```bash
# Restore latest prod backup to the DEV stack
./restore.sh drupal-dev
```

### `deploy.sh` (Deployment & AI Initialization)
**CRITICAL**: This script must be run inside the Drupal container after a fresh deployment. It handles logic that cannot be static in the image.

**What it does:**
1.  **Config Import**: Syncs the database with the `config/` directory.
2.  **AI Domain Patching**: Updates the AI Assistant's system prompt to use the correct domain (e.g., changing `dev-blog` -> `blog`) so that cited links work for the user.
3.  **RAG Indexing**: Triggers `drush search-api:index` to generate vector embeddings for your content. Without this, the AI cannot "read" your blog posts.

**When to run it:**
- Immediately after checking out/deploying a new stack.
- After importing a database backup (to re-sync config).
- When you notice the AI is unaware of new content.

```bash
docker exec -it [container_id] /app/deploy.sh
```

---

## 🔧 Customization

### Adding Modules
1.  Edit `Dockerfile` (Builder Stage).
2.  Add packages to the `composer require` command.
3.  Rebuild image: `docker build -t ttrelvik/drupal-core:tag .`

### Updating Configuration
1.  Make changes in the running Dev container (GUI or Drush).
2.  Export config to host:
    ```bash
    docker exec [dev_container_id] drush cex -y
    # (Then copy files from container /tmp to local config/ dir if not mounted)
    ```
    *Note: We typically commit the `config/` directory to git.*
3.  Rebuild image to include new config.
