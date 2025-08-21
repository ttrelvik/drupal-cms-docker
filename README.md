# Drupal CMS Dockerized

This repository provides a complete, containerized environment for running **Drupal CMS**. It simplifies local development and provides a solid foundation for container-based deployments.

The setup uses Docker Compose to orchestrate a multi-container environment featuring an Nginx web server, PHP-FPM, and a PostgreSQL database. The resulting Docker image is multi-platform, supporting both `amd64` (Intel/AMD) and `arm64` (Apple Silicon) architectures.

---
## Tech Stack

* **Drupal CMS**: The latest version pulled by Composer.
* **Web Server**: Nginx
* **PHP**: 8.3-FPM
* **Database**: PostgreSQL 16

---
## Quick Start

### Prerequisites

* [Docker](https://docs.docker.com/get-docker/)
* [Docker Compose](https://docs.docker.com/compose/install/)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/ttrelvik/drupal-cms-docker.git
    cd drupal-cms-docker
    ```

2.  **Build and run the containers:**
    For the first run, use the `--build` flag to build the custom Drupal image.
    ```bash
    docker-compose up --build -d
    ```
    To simply start the containers on subsequent runs, you can omit the `--build` flag:
    ```bash
    docker-compose up -d
    ```

3.  **Launch the Drupal Installer:**
    Open your web browser and navigate to **[http://localhost:8080](http://localhost:8080)**.

4.  **Configure the Database:**
    When you reach the "Database configuration" step of the Drupal installer, use the following credentials:
    * **Database type**: `PostgreSQL`
    * **Database name**: `drupal`
    * **Database username**: `drupal`
    * **Database password**: `drupal`
    * **Host** (under "Advanced options"): `db`
    * **Port** (under "Advanced options"): `5432`

Obviously replace those with something more secure when deploying.

Complete the rest of the installation steps to get your site up and running.

---
## Project Structure

* `Dockerfile`: The blueprint for building the custom Drupal CMS image. It installs PHP, Nginx, Composer, and all necessary extensions.
* `docker-compose.yml`: Defines and orchestrates the application (`drupal_cms`) and database (`db`) services.
* `.docker/`: Contains supporting configuration files.
    * `nginx/default.conf`: Nginx virtual host configuration.
    * `entrypoint.sh`: A script that starts PHP-FPM and Nginx when the container launches.
* `.gitignore`: Specifies files and directories to be excluded from version control.