# Setmana 8 - Containerització (Docker)

## Objectiu

Empaquetar aplicacions en contenidors Docker per garantir que funcionen igual en qualsevol entorn.

## Imatges creades

| Imatge | Descripció | Docker Hub |
|--------|------------|------------|
| nginx-gsx:v1 | Servidor web Nginx amb pàgina personalitzada | josepllmt20/nginx-gsx:v1 |
| app-gsx:v1 | Aplicació Python HTTP simple | josepllmt20/app-gsx:v1 |

## Estructura de fitxers

docker/
├── nginx/
│   ├── Dockerfile
│   └── index.html
└── app/
├── Dockerfile
└── app.py

## Dockerfile Nginx

```dockerfile
FROM nginx:alpine

LABEL maintainer="Josep Lluís Marín & Gemma Goitia"
LABEL description="Nginx per GreenDevCorp - GSX Pràctica 2"

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80
```

### Decisions de disseny

- **Base image `nginx:alpine`**: Alpine Linux és molt lleuger (~5MB vs ~130MB d'Ubuntu). Redueix mida de la imatge i superfície d'atac.
- **EXPOSE 80**: Documenta el port que utilitza el contenidor (no l'obre realment, això ho fa `-p` al docker run).

## Dockerfile App Python

```dockerfile
FROM python:3.11-alpine

WORKDIR /app

COPY app.py .

EXPOSE 8080

CMD ["python", "app.py"]
```

### Decisions de disseny

- **Base image `python:3.11-alpine`**: Versió lleugera de Python.
- **WORKDIR /app**: Directori de treball dins el contenidor.
- **CMD**: Comanda per defecte quan s'inicia el contenidor.

## Comandes utilitzades

### Construir imatges

```bash
# Nginx
cd docker/nginx
docker build -t nginx-gsx:v1 .

# App
cd docker/app
docker build -t app-gsx:v1 .
```

### Executar contenidors

```bash
# Nginx al port 8080
docker run -d -p 8080:80 --name nginx-test nginx-gsx:v1

# App al port 8081
docker run -d -p 8081:8080 --name app-test app-gsx:v1
```

### Verificar

```bash
curl http://localhost:8080   # Nginx
curl http://localhost:8081   # App Python
```

### Pujar a Docker Hub

```bash
docker login
docker tag nginx-gsx:v1 josepllmt20/nginx-gsx:v1
docker tag app-gsx:v1 josepllmt20/app-gsx:v1
docker push josepllmt20/nginx-gsx:v1
docker push josepllmt20/app-gsx:v1
```

## Verificació des d'una altra màquina

Qualsevol persona pot descarregar i executar les imatges:

```bash
docker pull josepllmt20/nginx-gsx:v1
docker run -d -p 8080:80 josepllmt20/nginx-gsx:v1
```

## Conceptes apresos

| Concepte | Descripció |
|----------|------------|
| Contenidor | Procés aïllat que inclou l'aplicació i dependències |
| Imatge | Plantilla immutable per crear contenidors |
| Dockerfile | Fitxer de text amb instruccions per construir una imatge |
| Docker Hub | Registre públic d'imatges Docker |
| Alpine | Distribució Linux molt lleugera, ideal per contenidors |

## Diferència contenidor vs màquina virtual

| Característica | Contenidor | Màquina Virtual |
|----------------|------------|-----------------|
| Virtualització | Sistema operatiu (kernel compartit) | Hardware complet |
| Mida | MB | GB |
| Arrencada | Segons | Minuts |
| Aïllament | Processos | Complet |
| Ús de recursos | Baix | Alt |
