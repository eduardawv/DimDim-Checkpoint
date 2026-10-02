#!/usr/bin/env bash
# =================================================================
# CP5 - Remove TODOS os recursos criados pelo azure-setup.sh
# Rode ao final da gravacao do video para nao consumir creditos.
#
# Uso (Git Bash):  bash scripts/azure-destroy.sh
# =================================================================
set -Eeuo pipefail
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

# No Windows o az devolve linhas terminadas em \r (CRLF), o que quebra
# comparacoes e valores capturados no Git Bash. Toda captura passa por aqui.
az_out() { az "$@" | tr -d '\r'; }

RESOURCE_GROUP="rg-rm564434-dimdim-cp5"

C_OK='\033[0;32m'; C_WARN='\033[1;33m'; C_ERR='\033[0;31m'; C_OFF='\033[0m'

az account show >/dev/null 2>&1 || { echo -e "${C_ERR}[ERRO]${C_OFF} Rode az login primeiro."; exit 1; }

if [[ "$(az_out group exists -n "$RESOURCE_GROUP")" != "true" ]]; then
  echo -e "${C_OK}[ OK ]${C_OFF} Resource Group $RESOURCE_GROUP nao existe. Nada para remover."
  exit 0
fi

echo "Recursos que serao REMOVIDOS:"
az resource list -g "$RESOURCE_GROUP" --query "[].{Nome:name, Tipo:type, Regiao:location}" -o table
echo
echo -e "${C_WARN}ATENCAO:${C_OFF} esta acao apaga o banco e todos os dados."
read -r -p "Digite o nome do resource group para confirmar ($RESOURCE_GROUP): " CONFIRM
[[ "$CONFIRM" == "$RESOURCE_GROUP" ]] || { echo "Cancelado."; exit 1; }

# Log Analytics fica 14 dias em "soft delete" e bloqueia recriar com o mesmo
# nome em outra regiao. Remocao definitiva evita esse problema.
for ws in $(az_out monitor log-analytics workspace list -g "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null || true); do
  echo "Removendo definitivamente o workspace $ws..."
  az monitor log-analytics workspace delete -g "$RESOURCE_GROUP" -n "$ws" --force true --yes -o none --only-show-errors || true
done

echo "Removendo o Resource Group $RESOURCE_GROUP (leva de 3 a 10 minutos)..."
az group delete -n "$RESOURCE_GROUP" --yes --only-show-errors

if [[ "$(az_out group exists -n "$RESOURCE_GROUP")" == "false" ]]; then
  echo -e "${C_OK}[ OK ]${C_OFF} Todos os recursos foram removidos."
else
  echo -e "${C_WARN}[AVISO]${C_OFF} O grupo ainda aparece. Confira no portal em alguns minutos."
fi
rm -f .appsettings.tmp.json
