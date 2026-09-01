#!/bin/bash
# =================================================================
# Projeto DimDim — Checkpoint 1 DevOps (2o Semestre)
# ACR + ACI + Azure Files | Java 17 + MySQL 8
# MySQL via ACR (sem depender do Docker Hub)
# RM representante: 564434
# =================================================================

set -e

RESOURCE_GROUP="rm564434-dimdim-rg"
LOCATION="eastus"
ACR_NAME="rm564434acr"
CONTAINER_GROUP="rm564434-dimdim-group"
IMAGE_APP="rm564434-dimdim-app"
STORAGE_ACCOUNT="rm564434storage"
FILE_SHARE="rm564434-dbdata"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()   { echo -e "${GREEN}[ OK ]${NC} $1"; }

echo ""
echo "================================================================"
echo "   Projeto DimDim — Checkpoint | ACR + ACI | RM564434"
echo "================================================================"
echo ""

# ── 1. Resource Group ────────────────────────────────────────
log "Criando Resource Group..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output table
ok "Resource Group criado."

# ── 2. ACR ───────────────────────────────────────────────────
log "Criando ACR '$ACR_NAME'..."
az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic \
  --admin-enabled true \
  --location "$LOCATION" \
  --output table 2>/dev/null || ok "ACR ja existe."

ACR_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer --output tsv)
ACR_USER=$(az acr credential show --name "$ACR_NAME" --query username --output tsv)
ACR_PASS=$(az acr credential show --name "$ACR_NAME" --query "passwords[0].value" --output tsv)
log "ACR Server: $ACR_SERVER"

# ── 3. Login no ACR ──────────────────────────────────────────
log "Login no ACR..."
az acr login --name "$ACR_NAME"

# ── 4. Build e Push do App ───────────────────────────────────
log "Build da imagem do App..."
docker build -t "$ACR_SERVER/$IMAGE_APP:latest" .
log "Push do App para o ACR..."
docker push "$ACR_SERVER/$IMAGE_APP:latest"
ok "Imagem do App enviada."

# ── 5. Push MySQL para o ACR ─────────────────────────────────
log "Baixando MySQL 8.0..."
docker pull mysql:8.0
docker tag mysql:8.0 "$ACR_SERVER/mysql:8.0"
log "Push do MySQL para o ACR..."
docker push "$ACR_SERVER/mysql:8.0"
ok "MySQL enviado para o ACR."

log "Imagens no ACR:"
az acr repository list --name "$ACR_NAME" --output table

# ── 6. Storage Account + File Share ──────────────────────────
log "Criando Storage Account '$STORAGE_ACCOUNT'..."
az storage account create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT" \
  --sku Standard_LRS \
  --location "$LOCATION" \
  --output table 2>/dev/null || ok "Storage ja existe."

STORAGE_KEY=$(az storage account keys list \
  --resource-group "$RESOURCE_GROUP" \
  --account-name "$STORAGE_ACCOUNT" \
  --query "[0].value" --output tsv)

log "Criando File Share '$FILE_SHARE'..."
az storage share create \
  --name "$FILE_SHARE" \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$STORAGE_KEY" \
  --quota 5 \
  --output none 2>/dev/null || true
ok "Volume persistente criado."

# ── 7. Deleta container group antigo ─────────────────────────
log "Removendo container group anterior..."
az container delete \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_GROUP" \
  --yes 2>/dev/null || true

# ── 8. Gera YAML e Deploy ────────────────────────────────────
log "Preparando YAML do ACI..."
sed \
  -e "s|__ACR_SERVER__|$ACR_SERVER|g" \
  -e "s|__ACR_USER__|$ACR_USER|g" \
  -e "s|__ACR_PASS__|$ACR_PASS|g" \
  -e "s|__STORAGE_ACCOUNT__|$STORAGE_ACCOUNT|g" \
  -e "s|__STORAGE_KEY__|$STORAGE_KEY|g" \
  aci-deploy.yaml > aci-deploy-final.yaml

log "Criando Container Group..."
az container create \
  --resource-group "$RESOURCE_GROUP" \
  --file aci-deploy-final.yaml \
  --output table

rm -f aci-deploy-final.yaml
ok "Container Group criado!"

# ── 9. Resultado ─────────────────────────────────────────────
log "Aguardando containers (~60s)..."
sleep 60

APP_URL=$(az container show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_GROUP" \
  --query "ipAddress.fqdn" --output tsv)

log "Status:"
az container show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$CONTAINER_GROUP" \
  --query "containers[].{Nome:name, Estado:instanceView.currentState.state}" \
  --output table

echo ""
echo "================================================================"
echo -e " ${GREEN}PROJETO DIMDIM RODANDO!${NC}"
echo "================================================================"
echo "  Resource Group  : $RESOURCE_GROUP"
echo "  ACR             : $ACR_SERVER"
echo "  Storage Account : $STORAGE_ACCOUNT"
echo "  Volume          : $FILE_SHARE"
echo "  Swagger         : http://${APP_URL}:8080/swagger-ui.html"
echo "================================================================"
