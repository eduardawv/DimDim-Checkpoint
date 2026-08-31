#!/bin/bash
# Projeto DimDim — Remover todos os recursos Azure
RESOURCE_GROUP="rm564434-dimdim-rg"
echo "Deletando Resource Group '$RESOURCE_GROUP'..."
az group delete --name "$RESOURCE_GROUP" --yes --no-wait
echo "✅ Remoção solicitada. Verifique em portal.azure.com"
