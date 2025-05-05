#!/bin/bash

# ============================
# Colores para salida legible
# ============================
GREEN='\033[0;32m'     # Verde
YELLOW='\033[1;33m'    # Amarillo
RED='\033[0;31m'       # Rojo
NC='\033[0m'           # Reset de color

# ============================
# Usuario de Docker Hub
# ============================
DOCKER_USER="sebastianarce"

# ============================
# Lista de microservicios
# ============================
SERVICES=("create" "read" "update" "delete")
PORTS=(30001 30002 30003 30004)

# ============================
# Función para verificar cambios
# ============================
function check_changes() {
    echo -e "${GREEN}[INFO] Verificando cambios en los microservicios...${NC}"

    CHANGED_SERVICES=()

    for SERVICE in "${SERVICES[@]}"; do
        if git status --porcelain | grep "${SERVICE}/" > /dev/null; then
            CHANGED_SERVICES+=("$SERVICE")
        fi
    done

    if [ ${#CHANGED_SERVICES[@]} -eq 0 ]; then
        echo -e "${GREEN}[INFO] No se detectaron cambios en los microservicios.${NC}"
        return 1
    else
        echo -e "${YELLOW}[CAMBIOS DETECTADOS] Se modificaron:${NC}"
        for svc in "${CHANGED_SERVICES[@]}"; do
            echo -e "  - $svc"
        done
        return 0
    fi
}

# ============================
# Función para realizar Git commit y push
# ============================
function git_push() {
    read -p "¿Deseas subir los cambios a GitHub? (s/N): " push_git

    if [[ "$push_git" =~ ^[sS]$ ]]; then
        echo -e "${GREEN}[GIT] Agregando cambios...${NC}"
        git add .

        read -p "📝 Escribe un mensaje para el commit: " commit_message
        git commit -m "$commit_message"

        current_branch=$(git symbolic-ref --short HEAD)
        echo -e "${GREEN}[GIT] Haciendo push a '${current_branch}'...${NC}"
        git push origin "$current_branch"
    else
        echo -e "${YELLOW}[GIT] Cambios locales NO fueron subidos a GitHub.${NC}"
    fi
}

# ============================
# Función para construir y subir Docker
# ============================
function docker_build_push() {
    for svc in "${CHANGED_SERVICES[@]}"; do
        IMAGE_NAME="${DOCKER_USER}/${svc}-golang:latest"

        echo -e "${GREEN}[DOCKER] Construyendo imagen: $IMAGE_NAME...${NC}"
        docker build -t "$IMAGE_NAME" "./$svc" || { echo -e "${RED}[ERROR] Falló el build de $svc${NC}"; exit 1; }

        echo -e "${GREEN}[DOCKER] Subiendo imagen a Docker Hub: $IMAGE_NAME...${NC}"
        docker push "$IMAGE_NAME" || { echo -e "${RED}[ERROR] Falló el push de $svc${NC}"; exit 1; }
    done
}

# ============================
# Función para aplicar despliegue en Kubernetes
# ============================
function kubernetes_deploy() {
    echo -e "${GREEN}[KUBERNETES] Aplicando manifiestos con kubectl...${NC}"
    kubectl apply -f docker-compose.yaml

    echo -e "${YELLOW}[INFO] Esperando 10 segundos para que se levanten los pods...${NC}"
    sleep 10
}

# ============================
# Función para verificar los endpoints
# ============================
function verify_endpoints() {
    echo -e "${GREEN}[VERIFICACIÓN] Probando endpoints expuestos en NodePorts...${NC}"

    # Prueba Create
    echo -e "${YELLOW}→ Probando servicio 'create' en http://localhost:30001/create${NC}"
    if curl --silent --fail -X POST "http://localhost:30001/create" -d '{
  "nombre": "Test User",
  "telefono": "3001234567",
  "direccion": "Calle 123, Ciudad",
  "cedula": "77799",
  "correo": "testuggsher@example.com"
}' -H "Content-Type: application/json"; then
  echo -e "${GREEN}[✔] El servicio 'create' respondió correctamente.${NC}"
else
  echo -e "${RED}[✖] El servicio 'create' falló.${NC}"
fi


    # Prueba Read
    echo -e "${YELLOW}→ Probando servicio 'read' en http://localhost:30002/read${NC}"
    if curl --silent --fail "http://localhost:30002/read"; then
        echo -e "${GREEN}✔ Read respondió correctamente.${NC}"
    else
        echo -e "${RED}✖ Read no respondió o falló.${NC}"
    fi

    # Prueba Update (por cédula)
   echo -e "${YELLOW}→ Probando servicio 'update'" 
   if curl --silent --fail -X PUT "http://localhost:30003/update/update-by-cedula/100" -d '{
  "nombre": "Sebastian Arce Pareja",
  "telefono": "225151161",
  "direccion": "USA-Colombia",
  "correo": "sebastianUSA482@gmial.com"
}' -H "Content-Type: application/json"; then
  echo -e "${GREEN}[✔] El servicio 'update' respondió correctamente.${NC}"
else
  echo -e "${RED}[✖] El servicio 'update' falló.${NC}"
fi

    # Prueba Delete (por userID)
    echo -e "${YELLOW}→ Probando servicio 'delete' en http://localhost:30004/users/cedula/987654321${NC}"
    if curl --silent --fail -X DELETE "http://localhost:30004/users/cedula/987654321"; then
        echo -e "${GREEN}✔ Delete respondió correctamente.${NC}"
    else
        echo -e "${RED}✖ Delete no respondió o falló.${NC}"
    fi
}

# ============================
# Menú principal
# ============================
while true; do
    echo -e "${YELLOW}=============================${NC}"
    echo -e "${GREEN}Elige una opción:${NC}"
    echo -e "1) Verificar cambios"
    echo -e "2) Subir cambios a GitHub"
    echo -e "3) Construir y subir Docker"
    echo -e "4) Desplegar en Kubernetes"
    echo -e "5) Verificar endpoints"
    echo -e "6) Salir"
    echo -e "${YELLOW}=============================${NC}"

    read -p "Opción (1-6): " choice

    case $choice in
        1)
            check_changes
            ;;
        2)
            git_push
            ;;
        3)
            docker_build_push
            ;;
        4)
            kubernetes_deploy
            ;;
        5)
            verify_endpoints
            ;;
        6)
            echo -e "${GREEN}¡Adiós!${NC}"
            break
            ;;
        *)
            echo -e "${RED}[ERROR] Opción no válida.${NC}"
            ;;
    esac
done
