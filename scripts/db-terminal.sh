#!/usr/bin/env bash
# =================================================================
# CP5 - Terminal EXCLUSIVO para consultas no Azure SQL
# Deixe esta janela do Git Bash aberta durante o video, ao lado do
# terminal que executa o CRUD (scripts/crud-demo.sh).
#
# Pre-requisito (uma vez):  winget install sqlcmd   (e reabra o Git Bash)
# Uso:                      bash scripts/db-terminal.sh
# =================================================================
set -uo pipefail
export MSYS_NO_PATHCONV=1

SERVER="rm564434-dimdim-sqlsrv.database.windows.net"
DATABASE="dimdimdb"
DB_USER="dimdimadmin"

C_HEAD='\033[1;33m'; C_ERR='\033[0;31m'; C_OFF='\033[0m'

if ! command -v sqlcmd >/dev/null 2>&1; then
  echo -e "${C_ERR}sqlcmd nao encontrado.${C_OFF} Instale com: winget install sqlcmd  (depois feche e reabra o Git Bash)"
  echo "Alternativa sem instalar: Portal Azure > SQL database > Query editor, usando scripts/consultas.sql"
  exit 1
fi

# A senha fica so na memoria desta sessao (variavel lida pelo sqlcmd)
if [[ -z "${SQLCMDPASSWORD:-}" ]]; then
  read -r -s -p "Senha do admin do Azure SQL ($DB_USER): " SQLCMDPASSWORD; echo
fi
export SQLCMDPASSWORD

run_sql() {
  local title=$1 sql=$2
  echo
  echo -e "${C_HEAD}>> $title${C_OFF}"
  echo "   $sql"
  echo
  if ! sqlcmd -S "$SERVER" -d "$DATABASE" -U "$DB_USER" -W -s "|" -Q "SET NOCOUNT ON; $sql"; then
    echo -e "${C_ERR}Falha na consulta.${C_OFF} Se a mensagem citar o firewall/IP, rode em outro terminal: bash scripts/azure-liberar-ip.sh"
  fi
}

Q_TUTOR="SELECT id, nome, email, telefone, perfil, LEFT(senha, 20) + '...' AS senha_bcrypt FROM tb_tutor ORDER BY id;"
Q_PET="SELECT id, nome, especie, raca, idade, peso, health_score, tutor_id FROM tb_pet ORDER BY id;"
Q_JOIN="SELECT t.id AS tutor_id, t.nome AS tutor, t.telefone, p.id AS pet_id, p.nome AS pet, p.especie, p.raca, p.idade, p.peso FROM tb_tutor t LEFT JOIN tb_pet p ON p.tutor_id = t.id ORDER BY t.id, p.id;"
Q_COUNT="SELECT 'tb_tutor' AS tabela, COUNT(*) AS linhas FROM tb_tutor UNION ALL SELECT 'tb_pet', COUNT(*) FROM tb_pet UNION ALL SELECT 'tb_evento_saude', COUNT(*) FROM tb_evento_saude UNION ALL SELECT 'tb_veterinario', COUNT(*) FROM tb_veterinario;"
Q_TABLES="SELECT TABLE_NAME AS tabela, COLUMN_NAME AS coluna, DATA_TYPE AS tipo, CHARACTER_MAXIMUM_LENGTH AS tamanho, IS_NULLABLE AS aceita_nulo FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME IN ('tb_tutor','tb_pet') ORDER BY TABLE_NAME, ORDINAL_POSITION;"
Q_FLYWAY="SELECT installed_rank, version, description, script, success, installed_on FROM flyway_schema_history ORDER BY installed_rank;"
Q_CLEAN="DELETE FROM tb_evento_saude; DELETE FROM tb_pet; DELETE FROM tb_tutor; DBCC CHECKIDENT ('tb_pet', RESEED, 0); DBCC CHECKIDENT ('tb_tutor', RESEED, 0); SELECT 'dados apagados' AS status;"

while true; do
  echo
  echo "================ TERMINAL DO BANCO - $DATABASE ================"
  echo "  1) TB_TUTOR            4) Contagem de linhas por tabela"
  echo "  2) TB_PET              5) Estrutura das tabelas (DDL aplicada)"
  echo "  3) TUTOR x PET (JOIN)  6) Historico do Flyway (migrations)"
  echo "  7) Consulta livre      9) Limpar dados da demo (para regravar)"
  echo "  0) Sair"
  read -r -p "Opcao: " opt
  case "$opt" in
    1) run_sql "TB_TUTOR" "$Q_TUTOR" ;;
    2) run_sql "TB_PET" "$Q_PET" ;;
    3) run_sql "TUTOR x PET" "$Q_JOIN" ;;
    4) run_sql "Contagem por tabela" "$Q_COUNT" ;;
    5) run_sql "Estrutura de TB_TUTOR e TB_PET" "$Q_TABLES" ;;
    6) run_sql "Flyway" "$Q_FLYWAY" ;;
    7) read -r -p "SQL: " custom; [[ -n "$custom" ]] && run_sql "Consulta livre" "$custom" ;;
    9) read -r -p "Apagar TODOS os tutores e pets? Digite APAGAR para confirmar: " c
       [[ "$c" == "APAGAR" ]] && run_sql "Limpeza" "$Q_CLEAN" || echo "Cancelado." ;;
    0) exit 0 ;;
    *) echo "Opcao invalida." ;;
  esac
done
