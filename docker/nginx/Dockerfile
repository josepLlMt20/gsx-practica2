# Imatge base
FROM nginx:alpine

# Metadades
LABEL maintainer="Josep Lluís Marín & Gemma Goitia"
LABEL description="Nginx per GreenDevCorp - GSX Pràctica 2"

# Copiar configuració personalitzada (opcional)
# COPY nginx.conf /etc/nginx/nginx.conf

# Copiar pàgina web personalitzada
COPY index.html /usr/share/nginx/html/index.html

# Exposar port 80
EXPOSE 80
