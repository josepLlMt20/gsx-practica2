# Setmana 12: Network Design & Identity

**Autors:** Josep Lluís Marín & Gemma Goitia
**Data:** Maig 2026

---

## 1. Arquitectura de Xarxa

### 1.1 Diagrama de xarxa GreenDevCorp

                            INTERNET
                                |
                           [Firewall]
                                |
    ========================== DMZ (10.0.0.0/24) ==========================
                                |
                         [Load Balancer]
                          Nginx 10.0.0.10
                                |
    ===================== INTERNAL (10.0.1.0/24) ======================
                                |
              +-----------------+-----------------+
              |                 |                 |
          [App Pod]        [App Pod]         [App Pod]
          10.0.1.11        10.0.1.12         10.0.1.13
              |                 |                 |
              +-----------------+-----------------+
                                |
    ===================== DATABASE (10.0.2.0/24) ======================
                                |
                          [PostgreSQL]
                           10.0.2.10

### 1.2 Pla d'adreces IP (CIDR)

| Xarxa | CIDR | IPs disponibles | Ús |
|-------|------|-----------------|-----|
| Organització | 10.0.0.0/16 | 65.534 | Rang complet GreenDevCorp |
| DMZ | 10.0.0.0/24 | 254 | Load balancers, reverse proxies |
| Internal/Apps | 10.0.1.0/24 | 254 | Aplicacions backend |
| Database | 10.0.2.0/24 | 254 | Bases de dades |
| Management | 10.0.3.0/24 | 254 | Monitorització, logs |
| Development | 10.0.10.0/24 | 254 | Entorn desenvolupament |
| Staging | 10.0.20.0/24 | 254 | Entorn staging |
| Partners | 10.0.100.0/24 | 254 | Accés extern controlat |

Per què aquesta divisió:
- Separació clara entre entorns (dev/staging/prod)
- Base de dades aïllada en xarxa pròpia
- DMZ per serveis exposats a internet
- Espai per créixer (65K IPs totals)

---

## 2. NetworkPolicies Kubernetes

### 2.1 Estratègia: Default Deny

Apliquem el principi de "zero trust": tot està bloquejat per defecte, i només permetem el tràfic necessari.

### 2.2 Policies implementades

Fitxers a kubernetes/network-policies/:

1. deny-all.yml - Bloqueja tot el tràfic per defecte
2. allow-ingress-to-nginx.yml - Permet tràfic extern al port 80 de Nginx
3. allow-nginx-to-app.yml - Permet Nginx connectar a App al port 8080
4. allow-app-to-postgres.yml - Permet App connectar a PostgreSQL al port 5432

### 2.3 Flux de tràfic permès

    Internet --> Nginx:80 --> App:8080 --> Postgres:5432
        ✅          ✅           ✅            ✅

    Internet --> App:8080        ❌ BLOQUEJAT
    Internet --> Postgres:5432   ❌ BLOQUEJAT
    Nginx --> Postgres:5432      ❌ BLOQUEJAT

### 2.4 Comandes de verificació

    kubectl get networkpolicies
    kubectl describe networkpolicy allow-nginx-to-app
    kubectl apply -f kubernetes/network-policies/

### 2.5 Nota: CNI

Les NetworkPolicies requereixen un CNI que les suporti (Calico, Cilium). 
El CNI per defecte de Minikube no les enforça, però es creen igualment.
Per producció: minikube start --cni=calico

---

## 3. Serveis de Xarxa Essencials

### 3.1 DNS (Domain Name System)

Què és: DNS tradueix noms de domini (www.greendevcorp.com) a adreces IP. És la "guia telefònica" d'internet.

Per què és important:
- Permet usar noms llegibles en lloc de IPs
- Facilita la gestió quan canvien IPs
- Serveis interns poden tenir noms privats (app.internal.greendevcorp.com)

Com funciona:
1. L'usuari escriu www.greendevcorp.com
2. El navegador pregunta al DNS resolver
3. El resolver consulta servidors DNS fins trobar la IP
4. Retorna la IP al navegador
5. El navegador connecta amb la IP

A Kubernetes: CoreDNS permet que els pods es trobin per nom (postgres.default.svc.cluster.local)

### 3.2 DHCP (Dynamic Host Configuration Protocol)

Què és: DHCP assigna automàticament adreces IP als dispositius quan es connecten a una xarxa.

Per què és important:
- No cal configurar IPs manualment
- Evita conflictes d'IP
- Centralitza la gestió d'adreces

