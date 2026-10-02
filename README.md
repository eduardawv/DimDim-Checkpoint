# DimDim - CP5 - Aplicativos e Banco em Nuvem

## Descricao da Solucao

O **DimDim** e uma aplicacao web de gestao financeira pessoal construida com **Java 17 + Spring Boot 3.5**, implantada na nuvem Microsoft Azure utilizando servicos PaaS (Platform as a Service).

A solucao permite o cadastro de **tutores** e seus **pets**, demonstrando operacoes CRUD completas com persistencia em **Azure SQL Database** e monitoramento via **Application Insights**.

### Beneficios para o Negocio
- Gestao centralizada de dados de tutores e pets
- Escalabilidade automatica via Azure Web App
- Monitoramento em tempo real com Application Insights
- Banco de dados gerenciado (PaaS) com alta disponibilidade
- Deploy automatizado via GitHub Actions (CI/CD)

---

## Desenho Macro da Arquitetura

```
┌─────────────┐     HTTPS      ┌──────────────────┐
│   Usuario    │ ──────────────>│  Azure Web App   │
│  (Browser)   │                │  Java 17 / Boot  │
└─────────────┘                │  rm564434-dimdim  │
                               └────────┬─────────┘
                                        │ JDBC (TLS)
                                        v
                               ┌──────────────────┐
                               │ Azure SQL Server  │
                               │   rm564434-sqlsrv │
                               │  Database: dimdim │
                               └──────────────────┘
                                        │
                               ┌────────┴─────────┐
                               │  Application      │
                               │  Insights          │
                               │  (Monitoramento)   │
                               └──────────────────┘
```

**Componentes:**
- **Azure Web App** (Linux, Java 17) — hospeda a API REST
- **Azure SQL Database** (PaaS, tier S0) — banco relacional gerenciado
- **Application Insights** — monitoramento de performance e telemetria
- **GitHub Actions** — CI/CD automatizado (build + deploy)

---

## Rotas da API

### Tutores (`/api/tutores`)

| Metodo | Rota               | Descricao           |
|--------|--------------------|-----------------------|
| GET    | /api/tutores       | Listar todos          |
| GET    | /api/tutores/{id}  | Buscar por ID         |
| POST   | /api/tutores       | Criar novo tutor      |
| PUT    | /api/tutores/{id}  | Atualizar tutor       |
| DELETE | /api/tutores/{id}  | Remover tutor         |

### Pets (`/api/pets`)

| Metodo | Rota             | Descricao           |
|--------|------------------|-----------------------|
| GET    | /api/pets        | Listar todos          |
| GET    | /api/pets/{id}   | Buscar por ID         |
| POST   | /api/pets        | Criar novo pet        |
| PUT    | /api/pets/{id}   | Atualizar pet         |
| DELETE | /api/pets/{id}   | Remover pet           |

---

## How To - Instalacao da Solucao em Nuvem

### Pre-requisitos

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) instalado
- Conta Azure com creditos ativos
- Java 17 e Maven instalados localmente
- Git instalado

### Passo 1 — Clonar o Repositorio

```bash
git clone https://github.com/eduardawv/DimDim-Checkpoint.git
cd DimDim-Checkpoint
```

### Passo 2 — Login no Azure

```bash
az login
```

### Passo 3 — Executar o Script de Setup

O script cria todos os recursos automaticamente: Resource Group, SQL Server, SQL Database, Web App, Application Insights e configura as variaveis de ambiente.

```bash
chmod +x scripts/azure-setup-cp5.sh
./scripts/azure-setup-cp5.sh
```

**Recursos criados pelo script:**
- Resource Group: `rg-rm564434-dimdim-cp5`
- SQL Server: `rm564434-dimdim-sqlsrv`
- Database: `dimdimdb`
- Web App: `rm564434-dimdim-webapp`
- App Insights: `rm564434-dimdim-insights`
- App Service Plan: `rm564434-dimdim-plan` (Linux, B1)

