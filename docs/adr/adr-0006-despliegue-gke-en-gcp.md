# ADR-0006: Despliegue en Google Kubernetes Engine (GKE) sobre GCP

## Estado

Aceptada

**Fecha:** 2026-06-02

## Contexto

La cátedra exige desplegar el sistema en la nube y permite tres caminos:

- **PaaS** (Heroku, Railway, Render, Fly.io, App Engine, Cloud Run…): deploy rápido, abstracción alta, menos control sobre red/scheduling.
- **Orquestador de contenedores gestionado** (GKE, EKS, AKS, DigitalOcean Kubernetes…): control granular, configuración declarativa, curva de aprendizaje mayor.
- **Cloud provider directo** (VMs en GCP/AWS/Azure): control total, pero todo el operativo (HA, TLS, networking) queda a cargo del grupo.

La decisión debe documentarse y justificarse.

Restricciones y motivaciones del grupo:

- **Presupuesto cero:** somos un grupo académico, no podemos pagar infraestructura. El sistema necesita estar **online** para las demos de CP2/CP3 y la entrega final.
- **Cuatro servicios backend + dos frontends + RabbitMQ + bases de datos** ya están dockerizados; cualquier plataforma elegida tiene que correr múltiples contenedores comunicándose entre sí.
- Necesitamos **un único punto de entrada con TLS**, ya decidido como Kong API Gateway en [ADR-0002](adr-0002-kong-como-api-gateway.md). Eso requiere una plataforma donde podamos correr nuestro propio gateway, no una que imponga el suyo.
- **GitOps con ArgoCD** es el flujo de despliegue que adoptó el equipo: push de imagen → Image Updater detecta tag → ArgoCD sincroniza el cluster. Esto presupone un cluster Kubernetes accesible vía API.
- **Aprendizaje:** el cuatrimestre es una de las pocas oportunidades que tenemos de operar Kubernetes "de verdad" antes de un trabajo profesional. El grupo prioriza aprender el stack que más vamos a ver en el mercado, aun aceptando complejidad mayor.

Alternativas consideradas:

- **Railway / Render / Fly.io (PaaS):** despliegue trivial, pero las free tiers son limitadas (poca RAM por servicio, dormancia tras inactividad), no integran bien Kong como gateway propio y obligarían a abandonar el setup GitOps + Helm que el equipo ya armó.
- **Cloud Run (Google):** muy bueno para servicios HTTP stateless individuales y free tier generosa, pero introduce fricciones reales: el modelo "una request → un container" no encaja con un consumer RabbitMQ que vive idle, las comunicaciones service-to-service requerirían Cloud Run-to-Cloud Run o un Cloud Load Balancer, y el setup de Kong como gateway no aplica directamente.
- **VMs en GCP/AWS (control directo):** máxima libertad pero obliga a resolver a mano el orquestamiento, HA, rolling updates, TLS, secret management — fuera del scope académico.
- **EKS (AWS) / AKS (Azure):** Kubernetes gestionado equivalente a GKE, pero AWS no ofrece créditos comparables sin tarjeta empresarial y Azure for Students tiene cuotas restringidas; además ninguno de los miembros tiene experiencia previa con sus consolas.
- **GKE (Google):** Kubernetes gestionado, integra bien con cert-manager + Gateway API + ArgoCD, GCP ofrece **USD 300 en créditos gratuitos** para cuentas nuevas — suficiente para cubrir el cuatrimestre completo con un cluster zonal modesto.

## Decisión

Adoptamos **Google Kubernetes Engine (GKE) sobre Google Cloud Platform** como plataforma de despliegue para todos los servicios backend y las bases de datos del proyecto.

Decisiones concretas:

- **Provider:** GCP, elegido por los **USD 300 en créditos gratuitos** que cubren el costo del cluster durante todo el cuatrimestre sin gasto del grupo.
- **Compute:** un cluster GKE **zonal** (la opción más barata) con node pool autoescalable acotado, suficiente para los servicios del proyecto.
- **Networking:** Kong Gateway expuesto vía `LoadBalancer` con IP pública `35.247.221.39.nip.io` y TLS Let's Encrypt (cert-manager). Servicios internos como `ClusterIP`.
- **Persistencia:** PostgreSQL provisto por Supabase (managed, free tier), MongoDB Atlas (managed, free tier), RabbitMQ desplegado en el mismo cluster. Las bases de datos no consumen créditos GCP.
- **GitOps:** ArgoCD instalado en el cluster sincroniza manifiestos desde el repo `infra`. Image Updater detecta nuevos tags en GHCR (`1.0.X`) y trigerea rolling updates automáticos.
- **Imágenes:** GHCR (GitHub Container Registry) como registry, gratis e integrado al CI/CD via GitHub Actions; pull secret en cluster.

## Consecuencias

**Positivas**

- **Costo cero durante el cuatrimestre:** los créditos cubren el cluster y el sistema queda online para todas las demos sin gasto del grupo.
- **Control total del runtime:** podemos correr Kong como gateway, RabbitMQ propio, plugins Lua custom (`forward-email`, `require-admin`), CronJobs, lo que necesitemos — nada de eso es posible con PaaS.
- **GitOps real:** push → ArgoCD sync, sin scripts manuales ni deploys ad-hoc. Estado del cluster siempre reconciliable contra git.
- **Aprendizaje:** el equipo trabaja con HTTPRoutes, ReferenceGrants, Helm charts, cert-manager y patrones de Kubernetes que son industry-standard.
- **Portabilidad:** todo el sistema se describe con manifiestos K8s estándar; migrar a EKS/AKS o a un cluster on-prem es viable sin reescribir.

**Negativas**

- **Curva de aprendizaje alta:** el equipo tuvo que aprender Gateway API, ArgoCD, cert-manager, Image Updater y debugging de pods desde cero. En etapas tempranas eso costó velocidad.
- **Más superficie operativa que un PaaS:** hay que mantener manifiestos, secretos en el cluster, monitorear el estado de los pods, lidiar con CrashLoopBackOff, OOMKills y rolling updates fallidos.
- **Dependencia de los créditos:** cuando se agoten (estimado: post-entrega), GCP empezará a facturar. El plan es apagar el cluster después del 26/06/2026 o migrar a un free tier alternativo si el sistema sobrevive al curso.
- **Vendor lock-in moderado:** aunque los manifiestos son portables, dependencias específicas del cluster (Workload Identity, GCP Load Balancer, cert-manager con ACME HTTP01) ataría una migración a configurar equivalentes en otro provider.

**Neutras**

- **TLS gestionado por cert-manager + Let's Encrypt**: independiente de GCP, mismo flujo en cualquier cluster K8s.
- **Bases de datos fuera del cluster** (Supabase, MongoDB Atlas): aísla el storage del compute, lo que simplifica restarts y reduce el riesgo de perder datos al reciclar nodos, a cambio de un hop de red más en cada query.
- **Cluster zonal (no regional):** un fallo de zona implica downtime hasta que GCP reasigne; aceptable para un proyecto académico.
