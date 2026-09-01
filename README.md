# 💰 Projeto DimDim

> **Checkpoint 1 — 2o Semestre — Containers em Nuvem (ACR/ACI)**  
> Java 17 · Spring Boot 3.5 · MySQL 8 · Docker · Azure ACR + ACI  
> FIAP 2026 — 2TDS Fevereiro — Prof. João Menk

---

## 📖 Descrição

API REST em Java 17 com Spring Boot, containerizada e implantada no Azure usando ACR e ACI, com banco MySQL 8 containerizado e volume persistente via Azure Files (Conta de Armazenamento).

**Stack:** Java 17 + Spring Boot 3.5 + MySQL 8 + Docker  
**Deploy:** Azure Container Registry (ACR) + Azure Container Instance (ACI)  
**Persistência:** Azure Files montado em `/var/lib/mysql`

---

## 👥 Integrantes

| Nome | RM |
|------|-----|
| Camily Vitoria Pereira Maciel | RM566520 |
| Eduarda Weiss Ventura (representante) | RM564434 |
| Lucas Nunes Soares | RM566503 |

**RM representante:** 564434 (prefixo dos recursos Azure)

---

## 🏗️ Arquitetura

```
Desenvolvedor                    Microsoft Azure (eastus)
     │                   ┌──────────────────────────────────────────┐
     │ docker build      │  Resource Group: rm564434-dimdim-rg     │
     │ docker push       │                                          │
     └─────────────────► │  ┌────────────────────────────────────┐  │
                         │  │  ACR: rm564434acr                  │  │
                         │  │  Imagens: rm564434-dimdim-app      │  │
                         │  │           mysql:8.0                 │  │
                         │  └───────────────┬────────────────────┘  │
                         │                  │ pull                  │
                         │  ┌───────────────▼────────────────────┐  │
                         │  │  ACI: rm564434-dimdim-group        │  │
                         │  │                                    │  │
 Usuarios ──HTTP:8080──► │  │  ┌────────────┐  ┌─────────────┐  │  │
                         │  │  │ rm564434   │  │ rm564434    │  │  │
                         │  │  │ -app       │  │ -db         │  │  │
                         │  │  │ Java 17    ├──► MySQL 8     │  │  │
                         │  │  │ user:      │  │ dimdimdb    │  │  │
                         │  │  │ appuser    │  └──────┬──────┘  │  │
                         │  │  └────────────┘  ┌──────▼──────┐  │  │
                         │  │                  │ Azure Files │  │  │
                         │  │                  │ Volume      │  │  │
                         │  │                  │ Persistente │  │  │
                         │  │                  └─────────────┘  │  │
                         │  └────────────────────────────────────┘  │
                         └──────────────────────────────────────────┘
```

---

## 🚀 Deploy completo — Passo a passo

### Pré-requisitos

