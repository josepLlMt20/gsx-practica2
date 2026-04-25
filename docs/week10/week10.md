# Setmana 10 - Kubernetes (Minikube)

## Objectiu

Desplegar l'aplicació en Kubernetes amb escalat automàtic i resiliència.

## Arquitectura

    ┌─────────────────────────────────────────────┐
    │              Kubernetes Cluster             │
    │                                             │
    │   ┌─────────┐   ┌─────────┐   ┌─────────┐  │
    │   │  Nginx  │──▶│   App   │──▶│Postgres │  │
    │   │ :30080  │   │  x2     │   │  :5432  │  │
    │   └─────────┘   └─────────┘   └─────────┘  │
    │    NodePort      ClusterIP     ClusterIP   │
    └─────────────────────────────────────────────┘

## Fitxers

    kubernetes/
    ├── configmap.yaml    # Configuració no sensible
    ├── secret.yaml       # Credencials (base64)
    ├── postgres.yaml     # Deployment + Service
    ├── app.yaml          # Deployment + Service
    └── nginx.yaml        # Deployment + Service (NodePort)

## Resources desplegats

| Tipus | Nom | Descripció |
|-------|-----|------------|
| ConfigMap | app-config | Variables d'entorn |
| Secret | db-secret | Credencials BD (base64) |
| Deployment | postgres | 1 rèplica PostgreSQL |
| Deployment | app | 2 rèpliques backend |
| Deployment | nginx | 1 rèplica Nginx |
| Service | postgres | ClusterIP :5432 |
| Service | app | ClusterIP :8080 |
| Service | nginx | NodePort :30080 |

## Comandes principals

    # Desplegar tot
    kubectl apply -f kubernetes/

    # Veure pods
    kubectl get pods

    # Veure serveis
    kubectl get services

    # Escalar
    kubectl scale deployment app --replicas=4

    # Logs
    kubectl logs -l app=backend

    # Entrar a un pod
    kubectl exec -it deployment/app -- sh

    # Eliminar pod (es recrea automàticament)
    kubectl delete pod -l app=backend

    # URL d'accés
    minikube service nginx --url

## Resource Limits

| Servei | CPU Request | CPU Limit | Mem Request | Mem Limit |
|--------|-------------|-----------|-------------|-----------|
| nginx | 50m | 250m | 32Mi | 128Mi |
| app | 100m | 500m | 64Mi | 256Mi |

## Probes

| Probe | Funció | Configuració |
|-------|--------|--------------|
| readinessProbe | Pod llest per rebre tràfic | HTTP GET / cada 10s |
| livenessProbe | Pod viu i funcionant | HTTP GET / cada 30s |

## Proves realitzades

1. Desplegament complet ✅
2. Escalat 2→4→2 rèpliques ✅
3. Resiliència (pods recreats) ✅
4. Accés via NodePort ✅
5. Variables d'entorn (ConfigMap + Secret) ✅
6. Resource limits aplicats ✅
7. Probes funcionant ✅

## Conceptes clau

| Concepte | Descripció |
|----------|------------|
| Pod | Unitat mínima, conté 1+ contenidors |
| Deployment | Gestiona rèpliques i actualitzacions |
| Service | Exposa pods amb IP estable |
| ConfigMap | Configuració no sensible |
| Secret | Dades sensibles (base64) |
| NodePort | Exposa servei fora del cluster |
| ClusterIP | Només accessible dins el cluster |

## Diferència Docker Compose vs Kubernetes

| Aspecte | Docker Compose | Kubernetes |
|---------|----------------|------------|
| Ús | Desenvolupament | Producció |
| Escalat | Manual | Automàtic |
| Resiliència | Limitada | Alta |
| Complexitat | Baixa | Alta |
| Networking | Simple | Avançat |

## Persistent Storage (Avançat)

### Fitxers

    kubernetes/
    └── postgres-storage.yaml   # PV + PVC

### Recursos

| Tipus | Nom | Capacitat |
|-------|-----|-----------|
| PersistentVolume | postgres-pv | 1Gi |
| PersistentVolumeClaim | postgres-pvc | 1Gi |

### Comandes

    # Veure PV i PVC
    kubectl get pv
    kubectl get pvc

    # Comprovar que estan "Bound"
    kubectl get pv,pvc

### Prova de persistència

1. Fer visites a l'API: total_visits = 22
2. Eliminar pod postgres: kubectl delete pod -l app=postgres
3. Esperar que es recreï
4. Reiniciar app: kubectl rollout restart deployment app
5. Comprovar visites: total_visits = 26 ✅

Les dades sobreviuen a reinicis de pods!

### Conceptes

| Concepte | Descripció |
|----------|------------|
| PersistentVolume (PV) | Emmagatzematge físic al cluster |
| PersistentVolumeClaim (PVC) | Sol·licitud d'emmagatzematge per un pod |
| Bound | PV i PVC connectats correctament |
| hostPath | Emmagatzematge al node (només per dev/test) |