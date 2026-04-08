# Deploy en Azure Kubernetes Service (AKS) - Microservicios

## Índice

1. [Login y Configuración de Azure](#1-login-y-configuración-de-azure)
2. [Crear el Cluster AKS](#2-crear-el-cluster-aks)
3. [Instalar Nginx Ingress Controller](#3-instalar-nginx-ingress-controller)
4. [Deploy de la Aplicación](#4-deploy-de-la-aplicación)
5. [Requisito 11: Verificar pods a través del Service](#5-requisito-11-verificar-pods-a-través-del-service)
6. [Requisito 12: Ingress y acceso externo](#6-requisito-12-ingress-y-acceso-externo)
7. [Requisito 13: Escalado horizontal](#7-requisito-13-escalado-horizontal)
8. [Requisito 14: Estado general del cluster](#8-requisito-14-estado-general-del-cluster)
9. [Limpieza](#9-limpieza)

---

## 1. Login y Configuración de Azure

```bash
# Login a Azure
az login

# Seleccionar suscripción
az account set --subscription ee9628ea-3253-46a8-b7d8-6cb18091fc1e

# Verificar suscripción activa
az account show -o table
```

## 2. Crear el Cluster AKS

```bash
# Verificar providers de Kubernetes
az provider register --namespace Microsoft.ContainerService
az provider show --namespace Microsoft.ContainerService --query "registrationState"

# Crear Resource Group
az group create --name rg-nube2 --location mexicocentral

# Crear cluster AKS
az aks create --resource-group rg-nube2 --name aks-nube2 --node-count 2 --location mexicocentral --node-vm-size Standard_B2s --generate-ssh-keys

# Obtener credenciales de kubectl
az aks get-credentials --resource-group rg-nube2 --name aks-nube2 --overwrite-existing

# Verificar nodos del cluster
kubectl get nodes -o wide
```

## 3. Instalar Nginx Ingress Controller

```bash
# Instalar Nginx Ingress Controller para AKS
# El YAML ya crea el namespace ingress-nginx automáticamente
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# Verificar que el ingress controller esté corriendo
kubectl get pods -n ingress-nginx

# Ver el servicio del ingress controller (contiene la IP externa)
kubectl get svc -n ingress-nginx

# Esperar a que esté listo (timeout 5 minutos)
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s
```

## 4. Deploy de la Aplicación

```bash
# Asegúrate de estar en el directorio donde está el archivo
cd aks/

# Aplicar el manifest de la aplicación
vim webapp-k8s.yaml
kubectl apply -f webapp-k8s.yaml

# Verificar namespace creado
kubectl get ns webapp

# Ver todos los deployments
kubectl get deploy -n webapp

# Ver todos los pods con detalle
kubectl get pods -n webapp -o wide

# Ver los PersistentVolumeClaims
kubectl get pvc -n webapp

# Ver estado de los eventos (útil si hay errores)
kubectl get events -n webapp --sort-by='.lastTimestamp'
```

## 5. Requisito 11: Verificar pods a través del Service

### Listar Services

```bash
kubectl get svc -n webapp
```

**Output esperado:**
```
NAME            TYPE        CLUSTER-IP     PORT(S)    AGE
users-db        ClusterIP   10.0.x.x       3306/TCP   Xm
products-db     ClusterIP   10.0.x.x       3306/TCP   Xm
orders-db       ClusterIP   10.0.x.x       3306/TCP   Xm
users-svc       ClusterIP   10.0.x.x       3001/TCP   Xm
products-svc    ClusterIP   10.0.x.x       3002/TCP   Xm
orders-svc      ClusterIP   10.0.x.x       3003/TCP   Xm
```

### Probar servicios con kubectl run (curl)

```bash
# Probar Users Service
kubectl run curl-users --rm -i --restart=Never --image=curlimages/curl -n webapp --command -- sh -c "curl -sS http://users-svc:3001/api/users"

# Probar Products Service
kubectl run curl-products --rm -i --restart=Never --image=curlimages/curl -n webapp --command -- sh -c "curl -sS http://products-svc:3002/api/products"

# Probar Orders Service
kubectl run curl-orders --rm -i --restart=Never --image=curlimages/curl -n webapp --command -- sh -c "curl -sS http://orders-svc:3003/api/orders"
```

### Alternativa: Port-forward

```bash
# Terminal 1: crear port-forward
kubectl port-forward -n webapp svc/users-svc 3001:3001

# Terminal 2: probar el servicio
curl http://127.0.0.1:3001/api/users
```

## 6. Requisito 12: Ingress y acceso externo

### Obtener información del Ingress

```bash
# Ver el Ingress creado
kubectl get ingress -n webapp

# Ver IP externa del Ingress Controller
kubectl get svc -n ingress-nginx ingress-nginx-controller -o wide

# Descripción detallada del Ingress
kubectl describe ingress ingress-webapp -n webapp
```

**Output esperado de Ingress:**
```
NAME              CLASS   HOSTS   ADDRESS        PORTS   AGE
ingress-webapp    nginx   *       20.XX.XX.XX    80      Xm
```

### Probar rutas del Ingress

```bash
# Obtener IP del Ingress
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Probar cada ruta
curl http://${INGRESS_IP}/api/users/
curl http://${INGRESS_IP}/api/products/
curl http://${INGRESS_IP}/api/orders/
```

## 7. Requisito 13: Escalado horizontal

### Estado inicial (2 replicas)

```bash
# Ver deployment de orders
kubectl get deployment orders-deploy -n webapp

# Listar pods de orders
kubectl get pods -l app=orders-service -n webapp
```

### Escalar a 4 replicas

```bash
kubectl scale deployment orders-deploy --replicas=4 -n webapp
```

### Verificar nuevas replicas

```bash
# Ver deployment actualizado
kubectl get deployment orders-deploy -n webapp

# Ver que ahora hay 4 pods
kubectl get pods -l app=orders-service -n webapp
```

### Verificar distribución de tráfico durante escalado

```bash
# Ejecutar requests continuos (con Ingress)
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

for i in {1..20}; do
  echo "Request $i:"
  curl -s http://${INGRESS_IP}/api/orders/ | head -c 100
  echo ""
  sleep 0.5
done
```

### Escalar de vuelta a 2 (opcional)

```bash
kubectl scale deployment orders-deploy --replicas=2 -n webapp
```

## 8. Requisito 14: Estado general del cluster

### Estado completo

```bash
kubectl get all -n webapp
```

**Output esperado:**
```
NAME              READY   STATUS    RESTARTS   AGE
pod/users-db-0    1/1     Running   0          Xm
pod/products-db-0 1/1     Running   0          Xm
pod/orders-db-0   1/1     Running   0          Xm
pod/users-deploy-xxxxx   1/1     Running   0          Xm
pod/users-deploy-xxxxx   1/1     Running   0          Xm
pod/products-deploy-xxxxx 1/1     Running   0          Xm
pod/products-deploy-xxxxx 1/1     Running   0          Xm
pod/orders-deploy-xxxxx   1/1     Running   0          Xm
pod/orders-deploy-xxxxx   1/1     Running   0          Xm

NAME                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/users-db     ClusterIP   10.0.x.x       <none>        3306/TCP   Xm
service/products-db  ClusterIP   10.0.x.x       <none>        3306/TCP   Xm
service/orders-db    ClusterIP   10.0.x.x       <none>        3306/TCP   Xm
service/users-svc    ClusterIP   10.0.x.x       <none>        3001/TCP   Xm
service/products-svc ClusterIP   10.0.x.x       <none>        3002/TCP   Xm
service/orders-svc   ClusterIP   10.0.x.x       <none>        3003/TCP   Xm

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/users-db     1/1     1            1           Xm
deployment.apps/products-db  1/1     1            1           Xm
deployment.apps/orders-db    1/1     1            1           Xm
deployment.apps/users-deploy 2/2     2            2           Xm
deployment.apps/products-deploy 2/2  2            2           Xm
deployment.apps/orders-deploy 2/2   2            2           Xm

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/users-deploy-xxxxx   2         2         2       Xm
replicaset.apps/products-deploy-xxxxx 2        2         2       Xm
replicaset.apps/orders-deploy-xxxxx   2         2         2       Xm

NAME                            READY   AGE
statefulset.apps/users-db       1/1     Xm
statefulset.apps/products-db   1/1     Xm
statefulset.apps/orders-db     1/1     Xm
```

### Otros comandos de verificación

```bash
# Ver PersistentVolumeClaims
kubectl get pvc -n webapp

# Ver Ingress
kubectl get ingress -n webapp

# Ver todos los recursos en formato amplio
kubectl get all,pvc,ingress -n webapp -o wide
```

## 9. Limpieza

```bash
# Eliminar todos los recursos de la aplicación
kubectl delete -f microapp-k8s.yaml

# Eliminar el ingress controller
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# Eliminar el cluster AKS (opcional)
az aks delete --resource-group rg-nube2 --name aks-nube2 --yes
```

## Comandos útiles de debugging

```bash
# Ver logs de un pod
kubectl logs <pod-name> -n webapp

# Ver logs de todos los pods de un servicio
kubectl logs -l app=users-service -n webapp

# Describir un pod (útil para errores)
kubectl describe pod <pod-name> -n webapp

# Ver eventos del namespace
kubectl get events -n webapp --sort-by='.lastTimestamp'

# Reiniciar un deployment
kubectl rollout restart deployment/users-deploy -n webapp

# Ver estado del rollout
kubectl rollout status deployment/users-deploy -n webapp
```
