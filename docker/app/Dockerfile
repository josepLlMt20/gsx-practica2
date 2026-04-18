FROM python:3.11-alpine

WORKDIR /app

# Dependències per psycopg2
RUN apk add --no-cache postgresql-libs && \
    apk add --no-cache --virtual .build-deps gcc musl-dev postgresql-dev && \
    pip install psycopg2-binary && \
    apk del .build-deps

COPY app.py .

EXPOSE 8080

CMD ["python", "app.py"]