#!/bin/bash
# =================================================================
# DimDim - CP5 - Script Azure CLI
# Recursos: Azure SQL Database + Azure Web App + Application Insights
# Disciplina: DevOps Tools & Cloud Computing - FIAP 2026
# Professor: Joao Menk
# =================================================================
# USO:
#   chmod +x scripts/azure-setup-cp5.sh
#   az login
#   ./scripts/azure-setup-cp5.sh
# =================================================================

set -e

# ── Variaveis ────────────────────────────────────────────────
RESOURCE_GROUP="rg-rm564434-dimdim-cp5"
LOCATION="eastus"
SQL_SERVER_NAME="rm564434-dimdim-sqlsrv"
SQL_DB_NAME="dimdimdb"
SQL_ADMIN_USER="dimdimadmin"
SQL_ADMIN_PASS="DimDim@Fiap2026!"
APP_SERVICE_PLAN="rm564434-dimdim-plan"
WEB_APP_NAME="rm564434-dimdim-webapp"
APP_INSIGHTS_NAME="rm564434-dimdim-insights"
JAR_NAME="dimdim-0.0.1-SNAPSHOT.jar"

# ── Cores ────────────────────────────────────────────────────
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()   { echo -e "${GREEN}[ OK ]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERRO]${NC} $1"; }

echo ""
echo "================================================================"
echo "   DimDim CP5 - Azure Web App + SQL Database + App Insights"
echo "   RM564434 - Eduarda | FIAP 2026"
echo "================================================================"
echo ""

# ── PASSO 1: Criar Resource Group ────────────────────────────
log "Passo 1: Criando Resource Group '$RESOURCE_GROUP'..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output table
ok "Resource Group criado."

# ── PASSO 2: Criar Azure SQL Server ──────────────────────────
log "Passo 2: Criando Azure SQL Server '$SQL_SERVER_NAME'..."
az sql server create \
  --name "$SQL_SERVER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --admin-user "$SQL_ADMIN_USER" \
  --admin-password "$SQL_ADMIN_PASS" \
  --output table
ok "SQL Server criado."

# ── PASSO 3: Configurar Firewall do SQL (liberar Azure + IP local) ──
log "Passo 3: Configurando Firewall do SQL Server..."
# Liberar servicos Azure
az sql server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --server "$SQL_SERVER_NAME" \
  --name "AllowAzureServices" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0 \
  --output table

# Liberar IP atual para testes
MY_IP=$(curl -s ifconfig.me)
if [ -n "$MY_IP" ]; then
  az sql server firewall-rule create \
    --resource-group "$RESOURCE_GROUP" \
    --server "$SQL_SERVER_NAME" \
    --name "AllowMyIP" \
    --start-ip-address "$MY_IP" \
    --end-ip-address "$MY_IP" \
    --output table
  ok "IP local $MY_IP liberado no firewall."
fi
ok "Firewall configurado."

# ── PASSO 4: Criar Azure SQL Database ────────────────────────
log "Passo 4: Criando Database '$SQL_DB_NAME'..."
az sql db create \
  --resource-group "$RESOURCE_GROUP" \
  --server "$SQL_SERVER_NAME" \
  --name "$SQL_DB_NAME" \
  --service-objective "S0" \
  --output table
ok "Database '$SQL_DB_NAME' criado."

# ── PASSO 5: Criar App Service Plan (Linux) ──────────────────
log "Passo 5: Criando App Service Plan '$APP_SERVICE_PLAN'..."
az appservice plan create \
  --name "$APP_SERVICE_PLAN" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku B1 \
  --is-linux \
  --output table
ok "App Service Plan criado (Linux, B1)."

# ── PASSO 6: Criar Web App (Java 17) ─────────────────────────
log "Passo 6: Criando Web App '$WEB_APP_NAME'..."
az webapp create \
  --name "$WEB_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$APP_SERVICE_PLAN" \
  --runtime "JAVA:17-java17" \
  --output table
ok "Web App criado."

# ── PASSO 7: Criar Application Insights ──────────────────────
log "Passo 7: Criando Application Insights '$APP_INSIGHTS_NAME'..."
az monitor app-insights component create \
  --app "$APP_INSIGHTS_NAME" \
  --location "$LOCATION" \
  --resource-group "$RESOURCE_GROUP" \
  --application-type web \
  --output table

