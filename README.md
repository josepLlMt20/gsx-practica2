# GSX Pràctica 2 - Infraestructura IT Organitzacional

Implementació d'una infraestructura moderna containeritzada per GreenDevCorp.

**Assignatura:** Gestió de Sistemes i Xarxes (URV)  
**Equip:** Josep Lluís Marín & Gemma Goitia  
**Deadline:** 15 Maig 2026

---

## Descripció

Aquesta pràctica implementa una infraestructura cloud-native utilitzant:
- **Docker** per containerització
- **Docker Compose** per orquestració multi-contenidor
- **Kubernetes** per desplegament en producció
- **Terraform/Ansible** per Infrastructure as Code
- **GitHub Actions** per CI/CD

---

## Estructura del projecte

    gsx-practica2/
    ├── docker/
    │   ├── nginx/
    │   │   ├── Dockerfile
    │   │   ├── nginx.conf
    │   │   └── index.html
    │   └── app/
    │       ├── Dockerfile
    │       └── app.py
    ├── docker-compose/
    │   └── docker-compose.yml
    ├── kubernetes/
    ├── terraform/
    ├── scripts/
    │   └── build-push.sh
    └── docs/

---

## Inici ràpid

### Requisits
- Docker instal·lat
- Docker Compose instal·lat
- Compte a Docker Hub

### Opció 1: Utilitzar imatges de Docker Hub

    docker pull josepllmt20/nginx-gsx:v1
    docker pull josepllmt20/app-gsx:v1
    docker run -d -p 8080:80 --name nginx josepllmt20/nginx-gsx:v1
    docker run -d -p 8081:8080 --name app josepllmt20/app-gsx:v1

### Opció 2: Build local amb Docker Compose

    cd docker-compose
    docker compose up --build

### Verificar

    curl http://localhost:8080       # Nginx (pàgina web)
    curl http://localhost:8080/api   # Backend via reverse proxy

---

## Imatges Docker

| Imatge | Descripció | Docker Hub |
|--------|------------|------------|
| nginx-gsx | Servidor web + reverse proxy | josepllmt20/nginx-gsx |
| app-gsx | Backend Python HTTP | josepllmt20/app-gsx |

---

## Scripts disponibles

| Script | Descripció |
|--------|------------|
| scripts/build-push.sh | Build i push de totes les imatges a Docker Hub |

### Ús

    # Build i push amb versió v1
    ./scripts/build-push.sh

    # Build i push amb versió específica
    ./scripts/build-push.sh v2

    # Només build (sense push)
    ./scripts/build-push.sh v1 --no-push

---

## Arquitectura

    ┌─────────────────────────────────────┐
    │           Docker Network            │
    │           (gsx-network)             │
    │                                     │
    │   ┌─────────┐      ┌─────────┐     │
    │   │  Nginx  │─────▶│   App   │     │
    │   │  :80    │      │  :8080  │     │
    │   └─────────┘      └─────────┘     │
    │                                     │
    └─────────────────────────────────────┘

---

## Setmanes

| Setmana | Tema | Estat |
|---------|------|-------|
| 8 | Containerització (Docker) | ✅ Completada |
| 9 | Multi-container (Docker Compose) | 🔄 En progrés |
| 10 | Orquestració (Kubernetes) | ⬜ Pendent |
| 11 | IaC + CI/CD | ⬜ Pendent |
| 12 | Xarxa i Identitat | ⬜ Pendent |
| 13 | Integració i Observabilitat | ⬜ Pendent |

---

## Documentació

- [Setmana 8: Docker](docs/week1/week1.md)
... (altres setmanes a completar)

---

## Autors

- Josep Lluís Marín ([@josepLlMt20](https://github.com/josepLlMt20))
- Gemma Goitia ([@gemmagoitia](https://github.com/gemmagoitia))

---

## Llicència

Projecte acadèmic - URV 2026