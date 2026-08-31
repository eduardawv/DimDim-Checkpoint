# 💰 Projeto DimDim

> **Checkpoint 1 — 2o Semestre — Containers em Nuvem (ACR/ACI)**  
> Java 17 · Spring Boot 3.5 · MySQL 8 · Docker · Azure ACR + ACI  
> FIAP 2026 — 2TDS Fevereiro — Prof. João Menk

---

## 📖 Descrição

API REST em Java 17 com Spring Boot, containerizada e implantada no Azure usando Azure Container Registry (ACR) e Azure Container Instance (ACI), com banco MySQL 8 containerizado e persistência via Conta de Armazenamento.

---

## 👥 Integrantes

| Nome | RM |
|------|-----|
| Eduarda Weiss Ventura | RM564434 |
| Maria Gabriela Landim Severo | RM565146 |
| Samara Porto Souza | RM559072 |
| Lucas Nunes Soares | RM566503 |
| Camily Vitoria Pereira Maciel | RM566520 |

**RM representante:** 564434 (prefixo dos recursos Azure)

---

## 🏗️ Arquitetura

```
Desenvolvedor                     Microsoft Azure (eastus)
     │                    ┌────────────────────────────────────────┐
     │ docker build       │  Resource Group: rm564434-dimdim-rg    │
     │ docker push        │                                        │
     └──────────────────► │  ┌──────────────────────────────────┐  │
                          │  │  ACR: rm564434acr                │  │
                          │  │  Imagem: rm564434-dimdim-app     │  │
                          │  └──────────┬───────────────────────┘  │
                          │             │ pull                     │
                          │  ┌──────────▼───────────────────────┐  │
                          │  │  ACI: rm564434-dimdim-group      │  │
                          │  │                                  │  │
  Usuários ──HTTP:8080──► │  │  ┌────────────┐  ┌────────────┐ │  │
                          │  │  │ rm564434   │  │ rm564434   │ │  │
                          │  │  │ -app       │  │ -db        │ │  │
                          │  │  │ Java 17    ├──► MySQL 8    │ │  │
                          │  │  │ Spring Boot│  │ dimdimdb   │ │  │
                          │  │  │ user:      │  └─────┬──────┘ │  │
                          │  │  │ appuser    │        │        │  │
                          │  │  └────────────┘  ┌─────▼──────┐ │  │
                          │  │                  │ Storage    │ │  │
                          │  │                  │ Account    │ │  │
                          │  │                  │ (volume)   │ │  │
                          │  │                  └────────────┘ │  │
                          │  └──────────────────────────────────┘  │
                          └────────────────────────────────────────┘
```

---

## 📂 Estrutura do repositório

```
DimDim-Checkpoint/
├── Dockerfile                    # Multi-stage build (JDK → JRE)
├── aci-deploy.yaml               # YAML multi-container ACI
├── azure-setup-cp1.sh            # Script Azure CLI (provisiona tudo)
├── azure-destroy-cp1.sh          # Script para deletar recursos
├── docker-compose.yml            # Teste local (App + MySQL)
├── script_bd.sql                 # DDL das tabelas
├── json-testes/                  # Arquivos JSON para testes da API
│   ├── POST_tutor.json
│   ├── PUT_tutor.json
│   ├── POST_pet.json
│   ├── PUT_pet.json
│   └── GET_DELETE_endpoints.json
├── src/                          # Código-fonte Java
├── pom.xml                       # Dependências Maven
└── README.md                     # Este arquivo
```

---

## 🚀 How To — Tutorial de execução

### Pré-requisitos

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- Conta Azure ativa

### Passo 1 — Clone o repositório

```bash
git clone https://github.com/eduardawv/DimDim-Checkpoint.git
cd DimDim-Checkpoint
```

### Passo 2 — Build e push da imagem

```bash
# Login no Azure
az login

# Executa o script completo (cria todos os recursos)
./azure-setup-cp1.sh
```

### Passo 3 — Comandos de build e push (executados pelo script)

```bash
# Build da imagem do App
docker build -t rm564434acr.azurecr.io/rm564434-dimdim-app:latest .

# Login no ACR
az acr login --name rm564434acr

# Push da imagem para o ACR
docker push rm564434acr.azurecr.io/rm564434-dimdim-app:latest
```

### Passo 4 — Acessar a aplicação

```
Swagger UI: http://rm564434-dimdim.eastus.azurecontainer.io:8080/swagger-ui.html
```

### Passo 5 — Testar o CRUD

Use o Swagger UI ou os arquivos JSON da pasta `json-testes/`:

```bash
# POST tutor
curl -X POST http://<URL>:8080/api/tutores \
  -H "Content-Type: application/json" \
  -d @json-testes/POST_tutor.json

# GET tutores
curl http://<URL>:8080/api/tutores

# PUT tutor
curl -X PUT http://<URL>:8080/api/tutores/1 \
  -H "Content-Type: application/json" \
  -d @json-testes/PUT_tutor.json

# DELETE tutor
curl -X DELETE http://<URL>:8080/api/tutores/1
```

### Passo 6 — Verificar no banco (evidência SELECT)

```bash
az container exec \
  --resource-group rm564434-dimdim-rg \
  --name rm564434-dimdim-group \
  --container-name rm564434-db \
  --exec-command "mysql -u dimdim_user -pDimDim@Pass123 dimdimdb"

# No MySQL:
SELECT * FROM tb_tutor;
SELECT * FROM tb_pet;
```

### Passo 7 — Deletar recursos

```bash
./azure-destroy-cp1.sh
# ou:
az group delete --name rm564434-dimdim-rg --yes --no-wait
```

---

## 🐳 Dockerfile

```dockerfile
FROM eclipse-temurin:17-jdk AS build
WORKDIR /app
COPY pom.xml . && COPY .mvn/ .mvn/ && COPY mvnw .
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B
COPY src/ src/
RUN ./mvnw package -DskipTests -B

FROM eclipse-temurin:17-jre AS runtime
WORKDIR /app
RUN groupadd --system appgroup && useradd --system --gid appgroup appuser
COPY --from=build /app/target/*.jar app.jar
RUN chown -R appuser:appgroup /app
USER appuser          # ← sem privilégios de admin
EXPOSE 8080
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

---

## ☁️ Recursos Azure (com prefixo RM564434)

| Recurso | Nome |
|---------|------|
| Resource Group | `rm564434-dimdim-rg` |
| Container Registry | `rm564434acr` |
| Container Instance (App) | `rm564434-app` |
| Container Instance (DB) | `rm564434-db` |
| Storage Account | `rm564434storage` |
| DNS público | `rm564434-dimdim.eastus.azurecontainer.io` |