### Passo 4 — Aguardar Inicializacao

Aguarde ~2 minutos para a aplicacao iniciar. Acesse:

```
https://rm564434-dimdim-webapp.azurewebsites.net/swagger-ui.html
```

### Passo 5 — Executar DDL no Banco (Opcional)

O Hibernate cria as tabelas automaticamente (`ddl-auto=update`), mas voce pode executar a DDL manualmente:

```bash
# Via Azure Portal > SQL Database > Query Editor
# Ou via sqlcmd:
sqlcmd -S rm564434-dimdim-sqlsrv.database.windows.net \
  -d dimdimdb -U dimdimadmin -P 'DimDim@Fiap2026!' \
  -i scripts/ddl-dimdim.sql
```

### Passo 6 — Testar CRUD (Tutores)

**6.1 — POST (Criar Tutor)**
```bash
curl -s -X POST \
  https://rm564434-dimdim-webapp.azurewebsites.net/api/tutores \
  -H "Content-Type: application/json" \
  -d @json/tutor-post.json | python3 -m json.tool
```

**6.2 — GET (Listar Tutores)**
```bash
curl -s https://rm564434-dimdim-webapp.azurewebsites.net/api/tutores | python3 -m json.tool
```

**6.3 — PUT (Atualizar Tutor id=1)**
```bash
curl -s -X PUT \
  https://rm564434-dimdim-webapp.azurewebsites.net/api/tutores/1 \
  -H "Content-Type: application/json" \
  -d @json/tutor-put.json | python3 -m json.tool
```

**6.4 — DELETE (Remover Tutor id=1)**
```bash
curl -s -X DELETE \
  https://rm564434-dimdim-webapp.azurewebsites.net/api/tutores/1 -w "\nHTTP %{http_code}\n"
```

**6.5 — Verificar no Banco (Azure Portal > Query Editor)**
```sql
SELECT * FROM tb_tutor;
```

### Passo 7 — Testar CRUD (Pets)

**7.1 — POST (Criar Pet)**
```bash
curl -s -X POST \
  https://rm564434-dimdim-webapp.azurewebsites.net/api/pets \
  -H "Content-Type: application/json" \
  -d @json/pet-post.json | python3 -m json.tool
```

**7.2 — GET (Listar Pets)**
```bash
curl -s https://rm564434-dimdim-webapp.azurewebsites.net/api/pets | python3 -m json.tool
```

**7.3 — PUT (Atualizar Pet id=1)**
```bash
curl -s -X PUT \
  https://rm564434-dimdim-webapp.azurewebsites.net/api/pets/1 \
  -H "Content-Type: application/json" \
  -d @json/pet-put.json | python3 -m json.tool
```

**7.4 — DELETE (Remover Pet id=1)**
```bash
curl -s -X DELETE \
  https://rm564434-dimdim-webapp.azurewebsites.net/api/pets/1 -w "\nHTTP %{http_code}\n"
```

**7.5 — Verificar no Banco (Azure Portal > Query Editor)**
```sql
SELECT * FROM tb_pet;
```

### Passo 8 — Verificar Application Insights

1. Acesse o **Azure Portal** > **Application Insights** > `rm564434-dimdim-insights`
2. Verifique:
   - **Live Metrics** — requisicoes em tempo real
   - **Performance** — tempo de resposta das rotas
   - **Failures** — erros e excecoes
   - **Application Map** — mapa de dependencias (Web App → SQL)
3. Faca requests no Swagger e veja refletir no Application Insights

### Passo 9 — Remover Recursos (APOS gravar o video)

```bash
chmod +x scripts/azure-destroy-cp5.sh
./scripts/azure-destroy-cp5.sh
```

**Tire print da tela de remocao como evidencia!**

---

## Estrutura do Repositorio

