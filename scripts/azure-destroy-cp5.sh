#!/bin/bash
# =================================================================
# DimDim CP5 - Remocao de TODOS os recursos Azure
# Execute APOS gravar o video! Tire print como evidencia.
# =================================================================

RESOURCE_GROUP="rg-rm564434-dimdim-cp5"

echo "================================================================"
echo "  ⚠️   REMOCAO DE RECURSOS AZURE - DimDim CP5"
echo "================================================================"
echo ""
echo "  Serao removidos TODOS os recursos do grupo:"
echo "  → $RESOURCE_GROUP"
echo "  (Web App, SQL Server, SQL Database, App Insights, App Service Plan)"
echo ""
read -p "  Confirma a remocao? (s/N): " CONFIRM

if [[ "$CONFIRM" == "s" || "$CONFIRM" == "S" ]]; then
  echo ""
  echo ">>> Deletando Resource Group '$RESOURCE_GROUP'..."
  az group delete \
    --name "$RESOURCE_GROUP" \
    --yes \
    --no-wait
  echo ""
  echo "  Remocao solicitada com sucesso!"
  echo "  Aguarde ~3 minutos para remocao completa."
  echo ""
  echo "================================================================"
  echo "  TIRE PRINT DESTA TELA COMO EVIDENCIA PARA ENTREGA!"
  echo "  Confirme em: https://portal.azure.com → Resource Groups"
  echo "================================================================"
else
  echo "Remocao cancelada."
fi
