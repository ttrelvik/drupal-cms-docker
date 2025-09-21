# Drupal CMS Docker Image

This project builds a **production-ready, CI/CD-friendly Docker image** for the Drupal CMS distribution.

This ensures a consistent, reproducible artifact that isn't dependent on local files, making it ideal for automated build pipelines.

---

## ✅ The final image contains:

- **PHP 8.3-FPM**
- **Nginx**
- **Composer**
- **Drupal CMS**
- **Additional Drupal Modules**

---

## 🚀 How to Use

This project uses **Docker Compose** to build the image and run the necessary containers for a complete local environment.

### **Prerequisites**

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/)

---

### **1. Build and Run the Containers**

From the root of this project directory, run the following command (modern CLI):

```bash
docker compose up -d --build
```

**Flags explained:**
- `--build`: Builds the image from the Dockerfile. Use this again if you modify the Dockerfile.
- `-d`: Runs the containers in detached mode (in the background).

This command will:

- Build the **`drupal-cms-local:latest`** image using the instructions in the Dockerfile.
- Start a **Drupal container** using the newly built image.
- Start a **Postgres container** for the database.
- Create **persistent Docker volumes** for the database and Drupal files.

---

### **2. Complete the Drupal Installation**

Once the containers are running, you can complete the installation through your web browser:

- Open [http://localhost:8080](http://localhost:8080).
- Follow the Drupal installation prompts.
When you reach the **Database configuration** screen, use the values in your `.env` (copy `.env.example` to `.env` first):

```text
Database type: PostgreSQL
Database name: <value of POSTGRES_DB in .env> (default: drupal)
Database username: <value of POSTGRES_USER in .env> (default: drupal)
Database password: <value of POSTGRES_PASSWORD in .env>
Advanced options > Host: db
```

Note: `docker-compose.yml` maps the canonical `POSTGRES_*` variables from `.env` into the Drupal container as `DB_*` (so define the canonical values once in `.env`).

After completing the final step, you will have a **fully functional Drupal CMS site running locally**.

---

## 🔧 Customization

You can easily customize this project to fit your needs by editing the `Dockerfile`.

---

### **Adding/Removing Modules**

The primary customization is adding or removing contributed modules. This is done in the **builder stage** of the Dockerfile.

Find this section in the `Dockerfile`:

```dockerfile
# After the project is created, add any additional modules you need.
RUN composer require \
    'drupal/samlauth:^3.11' \
    'drush/drush:^13.6'
```

You can **add, remove, or change versions** of packages in this `RUN` command.  
After making changes, rebuild your image:

```bash
docker compose up -d --build
```

---

### **PHP Extensions & System Packages**

If your modules require additional dependencies:

- **System Packages** (e.g., `git`, `wget`) → Add to `apt-get install` in **both** `builder` and `drupal_app_base` stages.
- **PHP Extensions** → Add to the `docker-php-ext-install` commands in **both** stages.
