#!/usr/bin/env bash
# =================================================================
# CP5 - DevOps Tools & Cloud Computing (FIAP 2026)
# Projeto: CLYVO Predict (codigo Java da Sprint 4)
#
# Cria TODA a infraestrutura no Azure e faz o deploy da aplicacao:
#   1. Registro dos resource providers da assinatura
#   2. Resource Group
#   3. Azure SQL Server (testa as regioes permitidas ate uma aceitar)
#   4. Firewall do SQL (servicos Azure + seu IPv4)
#   5. Azure SQL Database
#   6. App Service Plan (Linux) + Web App (Java 21)
#   7. Log Analytics Workspace + Application Insights
#   8. App Settings (segredos como variaveis de ambiente) + logs
#   9. Chaves JWT (geradas localmente, nunca commitadas)
#  10. Build do JAR + deploy (az webapp deploy) + teste de saude
#
# Uso (Git Bash, na raiz do repositorio):
#   az login
#   bash scripts/azure-setup.sh
#
# Pode ser executado de novo: o que ja existe e reaproveitado.
# A senha do banco e pedida na hora (nao fica em nenhum arquivo).
# =================================================================
set -Eeuo pipefail

# Git Bash (Windows) converte argumentos que comecam com "/" em caminhos
# do Windows e corrompe IDs de recurso do Azure. Isto desliga a conversao.
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

# No Windows o az devolve linhas terminadas em \r (CRLF), o que quebra
# comparacoes e valores capturados no Git Bash. Toda captura passa por aqui.
az_out() { az "$@" | tr -d '\r'; }

# ------------------------- Configuracao -------------------------
RM="rm564434"
RESOURCE_GROUP="rg-${RM}-dimdim-cp5"
SQL_SERVER="${RM}-dimdim-sqlsrv"
SQL_DB="dimdimdb"
SQL_ADMIN_USER="dimdimadmin"
APP_PLAN="${RM}-dimdim-plan"
WEB_APP="${RM}-dimdim-webapp"
LOG_WORKSPACE="${RM}-dimdim-logs"
APP_INSIGHTS="${RM}-dimdim-insights"
JAVA_RUNTIME="JAVA:21-java21"
PLAN_SKU="B1"
DB_SKU="Basic"

# Regioes liberadas pela policy da assinatura FIAP (Allowed resource
# deployment regions). A primeira que aceitar o Azure SQL e usada para
# todos os recursos. Para forcar uma regiao: AZ_REGION=eastus2 bash scripts/azure-setup.sh
REGIONS=(mexicocentral eastus2 eastus southcentralus southafricanorth)
if [[ -n "${AZ_REGION:-}" ]]; then REGIONS=("$AZ_REGION"); fi

TMP_SETTINGS=".appsettings.tmp.json"
KEY_DIR="src/main/resources/keys"

# --------------------------- Helpers ----------------------------
C_INFO='\033[0;36m'; C_OK='\033[0;32m'; C_WARN='\033[1;33m'; C_ERR='\033[0;31m'; C_OFF='\033[0m'
step() { echo; echo -e "${C_INFO}==> $*${C_OFF}"; }
ok()   { echo -e "${C_OK}[ OK ]${C_OFF} $*"; }
warn() { echo -e "${C_WARN}[AVISO]${C_OFF} $*" >&2; }
fail() { echo -e "${C_ERR}[ERRO]${C_OFF} $*" >&2; exit 1; }

trap 'echo -e "${C_ERR}[ERRO]${C_OFF} Falha na linha $LINENO: $BASH_COMMAND" >&2' ERR
trap 'rm -f "$TMP_SETTINGS"' EXIT

# Retorna sucesso se o comando "show" encontrar o recurso (id nao vazio)
exists() { [[ -n "$("$@" --query id -o tsv 2>/dev/null || true)" ]]; }

# Executa "create_<recurso> <regiao>" na regiao principal e, se falhar,
# tenta as demais regioes permitidas. Imprime a regiao usada.
with_region_fallback() {
  local label=$1 fn=$2 region out
  local ordered=("$LOCATION")
  for region in "${REGIONS[@]}"; do [[ "$region" != "$LOCATION" ]] && ordered+=("$region"); done
  for region in "${ordered[@]}"; do
    if out=$("$fn" "$region" 2>&1); then echo "$region"; return 0; fi
    warn "$label nao foi criado em $region: $(echo "$out" | grep -m1 -iE 'error|message|code' | cut -c1-160)"
  done
  echo "$out" >&2
  return 1
}

