#!/usr/bin/env bash
# =================================================================
# CP5 - Demonstracao guiada do CRUD (roteiro do video)
#
# Executa POST, GET, PUT e DELETE nas tabelas TB_TUTOR e TB_PET usando
# os arquivos da pasta json/ e PAUSA depois de cada operacao para voce
# mostrar o resultado no terminal do banco (scripts/db-terminal.sh).
#
# Ao final ficam 2 linhas com conteudo significativo em cada tabela:
#   TB_TUTOR: Ana (atualizada) e Bruno   | Carla foi criada e excluida
#   TB_PET  : Thor (atualizado) e Mel    | Luna foi criada e excluida
#
# Uso (Git Bash, na raiz do repositorio):
#   bash scripts/crud-demo.sh
#   bash scripts/crud-demo.sh https://outra-url.azurewebsites.net
# =================================================================
set -uo pipefail

BASE_URL="${1:-https://rm564434-dimdim-webapp.azurewebsites.net}"
BASE_URL="${BASE_URL%/}"
JSON_DIR="json"

C_HEAD='\033[1;35m'; C_CMD='\033[0;36m'; C_DB='\033[1;33m'; C_OK='\033[0;32m'; C_ERR='\033[0;31m'; C_OFF='\033[0m'

[[ -d "$JSON_DIR" ]] || { echo "Execute na raiz do repositorio (onde esta a pasta json/)."; exit 1; }

# JSON formatado se houver Python; senao, mostra cru
PY=""
for c in python3 python py; do
  if command -v "$c" >/dev/null 2>&1 && "$c" -c "import json" >/dev/null 2>&1; then PY="$c"; break; fi
done
pretty() {
  local body; body=$(cat)
  if [[ -z "$body" ]]; then echo "(sem corpo)"; return; fi
  if [[ -n "$PY" ]] && printf '%s' "$body" | "$PY" -m json.tool 2>/dev/null; then return; fi
  printf '%s\n' "$body"
}

BODY=""; STATUS=""
# call METODO CAMINHO [TOKEN] [ARQUIVO_JSON]  -> preenche BODY e STATUS
call() {
  local method=$1 path=$2 token=${3:-} file=${4:-}
  local args=(-s -X "$method" "$BASE_URL$path" -w $'\n%{http_code}' --max-time 90)
  local shown="curl -X $method $BASE_URL$path"
  if [[ -n "$token" ]]; then args+=(-H "Authorization: Bearer $token"); shown+=' -H "Authorization: Bearer <token>"'; fi
  if [[ -n "$file" ]]; then args+=(-H "Content-Type: application/json" --data-binary "@$JSON_DIR/$file"); shown+=" -d @json/$file"; fi
  echo -e "${C_CMD}\$ ${shown}${C_OFF}"
  if [[ -n "$file" ]]; then echo "Corpo enviado (json/$file):"; cat "$JSON_DIR/$file"; echo; fi
  local resp; resp=$(curl "${args[@]}") || resp=""
  if [[ "$resp" == *$'\n'* ]]; then STATUS=${resp##*$'\n'}; BODY=${resp%$'\n'*}; else STATUS=$resp; BODY=""; fi
  echo "Resposta HTTP ${STATUS:-sem resposta}:"
  printf '%s' "$BODY" | pretty
}

expect_status() {
  local want=$1
  if [[ "$STATUS" == "$want" ]]; then echo -e "${C_OK}OK (HTTP $STATUS)${C_OFF}"; return 0; fi
  echo -e "${C_ERR}Esperado HTTP $want, recebido HTTP ${STATUS:-sem resposta}.${C_OFF}"
  if [[ "$BODY" == *"cadastrado"* ]]; then
    echo "Dica: os dados da demo ja existem. No terminal do banco use a opcao 9 (limpar dados) e rode de novo."
  fi
  read -r -p "Continuar mesmo assim? (s/N) " answer
  [[ "$answer" =~ ^[sS]$ ]] || exit 1
}

pause_db() {
  echo
  echo -e "${C_DB}>> TERMINAL DO BANCO: $1${C_OFF}"
  read -r -p "   Mostre o resultado e pressione ENTER para continuar..." _
}

header() { echo; echo -e "${C_HEAD}================ $* ================${C_OFF}"; }

json_id()    { grep -o '"id":[0-9]*' <<<"$BODY" | head -1 | cut -d: -f2; }
json_token() { grep -o '"token":"[^"]*"' <<<"$BODY" | head -1 | cut -d'"' -f4; }

# ------------------------------------------------------------------
header "Verificando a API em $BASE_URL"
code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 60 "$BASE_URL/v3/api-docs" || true)
if [[ "$code" != "200" ]]; then
  echo -e "${C_ERR}A API nao respondeu (HTTP ${code:-sem resposta}). Rode o azure-setup.sh e aguarde a aplicacao subir.${C_OFF}"
  exit 1
