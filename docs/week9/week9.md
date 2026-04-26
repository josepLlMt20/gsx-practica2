# Setmana 9 - Docker Compose

## Objectiu

Orquestrar múltiples contenidors que treballen junts.

## Arquitectura

    [Client] → [Nginx:80] → [App:8080] → [PostgreSQL:5432]
                                              ↓
                                        [postgres-data]

## Serveis

| Servei | Imatge | Port | Funció |
|--------|--------|------|--------|
| nginx | nginx-gsx | 8080:80 | Servidor web + reverse proxy |
| app | app-gsx | 8080 (intern) | Backend Python |
| postgres | postgres:16-alpine | 5432 (intern) | Base de dades |

## Fitxers

    docker-compose/
    ├── docker-compose.yml
    ├── .env.example
    └── .env (no a git)

## Característiques implementades

### Bàsiques
- Tres serveis connectats en xarxa privada
- Reverse proxy amb Nginx

### Intermèdies
- **depends_on amb healthcheck**: Serveis esperen que les dependències estiguin llestes
- **restart: unless-stopped**: Reinici automàtic si falla
- **volumes**: Persistència de dades PostgreSQL
- **environment**: Configuració via variables d'entorn

## Variables d'entorn

| Variable | Descripció | Valor per defecte |
|----------|------------|-------------------|
| APP_ENV | Entorn d'execució | production |
| APP_DEBUG | Mode debug | false |
| DB_HOST | Host de PostgreSQL | postgres |
| DB_PORT | Port de PostgreSQL | 5432 |
| DB_NAME | Nom de la base de dades | greendevcorp |
| DB_USER | Usuari de la BD | gsx |
| DB_PASSWORD | Contrasenya de la BD | gsx123 |

## Comandes

    # Arrancar
    docker compose up -d

    # Arrancar amb rebuild
    docker compose up --build -d

    # Aturar
    docker compose down

    # Aturar i eliminar volums
    docker compose down -v

    # Logs
    docker compose logs -f

    # Logs d'un servei
    docker compose logs -f app

    # Estat
    docker compose ps

## Proves realitzades

1. Pàgina web: curl http://localhost:8080 ✅
2. API backend: curl http://localhost:8080/api ✅
3. Comptador de visites a PostgreSQL ✅
4. Persistència de dades (down/up sense -v) ✅
5. Healthchecks funcionant ✅

## Conceptes apresos

| Concepte | Descripció |
|----------|------------|
| Docker Compose | Definir aplicacions multi-contenidor |
| depends_on + condition | Control d'ordre d'arrencada amb healthcheck |
| volumes | Persistència de dades entre reinicis |
| networks | Comunicació privada entre contenidors |
| environment | Configuració sense hardcoding |
| healthcheck | Verificar que un servei està operatiu |

## Diferència ports vs expose

| Directiva | Funció |
|-----------|--------|
| ports: "8080:80" | Accessible des de fora (host) |
| expose: "5432" | Només accessible dins la xarxa Docker |


## Configuració avançada

### Logging

Tots els serveis utilitzen el driver json-file amb rotació:

| Opció | Valor | Funció |
|-------|-------|--------|
| max-size | 10m | Màxim 10MB per fitxer |
| max-file | 3 | Màxim 3 fitxers (rotació) |

Això evita que els logs omplin el disc.

### Resource Limits

| Servei | CPU Limit | Memory Limit | CPU Reserved | Memory Reserved |
|--------|-----------|--------------|--------------|-----------------|
| nginx | 0.5 | 128M | 0.1 | 64M |
| app | 1.0 | 256M | 0.25 | 128M |
| postgres | 1.0 | 512M | 0.25 | 256M |

- **limits**: Màxim que pot utilitzar
- **reservations**: Mínim garantit

### Custom Network

    networks:
      gsx-network:
        driver: bridge
        ipam:
          config:
            - subnet: 172.20.0.0/16

Xarxa privada amb rang d'IPs personalitzat.

## Per què és important?

| Configuració | Importància |
|--------------|-------------|
| Healthchecks | Detectar serveis caiguts automàticament |
| depends_on + condition | Evitar errors d'arrencada per dependències no llestes |
| restart: unless-stopped | Recuperació automàtica de fallades |
| Logging amb límits | Evitar que logs omplin el disc |
| Resource limits | Evitar que un servei consumeixi tots els recursos |
| Custom network | Aïllament i control del rang d'IPs |


## Loki + Grafana (Logging centralitzat)

### Serveis afegits

| Servei | Imatge | Port | Funció |
|--------|--------|------|--------|
| loki | grafana/loki:latest | 3100 | Recollida de logs centralitzada |
| grafana | grafana/grafana:latest | 3000 | Visualització de logs |

### Arquitectura

    [nginx] ──logs──▶ [loki:3100] ◀──consulta──▶ [grafana:3000]
    [app]   ──logs──▶ [loki:3100]

### Com funciona

Nginx i app envien els seus logs directament a Loki mitjançant el driver `grafana/loki-docker-driver`. Loki els emmagatzema i Grafana els visualitza en temps real.

El driver de Loki s'ha instal·lat a la VM amb:

    sudo docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions

Configuració del logging a nginx i app:

    logging:
      driver: loki
      options:
        loki-url: "http://10.0.2.15:3100/loki/api/v1/push"

Loki exposa el port 3100 cap a fora perquè el driver hi pugui accedir:

    loki:
      ports:
        - "3100:3100"

### Persistència

La configuració de Grafana (fonts de dades, dashboards) es guarda en un volum persistent:

    volumes:
      grafana-data:

Així no es perd en fer `docker compose down`.

### Accés a Grafana

    http://localhost:3000
    Usuari: admin
    Contrasenya: (definida a GF_SECURITY_ADMIN_PASSWORD)

### Configuració de Loki a Grafana

1. Connections → Data sources → Add data source
2. Seleccionar Loki
3. URL: `http://loki:3100`
4. Save & test

### Proves realitzades

1. Loki arrenca i és accessible ✅
2. Grafana connecta amb Loki ✅
3. Logs de nginx visibles a Grafana en temps real ✅
4. Persistència de configuració de Grafana entre reinicis ✅