# --------------------------- Pre-checks -------------------------
step "Verificando pre-requisitos"
[[ -f pom.xml && -d src/main/java ]] || fail "Execute na raiz do repositorio (pasta onde esta o pom.xml)."
command -v az >/dev/null 2>&1      || fail "Azure CLI nao encontrado. Instale com: winget install Microsoft.AzureCLI"
command -v openssl >/dev/null 2>&1 || fail "openssl nao encontrado (ele vem com o Git Bash)."
command -v curl >/dev/null 2>&1    || fail "curl nao encontrado."
command -v java >/dev/null 2>&1    || fail "Java nao encontrado. Instale o JDK 21: winget install EclipseAdoptium.Temurin.21.JDK"
java_major() { "$1" -version 2>&1 | grep -m1 'version "' | sed -E 's/.*version "([0-9]+).*/\1/'; }
JAVA_MAJOR=$(java_major java || true)
# O ./mvnw usa o JAVA_HOME quando ele existe, entao ele tambem precisa ser 21+
if [[ -n "${JAVA_HOME:-}" ]]; then
  JH_UNIX=$(cygpath -u "$JAVA_HOME" 2>/dev/null || echo "$JAVA_HOME")
  JH_MAJOR=$(java_major "$JH_UNIX/bin/java" || true)
  if [[ "${JH_MAJOR:-0}" -ge 21 ]]; then
    JAVA_MAJOR=$JH_MAJOR
  elif [[ "${JAVA_MAJOR:-0}" -ge 21 ]]; then
    warn "JAVA_HOME aponta para Java ${JH_MAJOR:-?}. Nesta execucao vou usar o Java $JAVA_MAJOR do PATH."
    unset JAVA_HOME
  else
    fail "JAVA_HOME aponta para Java ${JH_MAJOR:-?}. Instale o JDK 21 (winget install EclipseAdoptium.Temurin.21.JDK) e ajuste o JAVA_HOME."
  fi
fi
[[ "${JAVA_MAJOR:-0}" -ge 21 ]] || fail "O projeto exige JDK 21 (encontrado: ${JAVA_MAJOR:-?}). Instale: winget install EclipseAdoptium.Temurin.21.JDK e reabra o Git Bash."
az account show >/dev/null 2>&1 || fail "Voce nao esta logado. Rode: az login"
ok "Assinatura: $(az_out account show --query name -o tsv) | Java $JAVA_MAJOR"

# ---------------------- Senha do Azure SQL ----------------------
if [[ -z "${SQL_ADMIN_PASSWORD:-}" ]]; then
  echo "Defina a senha do administrador do Azure SQL."
  echo "Ela NAO e salva em nenhum arquivo: vai direto para o Azure (App Settings)."
  echo "Regras: 12+ caracteres, comecando com letra ou numero, com MAIUSCULA, minuscula, numero e um simbolo entre @ # ! _ - ."
  read -r -s -p "Senha: " SQL_ADMIN_PASSWORD; echo
  read -r -s -p "Confirme a senha: " SQL_PASS_CONFIRM; echo
  [[ "$SQL_ADMIN_PASSWORD" == "$SQL_PASS_CONFIRM" ]] || fail "As senhas nao conferem."