```
DimDim-Checkpoint/
├── .github/
│   └── workflows/
│       └── deploy-azure.yml        # CI/CD GitHub Actions
├── scripts/
│   ├── azure-setup-cp5.sh          # Script CLI para criar recursos
│   ├── azure-destroy-cp5.sh        # Script CLI para remover recursos
│   └── ddl-dimdim.sql              # DDL das tabelas (Azure SQL)
├── json/
│   ├── tutor-post.json             # JSON para POST tutor
│   ├── tutor-put.json              # JSON para PUT tutor
│   ├── pet-post.json               # JSON para POST pet
│   └── pet-put.json                # JSON para PUT pet
├── src/
│   └── main/
│       ├── java/...                # Codigo fonte Java
│       └── resources/
│           ├── application.properties
│           └── application-azure.properties
├── pom.xml
├── Dockerfile
└── README.md
```

---

## Dockerfile

```dockerfile
FROM eclipse-temurin:17-jdk AS build
WORKDIR /app
COPY pom.xml .
COPY .mvn/ .mvn/
COPY mvnw .
RUN sed -i 's/\r$//' mvnw && chmod +x mvnw
RUN ./mvnw dependency:go-offline -B --no-transfer-progress
COPY src/ src/
RUN ./mvnw package -DskipTests -B --no-transfer-progress

FROM eclipse-temurin:17-jre AS runtime
WORKDIR /app
RUN groupadd --system appgroup && \
    useradd --system --gid appgroup --shell /bin/false appuser
COPY --from=build /app/target/*.jar app.jar
RUN chown -R appuser:appgroup /app
USER appuser
EXPOSE 8080
ENV SPRING_PROFILES_ACTIVE=azure
ENTRYPOINT ["java", "-Xms256m", "-Xmx512m", "-jar", "app.jar"]
```

---

## Scripts Azure CLI

### azure-setup-cp5.sh
Cria todos os recursos na Azure:
1. Resource Group
2. Azure SQL Server + Firewall
3. Azure SQL Database
4. App Service Plan (Linux B1)
5. Web App (Java 17)
6. Application Insights
7. Configura App Settings (variaveis de ambiente com secrets)
8. Habilita logs
9. Build e deploy do JAR

### azure-destroy-cp5.sh
Remove todos os recursos apos a gravacao do video.

---

## JSON das Operacoes CRUD

Os arquivos JSON estao na pasta `json/`:

| Arquivo           | Operacao | Tabela |
|-------------------|----------|--------|
| tutor-post.json   | POST     | Tutor  |
| tutor-put.json    | PUT      | Tutor  |
| pet-post.json     | POST     | Pet    |
| pet-put.json      | PUT      | Pet    |

---

## Alteracoes no pom.xml (obrigatorias)

Adicionar a dependencia do driver SQL Server e Application Insights:

```xml
<!-- Driver Azure SQL Server -->
<dependency>
    <groupId>com.microsoft.sqlserver</groupId>
    <artifactId>mssql-jdbc</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- Application Insights (monitoramento) -->
<dependency>
    <groupId>com.microsoft.azure</groupId>
    <artifactId>applicationinsights-spring-boot-starter</artifactId>
    <version>2.6.4</version>
</dependency>
```

**Remover** a dependencia do MySQL (se existir):
```xml
<!-- REMOVER ESTA DEPENDENCIA -->
<dependency>
    <groupId>com.mysql</groupId>
    <artifactId>mysql-connector-j</artifactId>
    <scope>runtime</scope>
</dependency>
```

---

## Equipe

| Nome              | RM       |
|-------------------|----------|
| Camily            | RM566520 |
| Eduarda (Rep.)    | RM564434 |
| Lucas             | RM566503 |

---

## Link do Video

[YouTube - DimDim CP5 Demo](https://www.youtube.com/watch?v=INSERIR_LINK)

---

**Disciplina:** DevOps Tools & Cloud Computing — FIAP 2026  
**Professor:** Joao Menk
