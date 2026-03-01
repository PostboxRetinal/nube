# Mini Store — Microservices - Parcial 1C
## Desarrollado por Juan Eduardo Jaramillo y Sebastian Balanta

Flask-based store management app with Users, Products, and Orders microservices orchestrated via Docker Compose and Consul service discovery.

## Requirements

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Run

```bash
cd webApp
docker compose up --build
```

| Service  | URL                        |
|----------|----------------------------|
| Frontend | http://localhost:5001       |
| Users    | http://localhost:5002/api/users    |
| Products | http://localhost:5003/api/products |
| Orders   | http://localhost:5004/api/orders   |
| Consul   | http://localhost:8500       |

## Stop

```bash
docker compose down
```

To also wipe the database volumes:

```bash
docker compose down -v
```