Com funciona:
1. Dispositiu nou es connecta
2. Envia broadcast "Necessito una IP!"
3. Servidor DHCP ofereix una IP
4. Dispositiu accepta
5. Servidor confirma

A GreenDevCorp:
- Oficines: DHCP per portàtils i mòbils
- Servidors: IPs estàtiques
- Kubernetes: El CNI gestiona les IPs dels pods

### 3.3 NTP (Network Time Protocol)

Què és: NTP sincronitza els rellotges de tots els dispositius d'una xarxa.

Per què és important:
- Logs: Sense temps sincronitzat, és impossible correlacionar events
- Seguretat: Certificats TLS depenen de timestamps correctes
- Bases de dades: Transaccions necessiten temps consistent
- Compliance: Auditories requereixen timestamps precisos

Com funciona:
1. Client NTP contacta servidor NTP
2. Servidor retorna l'hora exacta
3. Client ajusta el seu rellotge
4. Es repeteix periòdicament

---

## 4. Gestió d'Identitat

### 4.1 Autenticació vs Autorització

| Concepte | Pregunta | Exemple |
|----------|----------|---------|
| Autenticació | Qui ets? | Login amb usuari/password |
| Autorització | Què pots fer? | Tens permís per accedir a /admin? |

Exemple: Josep fa login (autenticació), després el sistema comprova si pot accedir a /admin (autorització).

### 4.2 LDAP (Lightweight Directory Access Protocol)

Què és: Protocol per accedir a un directori centralitzat d'usuaris, grups i recursos.

Estructura típica:
    dc=greendevcorp,dc=com
    ├── ou=Users
    │   ├── cn=Josep Lluís Marín
    │   └── cn=Gemma Goitia
    ├── ou=Groups
    │   ├── cn=Developers
    │   └── cn=Admins
    └── ou=Services

Avantatges:
- Un únic lloc per gestionar tots els usuaris
- Canviar password un cop funciona a tot arreu
- Grups centralitzats per permisos

### 4.3 Active Directory (AD)

Què és: Implementació de Microsoft d'un servei de directori. Inclou LDAP més funcionalitats addicionals.

Funcionalitats: Kerberos, Group Policy, DNS integrat, Certificats, Federació.

Quan usar-lo: Entorns amb molts PCs Windows, necessitat de GPOs, integració amb Office 365.

### 4.4 SSO (Single Sign-On)

Què és: Permet iniciar sessió una vegada i accedir a múltiples aplicacions sense tornar a autenticar-se.

Com funciona:
1. Usuari va a app1.greendevcorp.com
2. App1 redirigeix al servidor SSO
3. Usuari s'autentica
4. SSO retorna token a App1
5. Usuari accedeix a App1
6. Quan va a App2, el token ja és vàlid (no cal login)

Protocols: SAML 2.0, OAuth 2.0, OpenID Connect, Kerberos

Avantatges:
- Millor experiència d'usuari
- Més segur (passwords no van a cada app)
- Fàcil revocar accés centralment

---

## 5. Recomanació d'Identitat per GreenDevCorp

### 5.1 Situació
- 20+ empleats amb creixement previst
- Aplicacions containeritzades
- Necessitat de gestió centralitzada

### 5.2 Recomanació: Keycloak

| Factor | Keycloak | Active Directory |
|--------|----------|------------------|
| Cost | Gratuït (open source) | Llicències Windows |
| Cloud-native | Sí (containers) | No (requereix VMs) |
| SSO modern | OIDC/OAuth2 natiu | Requereix ADFS |
| Escalabilitat | Horitzontal | Vertical |

Decisió: Per una startup tech de 20 persones amb infraestructura containeritzada, Keycloak és l'opció més equilibrada.

---

## 6. Preguntes d'entrevista

P: Per què segmentar la xarxa?
R: Per limitar el blast radius d'un atac. Si comprometen un pod a la DMZ, les NetworkPolicies impedeixen accés a la base de dades.

P: Què és default-deny?
R: Bloquejar tot per defecte i afegir regles explícites per permetre només el tràfic necessari. Principi de mínim privilegi.

P: Diferència autenticació i autorització?
R: Autenticació verifica QUI ets. Autorització determina QUÈ pots fer.

P: Per què SSO és més segur?
R: El password només va al servidor d'identitat, no a cada app. Menys exposició = menys risc.

P: Keycloak vs AD per GreenDevCorp?
R: Keycloak és gratuït, cloud-native, i s'integra millor amb containers. AD seria overkill per 20 persones.
