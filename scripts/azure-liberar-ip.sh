#!/usr/bin/env bash
# =================================================================
# Libera o IPv4 atual no firewall do Azure SQL.
# Use se trocar de rede (casa/FIAP) e o terminal do banco nao conectar.
#
# Uso (Git Bash):  bash scripts/azure-liberar-ip.sh
# =================================================================
set -Eeuo pipefail
export MSYS_NO_PATHCONV=1

# No Windows o az devolve linhas terminadas em \r (CRLF), o que quebra
# comparacoes e valores capturados no Git Bash. Toda captura passa por aqui.
az_out() { az "$@" | tr -d '\r'; }

RESOURCE_GROUP="rg-rm564434-dimdim-cp5"
SQL_SERVER="rm564434-dimdim-sqlsrv"
RULE="AllowMyIP"

MY_IP=$(curl -s -4 --max-time 10 https://api.ipify.org || true)
[[ "$MY_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "[ERRO] Nao consegui descobrir seu IPv4."; exit 1; }

ACTION=create
az sql server firewall-rule show -g "$RESOURCE_GROUP" -s "$SQL_SERVER" -n "$RULE" >/dev/null 2>&1 && ACTION=update
az sql server firewall-rule "$ACTION" -g "$RESOURCE_GROUP" -s "$SQL_SERVER" -n "$RULE" \
  --start-ip-address "$MY_IP" --end-ip-address "$MY_IP" -o none --only-show-errors
echo "[ OK ] IPv4 $MY_IP liberado no firewall do $SQL_SERVER."
