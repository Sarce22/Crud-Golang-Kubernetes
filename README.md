# 🐳 Parcial 3 – Sistemas Operativos (Kubernetes + Golang)

**👨‍💻 Autor:** Sebastián Arce Pareja  
**🎓 Institución:** EAM   
**📅 Año:** 2025

---

## 📌 Descripción

Este proyecto consiste en el desarrollo de un sistema CRUD de personas implementado con microservicios en Golang, desplegado usando Kubernetes, con persistencia de datos en MongoDB, y validado mediante pruebas unitarias, de integración y colección Postman. Todo esto forma parte del tercer parcial de la asignatura Sistemas Operativos.

---

## 📁 Repositorio del Proyecto

🔗 [GitHub - Sarce22/Crud-Golang-Kubernetes](https://github.com/Sarce22/Crud-Golang-Kubernetes)

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


🐳 Dockerfile del Microservicio

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
---

📦 Despliegue con Kubernetes
Todos los archivos YAML están contenidos en docker-compose.yaml, e incluyen:

PersistentVolumes y PersistentVolumeClaims

Despliegue y servicio de MongoDB

Microservicios: Create, Read, Update, Delete

Ingress para exponerlos bajo un mismo dominio

---
🔧 Comando para desplegar

kubectl apply -f docker-compose.yaml


💾 Copia de seguridad MongoDB
Puedes ejecutar este comando para crear una copia de seguridad de la base de datos:

kubectl exec -it mongo-89887ddc8-gwq4q -- \
  mongodump --uri="mongodb://localhost:27017/testdb" \
  --out /backup/backup_$(date +%Y%m%d_%H%M%S)


🔗 Créditos
Desarrollado por Sebastián Arce Pareja
EAM – Sistemas Operativos (2025)