| Ferramenta | Instalação |
|------------|-----------|
| Azure CLI | [learn.microsoft.com/cli/azure](https://learn.microsoft.com/cli/azure/install-azure-cli) |
| Docker Desktop | [docker.com](https://www.docker.com/products/docker-desktop/) |
| Git | [git-scm.com](https://git-scm.com/) |

---

### Passo 1 — Clonar o repositório

```bash
git clone https://github.com/eduardawv/DimDim-Checkpoint.git
cd DimDim-Checkpoint
```

### Passo 2 — Login no Azure

```bash
az login
```

### Passo 3 — Executar o script de deploy

```bash
./azure-setup-cp1.sh
```

O script cria automaticamente:
1. Resource Group `rm564434-dimdim-rg`
2. ACR `rm564434acr`
3. Build e push da imagem do App para o ACR
4. Push da imagem MySQL para o ACR
5. Storage Account `rm564434storage` + File Share (volume persistente)
6. Container Group no ACI com dois containers (MySQL + App)

### Passo 4 — Verificar status dos containers

```bash
az container show \
  --resource-group rm564434-dimdim-rg \
  --name rm564434-dimdim-group \
  --query "containers[].{Nome:name, Estado:instanceView.currentState.state}" \
  --output table
```

Resultado esperado:
```
Nome           Estado
-------------  --------
rm564434-db    Running
rm564434-app   Running
```

### Passo 5 — Obter URL público

```bash
az container show \
  --resource-group rm564434-dimdim-rg \
  --name rm564434-dimdim-group \
  --query "ipAddress.fqdn" --output tsv
```

Resultado:
```
rm564434-dimdim.eastus.azurecontainer.io
```

### Passo 6 — Verificar Swagger UI

Abra no navegador:
```
http://rm564434-dimdim.eastus.azurecontainer.io:8080/swagger-ui.html
```

---

## 🧪 Testes do CRUD via terminal

> Substitua `<URL>` pelo FQDN obtido no Passo 5.  
> Exemplo: `<URL>` = `rm564434-dimdim.eastus.azurecontainer.io`

### 7.1 — CREATE: Inserir tutor

```bash
curl -X POST http://<URL>:8080/api/tutores \
  -H "Content-Type: application/json" \
  -d '{"nome":"Carlos Silva","email":"carlos@email.com","telefone":"11999990001","senha":"123456"}'
```

### 7.2 — Verificar INSERT no banco

```bash
az container exec \
  --resource-group rm564434-dimdim-rg \
  --name rm564434-dimdim-group \
  --container-name rm564434-db \
  --exec-command "mysql -u dimdim_user -pDimDim@Pass123 dimdimdb"
```

```sql
SELECT * FROM tb_tutor;
```

### 7.3 — CREATE: Inserir pet

```bash
curl -X POST http://<URL>:8080/api/pets \
  -H "Content-Type: application/json" \
  -d '{"nome":"Thor","especie":"Cachorro","raca":"Golden Retriever","idade":5,"peso":32.5,"tutorId":1}'
```

### 7.4 — Verificar INSERT do pet no banco

```sql
SELECT * FROM tb_pet;
```

### 7.5 — READ: Listar via GET

```bash
curl http://<URL>:8080/api/tutores
curl http://<URL>:8080/api/pets
```

Ou via Swagger UI: `GET /api/tutores` → Try it out → Execute

### 7.6 — UPDATE: Atualizar pet

```bash
curl -X PUT http://<URL>:8080/api/pets/1 \
  -H "Content-Type: application/json" \
  -d '{"nome":"Thor Atualizado","especie":"Cachorro","raca":"Golden Retriever","idade":6,"peso":33.0,"tutorId":1}'
```

### 7.7 — Verificar UPDATE no banco

```sql
SELECT * FROM tb_pet WHERE id = 1;
```

### 7.8 — DELETE: Remover pet

```bash
curl -X DELETE http://<URL>:8080/api/pets/1
```

### 7.9 — Verificar DELETE no banco

```sql
SELECT * FROM tb_pet WHERE id = 1;
-- Resultado esperado: Empty set (0 rows)
```

### 7.10 — Sair do MySQL

```sql
exit
```

---

## 🐳 Comandos de build e push

```bash
# Build da imagem do App
docker build -t rm564434acr.azurecr.io/rm564434-dimdim-app:latest .

# Login no ACR
az acr login --name rm564434acr

# Push do App
docker push rm564434acr.azurecr.io/rm564434-dimdim-app:latest

# Push do MySQL (evita dependência do Docker Hub)
docker pull mysql:8.0
docker tag mysql:8.0 rm564434acr.azurecr.io/mysql:8.0
docker push rm564434acr.azurecr.io/mysql:8.0

# Verificar imagens no ACR
az acr repository list --name rm564434acr --output table
```

---

## 📋 Logs dos containers

```bash
# Logs do App
az container logs \
  --resource-group rm564434-dimdim-rg \
  --name rm564434-dimdim-group \
  --container-name rm564434-app

# Logs do MySQL
az container logs \
  --resource-group rm564434-dimdim-rg \
  --name rm564434-dimdim-group \
  --container-name rm564434-db
```

---

## 🗑️ Deletar recursos

```bash
az group delete --name rm564434-dimdim-rg --yes --no-wait
```

---

## 📂 Estrutura do repositório

```
DimDim-Checkpoint/
├── Dockerfile                    # Multi-stage (JDK→JRE, user: appuser)
├── aci-deploy.yaml               # YAML ACI com volume Azure Files
├── azure-setup-cp1.sh            # Script Azure CLI completo
├── azure-destroy-cp1.sh          # Script para deletar recursos
├── docker-compose.yml            # Teste local
├── script_bd.sql                 # DDL das tabelas
├── json-testes/                  # Arquivos JSON para testes
│   ├── POST_tutor.json
│   ├── PUT_tutor.json
│   ├── POST_pet.json
│   ├── PUT_pet.json
│   └── GET_DELETE_endpoints.json
├── pom.xml
├── src/
│   └── main/resources/
│       ├── application.properties
│       └── application-prod.properties
└── README.md
```

---

## 🗄️ Banco de Dados

**Banco:** MySQL 8 (containerizado no ACI, imagem via ACR)  
**Persistência:** Azure Files montado em `/var/lib/mysql`  
**DDL:** [`script_bd.sql`](./script_bd.sql)  
**Tabelas:** `tb_tutor` e `tb_pet` (FK: `tb_pet.tutor_id → tb_tutor.id`)

---

## ☁️ Recursos Azure (prefixo RM564434)

| Recurso | Nome |
|---------|------|
| Resource Group | `rm564434-dimdim-rg` |
| Container Registry (ACR) | `rm564434acr` |
| Container App | `rm564434-app` |
| Container DB | `rm564434-db` |
| Storage Account | `rm564434storage` |
| File Share (volume) | `rm564434-dbdata` |
| DNS público | `rm564434-dimdim.eastus.azurecontainer.io` |