# Capturar Instrumentation Key e Connection String
INSIGHTS_KEY=$(az monitor app-insights component show \
  --app "$APP_INSIGHTS_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query instrumentationKey \
  --output tsv)

INSIGHTS_CONN=$(az monitor app-insights component show \
  --app "$APP_INSIGHTS_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query connectionString \
  --output tsv)

ok "Application Insights criado. Key: $INSIGHTS_KEY"

# ── PASSO 8: Configurar Variaveis de Ambiente no Web App ─────
# (Secrets ficam APENAS no App Settings, nunca no codigo fonte)
log "Passo 8: Configurando App Settings (variaveis de ambiente)..."

SQL_JDBC_URL="jdbc:sqlserver://${SQL_SERVER_NAME}.database.windows.net:1433;database=${SQL_DB_NAME};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30"

az webapp config appsettings set \
  --name "$WEB_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --settings \
    SPRING_PROFILES_ACTIVE=azure \
    SPRING_DATASOURCE_URL="$SQL_JDBC_URL" \
    SPRING_DATASOURCE_USERNAME="$SQL_ADMIN_USER" \
    SPRING_DATASOURCE_PASSWORD="$SQL_ADMIN_PASS" \
    SPRING_JPA_HIBERNATE_DDL_AUTO=update \
    SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.SQLServerDialect \
    APPLICATIONINSIGHTS_CONNECTION_STRING="$INSIGHTS_CONN" \
    APPINSIGHTS_INSTRUMENTATIONKEY="$INSIGHTS_KEY" \
  --output table
ok "App Settings configurados (secrets protegidos)."

# ── PASSO 9: Habilitar logging ────────────────────────────────
log "Passo 9: Habilitando logs da aplicacao..."
az webapp log config \
  --name "$WEB_APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --application-logging filesystem \
  --level information \
  --output table
ok "Logs habilitados."

# ── PASSO 10: Build e Deploy do JAR ──────────────────────────
log "Passo 10: Fazendo build do projeto e deploy..."

if [ -f "pom.xml" ]; then
  log "Executando Maven build..."
  ./mvnw clean package -DskipTests -B --no-transfer-progress 2>/dev/null || \
  mvn clean package -DskipTests -B --no-transfer-progress 2>/dev/null || \
  mvnw.cmd clean package -DskipTests -B 2>/dev/null

  JAR_PATH=$(find target -name "*.jar" -not -name "*sources*" | head -1)

  if [ -n "$JAR_PATH" ]; then
    log "Fazendo deploy do JAR: $JAR_PATH"
    az webapp deploy \
      --resource-group "$RESOURCE_GROUP" \
      --name "$WEB_APP_NAME" \
      --src-path "$JAR_PATH" \
      --type jar \
      --output table
    ok "Deploy realizado com sucesso!"
  else
    err "JAR nao encontrado em target/. Verifique o build."
  fi
else
  warn "pom.xml nao encontrado no diretorio atual."
  warn "Execute o script na raiz do projeto Java, ou faca o deploy via GitHub Actions."
fi

# ── Resumo ────────────────────────────────────────────────────
WEB_APP_URL="https://${WEB_APP_NAME}.azurewebsites.net"
SQL_FQDN="${SQL_SERVER_NAME}.database.windows.net"

echo ""
echo "================================================================"
echo -e " ${GREEN}  DimDim CP5 - DEPLOY COMPLETO!${NC}"
echo "================================================================"
echo "  Resource Group     : $RESOURCE_GROUP"
echo "  SQL Server         : $SQL_FQDN"
echo "  Database           : $SQL_DB_NAME"
echo "  Web App            : $WEB_APP_URL"
echo "  Swagger            : ${WEB_APP_URL}/swagger-ui.html"
echo "  App Insights       : $APP_INSIGHTS_NAME"
echo "  Insights Key       : $INSIGHTS_KEY"
echo "================================================================"
echo ""
warn "IMPORTANTE: Aguarde ~2 minutos para a aplicacao iniciar."
warn "Apos gravar o video, execute: ./scripts/azure-destroy-cp5.sh"
echo ""