fi
echo -e "${C_OK}API no ar. Swagger: $BASE_URL/swagger-ui.html${C_OFF}"

# ========================= TABELA TB_TUTOR =========================
header "TB_TUTOR - CREATE (POST /api/tutores) - 3 tutores"
call POST /api/tutores "" tutor-post-1.json; expect_status 201; TUTOR_ANA=$(json_id)
pause_db "opcao 1 (TB_TUTOR) - Ana inserida com senha criptografada (BCrypt)"
call POST /api/tutores "" tutor-post-2.json; expect_status 201; TUTOR_BRUNO=$(json_id)
call POST /api/tutores "" tutor-post-3.json; expect_status 201; TUTOR_CARLA=$(json_id)
pause_db "opcao 1 (TB_TUTOR) - agora com Ana, Bruno e Carla"

header "LOGIN (POST /api/tutores/login) - gera o token JWT de cada tutor"
call POST /api/tutores/login "" tutor-login-1.json; expect_status 200; TOKEN_ANA=$(json_token)
call POST /api/tutores/login "" tutor-login-2.json; expect_status 200; TOKEN_BRUNO=$(json_token)
call POST /api/tutores/login "" tutor-login-3.json; expect_status 200; TOKEN_CARLA=$(json_token)

header "TB_TUTOR - READ (GET /api/tutores/{id})"
call GET "/api/tutores/$TUTOR_ANA" "$TOKEN_ANA"; expect_status 200
pause_db "opcao 1 (TB_TUTOR) - mesmo registro retornado pela API"

header "TB_TUTOR - UPDATE (PUT /api/tutores/{id}) - nome e telefone da Ana"
call PUT "/api/tutores/$TUTOR_ANA" "$TOKEN_ANA" tutor-put.json; expect_status 200
pause_db "opcao 1 (TB_TUTOR) - nome 'Ana Beatriz Souza Ramos' e telefone (11) 91234-5678"

header "TB_TUTOR - DELETE (DELETE /api/tutores/{id}) - Carla"
call DELETE "/api/tutores/$TUTOR_CARLA" "$TOKEN_CARLA"; expect_status 204
pause_db "opcao 1 (TB_TUTOR) - Carla removida, restam Ana e Bruno"

# ========================== TABELA TB_PET ==========================
header "TB_PET - CREATE (POST /api/pets) - 3 pets ligados aos tutores (FK tutor_id)"
call POST /api/pets "$TOKEN_ANA" pet-post-1.json; expect_status 201; PET_THOR=$(json_id)
pause_db "opcao 2 (TB_PET) - Thor inserido com tutor_id da Ana e health_score 100"
call POST /api/pets "$TOKEN_ANA" pet-post-2.json; expect_status 201; PET_LUNA=$(json_id)
call POST /api/pets "$TOKEN_BRUNO" pet-post-3.json; expect_status 201; PET_MEL=$(json_id)
pause_db "opcao 2 (TB_PET) e opcao 3 (JOIN tutor x pet) - Thor e Luna da Ana, Mel do Bruno"

header "TB_PET - READ (GET /api/pets e GET /api/pets/{id})"
call GET /api/pets "$TOKEN_ANA"; expect_status 200
call GET "/api/pets/$PET_MEL" "$TOKEN_BRUNO"; expect_status 200
pause_db "opcao 2 (TB_PET) - mesmos dados retornados pela API"

header "TB_PET - UPDATE (PUT /api/pets/{id}) - idade e peso do Thor"
call PUT "/api/pets/$PET_THOR" "$TOKEN_ANA" pet-put.json; expect_status 200
pause_db "opcao 2 (TB_PET) - Thor com idade 5 e peso 30.2"

header "TB_PET - DELETE (DELETE /api/pets/{id}) - Luna"
call DELETE "/api/pets/$PET_LUNA" "$TOKEN_ANA"; expect_status 204
pause_db "opcao 3 (JOIN) e opcao 4 (contagem) - restam Thor (Ana) e Mel (Bruno)"

header "Resumo"
echo "TB_TUTOR: Ana (id $TUTOR_ANA, atualizada) e Bruno (id $TUTOR_BRUNO). Carla (id $TUTOR_CARLA) excluida."
echo "TB_PET  : Thor (id $PET_THOR, atualizado) e Mel (id $PET_MEL). Luna (id $PET_LUNA) excluida."
echo
echo "Agora mostre o Application Insights no portal (Live Metrics, Application Map, Performance, Logs)."