fi
RE_ALLOWED='^[A-Za-z0-9][A-Za-z0-9@#!_.-]+$'; RE_UP='[A-Z]'; RE_LOW='[a-z]'; RE_NUM='[0-9]'; RE_SYM='[@#!_.-]'
[[ ${#SQL_ADMIN_PASSWORD} -ge 12 ]]        || fail "Senha precisa ter 12 ou mais caracteres."
[[ $SQL_ADMIN_PASSWORD =~ $RE_ALLOWED ]]   || fail "Comece com letra ou numero e use apenas letras, numeros e os simbolos @ # ! _ - . (outros simbolos quebram o az no Windows)."
[[ $SQL_ADMIN_PASSWORD =~ $RE_UP && $SQL_ADMIN_PASSWORD =~ $RE_LOW && $SQL_ADMIN_PASSWORD =~ $RE_NUM && $SQL_ADMIN_PASSWORD =~ $RE_SYM ]] \
  || fail "Senha precisa ter maiuscula, minuscula, numero e simbolo."
[[ "${SQL_ADMIN_PASSWORD,,}" != *"${SQL_ADMIN_USER,,}"* ]] || fail "A senha nao pode conter o nome do usuario ($SQL_ADMIN_USER)."
ok "Senha valida (nao sera exibida)."

# --------------------- 1. Resource providers --------------------
step "1/10 Registrando resource providers (necessario em assinaturas novas)"
for ns in Microsoft.Sql Microsoft.Web Microsoft.Insights Microsoft.OperationalInsights Microsoft.AlertsManagement; do
  state=$(az_out provider show -n "$ns" --query registrationState -o tsv 2>/dev/null || echo "NotRegistered")
  if [[ "$state" != "Registered" ]]; then
    echo "    Registrando $ns (pode levar alguns minutos)..."
    az provider register -n "$ns" --wait --only-show-errors
  fi
  ok "$ns"
done

# Instala a extensao do Application Insights sem perguntar (Y/n)
az config set extension.use_dynamic_install=yes_without_prompt --only-show-errors >/dev/null 2>&1 || true
az config set extension.dynamic_install_allow_preview=false --only-show-errors >/dev/null 2>&1 || true
az extension add --name application-insights --upgrade --only-show-errors >/dev/null 2>&1 \
  || warn "Nao consegui instalar/atualizar a extensao application-insights agora; o az tentara de novo no passo 7."

# ------------------------ 2. Resource Group ---------------------
step "2/10 Resource Group $RESOURCE_GROUP"
if [[ "$(az_out group exists -n "$RESOURCE_GROUP")" == "true" ]]; then
  ok "Ja existe, reaproveitando."
else
  az group create -n "$RESOURCE_GROUP" -l "${REGIONS[0]}" -o none --only-show-errors
  ok "Criado."
fi

# ------------------------ 3. Azure SQL Server -------------------
step "3/10 Azure SQL Server $SQL_SERVER"
LOCATION=$(az_out sql server show -g "$RESOURCE_GROUP" -n "$SQL_SERVER" --query location -o tsv 2>/dev/null || true)
if [[ -n "$LOCATION" ]]; then
  # Garante que a senha do servidor e a mesma que vai para as App Settings
  az sql server update -g "$RESOURCE_GROUP" -n "$SQL_SERVER" --admin-password "$SQL_ADMIN_PASSWORD" -o none --only-show-errors
  ok "Ja existe em $LOCATION (senha do admin sincronizada)."
else
  for region in "${REGIONS[@]}"; do
    echo "    Tentando a regiao $region..."
    if out=$(az_out sql server create -g "$RESOURCE_GROUP" -n "$SQL_SERVER" -l "$region" \
              --admin-user "$SQL_ADMIN_USER" --admin-password "$SQL_ADMIN_PASSWORD" \
              --minimal-tls-version 1.2 -o none --only-show-errors 2>&1); then
      LOCATION="$region"; break
    fi
    if grep -qiE "RegionDoesNotAllowProvisioning|RequestDisallowedByAzure|not accepting creation|disallowed by Azure|already exists in location|ProvisioningDisabled" <<<"$out"; then
      warn "$region indisponivel para Azure SQL agora. Limpando tentativa e indo para a proxima..."
      az sql server delete -g "$RESOURCE_GROUP" -n "$SQL_SERVER" --yes -o none --only-show-errors >/dev/null 2>&1 || true
      sleep 15
      continue
    fi
    echo "$out" >&2
    if grep -qiE "NameAlreadyExists|already exists" <<<"$out"; then
      fail "O nome '$SQL_SERVER' ja esta em uso no Azure. Altere a variavel RM/SQL_SERVER no topo do script."
    fi
    fail "Erro inesperado ao criar o SQL Server (mensagem acima)."
  done
  [[ -n "$LOCATION" ]] || fail "Nenhuma regiao permitida aceitou o Azure SQL agora. Aguarde alguns minutos e rode o script de novo."
  ok "Criado em $LOCATION."
fi
echo "    Regiao usada para os demais recursos: $LOCATION"

# ------------------------ 4. Firewall do SQL --------------------
step "4/10 Firewall do Azure SQL"
fw_rule() {
  local name=$1 ip_start=$2 ip_end=$3 action=create
  if az sql server firewall-rule show -g "$RESOURCE_GROUP" -s "$SQL_SERVER" -n "$name" >/dev/null 2>&1; then action=update; fi
  az sql server firewall-rule "$action" -g "$RESOURCE_GROUP" -s "$SQL_SERVER" -n "$name" \
    --start-ip-address "$ip_start" --end-ip-address "$ip_end" -o none --only-show-errors
}
fw_rule "AllowAzureServices" 0.0.0.0 0.0.0.0
ok "Servicos do Azure (Web App) liberados."
MY_IP=$(curl -s -4 --max-time 10 https://api.ipify.org || true)
if [[ "$MY_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  fw_rule "AllowMyIP" "$MY_IP" "$MY_IP"
  ok "Seu IPv4 $MY_IP liberado (para o terminal de consultas / Query Editor)."
else
  warn "Nao detectei seu IPv4. Depois rode: bash scripts/azure-liberar-ip.sh"
fi

# ------------------------ 5. SQL Database -----------------------
step "5/10 Azure SQL Database $SQL_DB ($DB_SKU)"
if exists az sql db show -g "$RESOURCE_GROUP" -s "$SQL_SERVER" -n "$SQL_DB"; then
  ok "Ja existe, reaproveitando."
else
  # Backup "Local": regioes sem par (ex.: Mexico Central) nao aceitam backup geo-redundante
  az sql db create -g "$RESOURCE_GROUP" -s "$SQL_SERVER" -n "$SQL_DB" \
    --service-objective "$DB_SKU" --backup-storage-redundancy Local -o none --only-show-errors
  ok "Criado."
fi

# ------------------ 6. App Service Plan + Web App ---------------
step "6/10 App Service Plan $APP_PLAN ($PLAN_SKU Linux) e Web App $WEB_APP"
create_plan() {
  az appservice plan create -g "$RESOURCE_GROUP" -n "$APP_PLAN" -l "$1" --sku "$PLAN_SKU" --is-linux -o none --only-show-errors
}
if exists az appservice plan show -g "$RESOURCE_GROUP" -n "$APP_PLAN"; then
  ok "Plano ja existe, reaproveitando."
else
  PLAN_REGION=$(with_region_fallback "App Service Plan" create_plan) || fail "Nao foi possivel criar o App Service Plan."
  ok "Plano criado em $PLAN_REGION."
fi

if exists az webapp show -g "$RESOURCE_GROUP" -n "$WEB_APP"; then
  ok "Web App ja existe, reaproveitando."
else
  if ! out=$(az_out webapp create -g "$RESOURCE_GROUP" -n "$WEB_APP" -p "$APP_PLAN" --runtime "$JAVA_RUNTIME" -o none --only-show-errors 2>&1); then
    echo "$out" >&2
    grep -qiE "already exists|not available" <<<"$out" && fail "O nome '$WEB_APP' ja esta em uso no Azure. Altere RM/WEB_APP no topo do script."
    fail "Erro ao criar o Web App (mensagem acima)."
  fi
  ok "Web App criado (runtime $JAVA_RUNTIME)."
fi
az webapp update -g "$RESOURCE_GROUP" -n "$WEB_APP" --https-only true -o none --only-show-errors
az webapp config set -g "$RESOURCE_GROUP" -n "$WEB_APP" --always-on true --ftps-state Disabled --min-tls-version 1.2 -o none --only-show-errors
ok "HTTPS obrigatorio, Always On, FTP desabilitado, TLS 1.2."

# --------------- 7. Log Analytics + Application Insights --------
step "7/10 Log Analytics ($LOG_WORKSPACE) e Application Insights ($APP_INSIGHTS)"
create_workspace() {
  az monitor log-analytics workspace create -g "$RESOURCE_GROUP" -n "$LOG_WORKSPACE" -l "$1" --retention-time 30 -o none --only-show-errors
}
if exists az monitor log-analytics workspace show -g "$RESOURCE_GROUP" -n "$LOG_WORKSPACE"; then
  ok "Workspace ja existe, reaproveitando."
else
  WS_REGION=$(with_region_fallback "Log Analytics" create_workspace) || fail "Nao foi possivel criar o Log Analytics Workspace."
  ok "Workspace criado em $WS_REGION."
fi
WS_ID=$(az_out monitor log-analytics workspace show -g "$RESOURCE_GROUP" -n "$LOG_WORKSPACE" --query id -o tsv)

create_insights() {
  az monitor app-insights component create -g "$RESOURCE_GROUP" --app "$APP_INSIGHTS" -l "$1" \
    --kind web --application-type web --workspace "$WS_ID" -o none --only-show-errors
}
if exists az monitor app-insights component show -g "$RESOURCE_GROUP" --app "$APP_INSIGHTS"; then
  ok "Application Insights ja existe, reaproveitando."
else
  AI_REGION=$(with_region_fallback "Application Insights" create_insights) || fail "Nao foi possivel criar o Application Insights."
  ok "Application Insights criado em $AI_REGION."
fi
AI_CONN=$(az_out monitor app-insights component show -g "$RESOURCE_GROUP" --app "$APP_INSIGHTS" --query connectionString -o tsv)
[[ -n "$AI_CONN" ]] || fail "Connection string do Application Insights vazia."

# ------------------ 8. App Settings + logs ----------------------
step "8/10 App Settings do Web App (segredos como variaveis de ambiente)"
JDBC_URL="jdbc:sqlserver://${SQL_SERVER}.database.windows.net:1433;database=${SQL_DB};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30"
# Arquivo temporario (ignorado pelo git e apagado ao final) para evitar
# problemas de aspas/ponto-e-virgula do az no Windows.
cat > "$TMP_SETTINGS" <<EOF
[
  {"name": "SPRING_PROFILES_ACTIVE", "value": "azure", "slotSetting": false},
  {"name": "SPRING_DATASOURCE_URL", "value": "${JDBC_URL}", "slotSetting": false},
  {"name": "SPRING_DATASOURCE_USERNAME", "value": "${SQL_ADMIN_USER}", "slotSetting": false},
  {"name": "SPRING_DATASOURCE_PASSWORD", "value": "${SQL_ADMIN_PASSWORD}", "slotSetting": false},
  {"name": "APPLICATIONINSIGHTS_CONNECTION_STRING", "value": "${AI_CONN}", "slotSetting": false},
  {"name": "ApplicationInsightsAgent_EXTENSION_VERSION", "value": "~3", "slotSetting": false},
  {"name": "APPLICATIONINSIGHTS_ROLE_NAME", "value": "clyvo-predict-api", "slotSetting": false},
  {"name": "WEBSITES_CONTAINER_START_TIME_LIMIT", "value": "600", "slotSetting": false}
]
EOF
az webapp config appsettings set -g "$RESOURCE_GROUP" -n "$WEB_APP" --settings "@${TMP_SETTINGS}" -o none --only-show-errors
rm -f "$TMP_SETTINGS"
ok "App Settings gravadas: SPRING_PROFILES_ACTIVE, SPRING_DATASOURCE_* , APPLICATIONINSIGHTS_* (valores ocultos)."

az webapp log config -g "$RESOURCE_GROUP" -n "$WEB_APP" --application-logging filesystem \
  --docker-container-logging filesystem --level information -o none --only-show-errors
ok "Logs da aplicacao habilitados (az webapp log tail)."

# -------------------- 9. Chaves JWT (RSA) -----------------------
step "9/10 Chaves JWT (RSA 2048)"
mkdir -p "$KEY_DIR"
if [[ ! -s "$KEY_DIR/private_key.pem" ]]; then
  openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$KEY_DIR/private_key.pem" 2>/dev/null
  ok "Chave privada gerada em $KEY_DIR/private_key.pem (ignorada pelo git)."
elif ! grep -q "BEGIN PRIVATE KEY" "$KEY_DIR/private_key.pem"; then
  # A aplicacao le PKCS#8; converte chaves no formato antigo (PKCS#1)
  openssl pkcs8 -topk8 -nocrypt -in "$KEY_DIR/private_key.pem" -out "$KEY_DIR/private_key.pem.tmp"
  mv "$KEY_DIR/private_key.pem.tmp" "$KEY_DIR/private_key.pem"
  ok "Chave privada convertida para PKCS#8."
else
  ok "Chave privada local encontrada."
fi
openssl pkey -in "$KEY_DIR/private_key.pem" -pubout -out "$KEY_DIR/public_key.pem.tmp" 2>/dev/null
if cmp -s "$KEY_DIR/public_key.pem.tmp" "$KEY_DIR/public_key.pem"; then
  rm -f "$KEY_DIR/public_key.pem.tmp"
  ok "Chave publica confere com a privada."
else
  mv "$KEY_DIR/public_key.pem.tmp" "$KEY_DIR/public_key.pem"
  ok "public_key.pem atualizada para combinar com a chave privada (chave publica nao e segredo)."
fi

# ------------------- 10. Build + Deploy -------------------------
step "10/10 Build (Maven) e deploy no Web App"
chmod +x mvnw 2>/dev/null || true
if ! ./mvnw -B -q -DskipTests clean package; then
  # O curl do Git Bash ignora o proxy/certificados do Windows. O mvnw.cmd baixa
  # o Maven pelo PowerShell, que usa as configuracoes de rede do Windows.
  if command -v cmd.exe >/dev/null 2>&1 && [[ -f mvnw.cmd ]]; then
    warn "O mvnw do Git Bash falhou. Tentando pelo mvnw.cmd (rede do Windows)..."
    cmd.exe /c "mvnw.cmd -B -q -DskipTests clean package" \
      || fail "Build falhou tambem pelo mvnw.cmd. Rode no PowerShell: .\\mvnw.cmd -B -DskipTests package  e envie o erro."
  else
    fail "Build falhou. Rode './mvnw -B -DskipTests package' para ver o erro completo."
  fi
fi
JAR_PATH=$(ls target/*.jar 2>/dev/null | head -1 || true)
[[ -n "$JAR_PATH" ]] || fail "JAR nao encontrado em target/."
ok "Build concluido: $JAR_PATH"

echo "    Enviando o JAR (az webapp deploy). Isso leva de 2 a 5 minutos..."
if az webapp deploy -g "$RESOURCE_GROUP" -n "$WEB_APP" --src-path "$JAR_PATH" --type jar --restart true -o none --only-show-errors; then
  ok "Deploy enviado."
else
  warn "O az webapp deploy retornou erro (pode ser so demora na inicializacao). Conferindo se a aplicacao subiu..."
fi

APP_URL="https://${WEB_APP}.azurewebsites.net"
echo "    Aguardando a aplicacao responder em $APP_URL ..."
HEALTHY=false
for _ in $(seq 1 36); do
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 20 "$APP_URL/v3/api-docs" || true)
  if [[ "$code" == "200" ]]; then HEALTHY=true; break; fi
  sleep 10
done
if [[ "$HEALTHY" == "true" ]]; then
  ok "Aplicacao no ar."
else
  warn "A aplicacao nao respondeu 200 em 6 minutos. Veja o log de inicializacao com:"
  echo "    az webapp log tail -g $RESOURCE_GROUP -n $WEB_APP"
  exit 1
fi

# --------------------------- Resumo -----------------------------
SUB_ID=$(az_out account show --query id -o tsv)
echo
echo -e "${C_OK}================================================================${C_OFF}"
echo -e "${C_OK}  CLYVO Predict - CP5 - infraestrutura e deploy concluidos${C_OFF}"
echo -e "${C_OK}================================================================${C_OFF}"
echo "  Resource Group : $RESOURCE_GROUP ($LOCATION)"
echo "  Azure SQL      : ${SQL_SERVER}.database.windows.net / $SQL_DB (usuario $SQL_ADMIN_USER)"
echo "  Web App        : $APP_URL"
echo "  Swagger        : $APP_URL/swagger-ui.html"
echo "  App Insights   : https://portal.azure.com/#resource/subscriptions/${SUB_ID}/resourceGroups/${RESOURCE_GROUP}/providers/microsoft.insights/components/${APP_INSIGHTS}/overview"
echo
echo "  Proximos passos (README > How To):"
echo "    Terminal 2 (banco) : bash scripts/db-terminal.sh"
echo "    Terminal 1 (API)   : bash scripts/crud-demo.sh"
echo "    Ao final           : bash scripts/azure-destroy.sh"
echo
