# 🐳 Parcial 3 – Sistemas Operativos (Kubernetes + Golang)

**👨‍💻 Autor:** Sebastián Arce Pareja  
**🎓 Institución:** EAM   
**📅 Año:** 2025

---

## 📌 Descripción

Este proyecto consiste en el desarrollo de un sistema CRUD de personas implementado con microservicios en Golang, desplegado usando Kubernetes, con persistencia de datos en MongoDB, y validado mediante pruebas unitarias, de integración y colección Postman. Todo esto forma parte del tercer parcial de la asignatura Sistemas Operativos.

---


## 🚀 Comandos útiles para Kubernetes

```bash 
kubectl apply -f docker-compose.yaml

kubectl get pods
kubectl get pv
kubectl get pvc
kubectl get deployments
kubectl get rs
kubectl get svc
kubectl get ingress
```
---
 
## 🐳 Dockerfile del Microservicio

```bash
# Etapa 1: Compilación
FROM golang:1.20-alpine AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o main .

# Etapa 2: Imagen final ligera
FROM alpine:latest
WORKDIR /root/
COPY --from=builder /app/main .

EXPOSE 8080
CMD ["./main"]
```

## 📦 Despliegue con Kubernetes

Todos los archivos YAML están contenidos en docker-compose.yaml, e incluyen:

PersistentVolumes y PersistentVolumeClaims

Despliegue y servicio de MongoDB

Microservicios: Create, Read, Update, Delete

Ingress para exponerlos bajo un mismo dominio

---
## 🔧 Comando para desplegar

```bash

kubectl apply -f docker-compose.yaml

```


## 💾 Copia de seguridad MongoDB
Puedes ejecutar este comando para crear una copia de seguridad de la base de datos:

```bash

kubectl exec -it mongo-89887ddc8-gwq4q -- \
  mongodump --uri="mongodb://localhost:27017/testdb" \
  --out /backup/backup_$(date +%Y%m%d_%H%M%S)

```

## .yaml listo para usar



```bash

# --- Persistent Volumes locales ---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-mongodb-data
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: hostpath  # Añadir esta línea
  hostPath:
    path: /home/sebastian/docker_2025/Corte_3/database  # Asegurarse de que esta ruta sea correcta
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-mongodb-backup
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: hostpath  # Añadir esta línea
  hostPath:
    path: /home/sebastian/docker_2025/Corte_3/backup  # Asegurarse de que esta ruta sea correcta


# --- Persistent Volume Claims ---
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  volumeName: pv-mongodb-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-backup
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  volumeName: pv-mongodb-backup

# --- MongoDB Service & Deployment ---
---
apiVersion: v1
kind: Service
metadata:
  name: mongo
spec:
  ports:
    - port: 27017
      targetPort: 27017
  selector:
    app: mongo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
        - name: mongo
          image: mongo:latest
          ports:
            - containerPort: 27017
          env:
            - name: MONGO_INITDB_DATABASE
              value: testdb
          volumeMounts:
            - name: mongodb-data
              mountPath: /data/db
            - name: mongodb-backup
              mountPath: /backup
      volumes:
        - name: mongodb-data
          persistentVolumeClaim:
            claimName: mongodb-data
        - name: mongodb-backup
          persistentVolumeClaim:
            claimName: mongodb-backup

# --- Create Service ---
---
apiVersion: v1
kind: Service
metadata:
  name: create-service
spec:
  type: NodePort
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 30001
  selector:
    app: create-service
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: create-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: create-service
  template:
    metadata:
      labels:
        app: create-service
    spec:
      containers:
        - name: create-service
          image: sebastianarce/create-golang
          ports:
            - containerPort: 8080
          env:
            - name: MONGO_URI
              value: mongodb://mongo:27017
            - name: MONGO_DATABASE
              value: testdb

# --- Read Service ---
---
apiVersion: v1
kind: Service
metadata:
  name: read-service
spec:
  type: NodePort
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 30002
  selector:
    app: read-service
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: read-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: read-service
  template:
    metadata:
      labels:
        app: read-service
    spec:
      containers:
        - name: read-service
          image: sebastianarce/read-golang
          ports:
            - containerPort: 8080
          env:
            - name: MONGO_URI
              value: mongodb://mongo:27017
            - name: MONGO_DATABASE
              value: testdb

# --- Update Service ---
---
apiVersion: v1
kind: Service
metadata:
  name: update-service
spec:
  type: NodePort
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 30003
  selector:
    app: update-service
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: update-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: update-service
  template:
    metadata:
      labels:
        app: update-service
    spec:
      containers:
        - name: update-service
          image: sebastianarce/update-golang
          ports:
            - containerPort: 8080
          env:
            - name: MONGO_URI
              value: mongodb://mongo:27017
            - name: MONGO_DATABASE
              value: testdb

# --- Delete Service ---
---
apiVersion: v1
kind: Service
metadata:
  name: delete-service
spec:
  type: NodePort
  ports:
    - port: 8080
      targetPort: 8080
      nodePort: 30004
  selector:
    app: delete-service
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: delete-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: delete-service
  template:
    metadata:
      labels:
        app: delete-service
    spec:
      containers:
        - name: delete-service
          image: sebastianarce/delete-golang
          ports:
            - containerPort: 8080
          env:
            - name: MONGO_URI
              value: mongodb://mongo:27017
            - name: MONGO_DATABASE
              value: testdb

# --- Ingress ---
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: golang-kube-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$1
spec:
  rules:
    - host: golang-kube.local
      http:
        paths:
          - path: /create/?(.*)
            pathType: Prefix
            backend:
              service:
                name: create-service
                port:
                  number: 8080
          - path: /read/?(.*)
            pathType: Prefix
            backend:
              service:
                name: read-service
                port:
                  number: 8080
          - path: /update/?(.*)
            pathType: Prefix
            backend:
              service:
                name: update-service
                port:
                  number: 8080
          - path: /delete/?(.*)
            pathType: Prefix
            backend:
              service:
                name: delete-service
                port:
                  number: 8080
```

## 🔗 Créditos
Desarrollado por Sebastián Arce Pareja
EAM – Sistemas Operativos (2025)