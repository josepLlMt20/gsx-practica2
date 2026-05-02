FROM python:3.11-alpine

WORKDIR /app

# Actualitzar paquets del sistema i pip/setuptools
RUN apk update && apk upgrade --no-cache && \
    pip install --no-cache-dir --upgrade pip setuptools wheel

# Dependències per psycopg2
RUN apk add --no-cache postgresql-libs && \
    apk add --no-cache --virtual .build-deps gcc musl-dev postgresql-dev && \
    pip install --no-cache-dir psycopg2-binary && \
    apk del .build-deps

COPY app.py .

EXPOSE 8080

CMD ["python", "app.py"]
