<div align="center">

# 🔮 Clyvo Predict

**Microsserviço de Predição de Saúde Animal — Challenge FIAP 2026**

[![Java](https://img.shields.io/badge/Java-17-orange?style=for-the-badge&logo=openjdk&logoColor=white)](https://openjdk.org/projects/jdk/17/)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.5-brightgreen?style=for-the-badge&logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![Oracle](https://img.shields.io/badge/Oracle-DB-red?style=for-the-badge&logo=oracle&logoColor=white)](https://www.oracle.com/database/)
[![Maven](https://img.shields.io/badge/Maven-Build-blue?style=for-the-badge&logo=apachemaven&logoColor=white)](https://maven.apache.org/)
[![Swagger](https://img.shields.io/badge/Swagger-OpenAPI_3-85EA2D?style=for-the-badge&logo=swagger&logoColor=black)](https://swagger.io/)

> Serviço backend desenvolvido como parte do **Challenge FIAP 2026** em parceria com a startup **Clyvo** — plataforma voltada à análise preditiva da saúde de pets, auxiliando tutores a acompanhar o histórico clínico de seus animais por meio de um **Health Score dinâmico**.

</div>

---

## 📋 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [Funcionalidades](#-funcionalidades)
- [Arquitetura e Tecnologias](#-arquitetura-e-tecnologias)
- [Modelo de Domínio](#-modelo-de-domínio)
- [Endpoints da API](#-endpoints-da-api)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Pré-requisitos](#-pré-requisitos)
- [Configuração e Instalação](#-configuração-e-instalação)
- [Executando a Aplicação](#-executando-a-aplicação)
- [Documentação da API](#-documentação-da-api)
- [Design Patterns](#-design-patterns)
- [Testes](#-testes)
- [Time](#-time)

---

## 🎯 Sobre o Projeto

O **Clyvo Predict** é o núcleo de backend da solução desenvolvida no **Challenge 2026 da FIAP** em parceria com a startup **Clyvo**. O serviço expõe uma **API RESTful** que permite o cadastro de tutores e seus pets, o registro de eventos de saúde (consultas, vacinas, doenças, cirurgias) e o cálculo automático de um **Health Score** — uma pontuação dinâmica que reflete a condição de saúde de cada animal ao longo do tempo.

### Contexto do Desafio

O Challenge FIAP é um projeto interdisciplinar onde equipes de estudantes trabalham diretamente com empresas reais para desenvolver soluções tecnológicas com impacto no mercado. A **Clyvo** propôs o desafio de criar um serviço preditivo capaz de processar dados clínicos de pets e entregar insights relevantes de forma escalável, segura e documentada.

---

## ✨ Funcionalidades

- 🐾 **Gestão de Pets** — cadastro, consulta, atualização e remoção de animais
- 👤 **Gestão de Tutores** — cadastro com senha criptografada (BCrypt) e autenticação por e-mail
- 📋 **Registro de Eventos de Saúde** — vacinas, consultas, exames, doenças e acidentes
- 💚 **Health Score dinâmico** — pontuação calculada automaticamente a cada evento (0 a 100)
- 🔍 **Busca com parâmetros** — filtro de pets por nome
- 📄 **Paginação e ordenação** — todos os endpoints de listagem suportam paginação
- ⚡ **Cache de listagem** — otimização de consultas frequentes com Spring Cache
- ✅ **Validação de dados** — Bean Validation em todos os campos de entrada
- 🔒 **Segurança de senha** — hash BCrypt no cadastro e validação no login
- 📖 **Documentação interativa** — Swagger UI gerado automaticamente

---

## 🛠️ Arquitetura e Tecnologias

### Stack Principal

| Tecnologia | Versão | Finalidade |
|---|---|---|
| **Java** | 17 (LTS) | Linguagem principal |
| **Spring Boot** | 3.5 | Framework de aplicação |
| **Spring Data JPA** | — | Abstração de persistência ORM |
| **Spring Web** | — | Camada REST (controllers, DTOs) |
| **Spring Validation** | — | Bean Validation nos DTOs e entidades |
| **Spring Cache** | — | Cache em memória para otimização |
| **Spring Security Crypto** | — | Criptografia BCrypt de senhas |
| **Oracle JDBC (ojdbc11)** | — | Driver de conexão com o banco Oracle |
| **Lombok** | — | Redução de boilerplate |
| **Springdoc OpenAPI** | 2.8 | Geração automática do Swagger UI |
| **Spring DevTools** | — | Reload automático em desenvolvimento |
| **Maven** | Wrapper | Gerenciamento de build e dependências |

### Padrão Arquitetural

A aplicação segue o padrão de **arquitetura em camadas (Layered Architecture)**:

```
┌──────────────────────────────────────────────┐
│              Controller Layer                │  ← REST Endpoints (@RestController)
│     TutorController  PetController           │
│     EventoSaudeController                    │
├──────────────────────────────────────────────┤
│               Service Layer                  │  ← Regras de negócio (@Service)
│     TutorService  PetService                 │
│     EventoSaudeService                       │
├──────────────────────────────────────────────┤
│             Repository Layer                 │  ← Acesso a dados (Spring Data JPA)
│     TutorRepository  PetRepository           │
│     EventoSaudeRepository                    │
├──────────────────────────────────────────────┤
│              Model Layer                     │  ← Entidades JPA + Enum
│     Tutor  Pet  EventoSaude  TipoEvento      │
├──────────────────────────────────────────────┤
│           Database (Oracle DB)               │  ← Persistência
│     TB_TUTOR  TB_PET  TB_EVENTO_SAUDE        │
└──────────────────────────────────────────────┘
```

---

## 🗂️ Modelo de Domínio

### Entidades e Relacionamentos

```
Tutor (1) ──────────── (N) Pet (1) ──────────── (N) EventoSaude
  - id                       - id                      - id
  - nome                     - nome                    - tipoEvento (Enum)
  - email (unique)           - especie                 - descricao
  - telefone                 - raca                    - dataEvento
  - senha (BCrypt)           - idade                   - pet (FK)
                             - peso
                             - healthScore (0-100)
                             - tutor (FK)
```

### Health Score — Como funciona

O **Health Score** é uma pontuação de 0 a 100 que reflete a condição de saúde do pet. Cada evento registrado impacta automaticamente essa pontuação:

| Tipo de Evento | Impacto no Score |
|---|---|
| `VACINA` | +10 |
| `CONSULTA_ROTINA` | +5 |
| `EXAME` | +5 |
| `DOENCA_LEVE` | -15 |
| `CIRURGIA` | -30 |
| `DOENCA_GRAVE` | -40 |
| `ACIDENTE` | -50 |

> Todo pet inicia com **Health Score = 100** e o valor é mantido sempre entre **0 e 100**.

---

## 🌐 Endpoints da API

### Tutores — `/api/tutores`

| Método | Endpoint | Descrição |
|---|---|---|
| `POST` | `/api/tutores` | Cadastrar novo tutor |
| `POST` | `/api/tutores/login` | Autenticar tutor |
| `GET` | `/api/tutores` | Listar tutores (paginado) |
| `GET` | `/api/tutores/{id}` | Buscar tutor por ID |
| `PUT` | `/api/tutores/{id}` | Atualizar tutor |
| `DELETE` | `/api/tutores/{id}` | Remover tutor |

### Pets — `/api/pets`

| Método | Endpoint | Descrição |
|---|---|---|
| `POST` | `/api/pets` | Cadastrar novo pet |
| `GET` | `/api/pets` | Listar pets (paginado, filtrável por `?nome=`) |
| `GET` | `/api/pets/{id}` | Buscar pet por ID |
| `PUT` | `/api/pets/{id}` | Atualizar pet |
| `DELETE` | `/api/pets/{id}` | Remover pet |

### Eventos de Saúde — `/api/eventos`

| Método | Endpoint | Descrição |
|---|---|---|
| `POST` | `/api/eventos` | Registrar evento e atualizar Health Score |
| `GET` | `/api/eventos/pet/{petId}` | Listar eventos de um pet (paginado, ordenado por data) |

---

## 📁 Estrutura do Projeto

```
clyvo-predict/
│
├── src/
│   ├── main/
│   │   ├── java/br/com/fiap/clyvo/
│   │   │   ├── controller/
│   │   │   │   ├── TutorController.java
│   │   │   │   ├── PetController.java
│   │   │   │   └── EventoSaudeController.java
│   │   │   ├── service/
│   │   │   │   ├── TutorService.java
│   │   │   │   ├── PetService.java
│   │   │   │   └── EventoSaudeService.java
│   │   │   ├── repository/
│   │   │   │   ├── TutorRepository.java
│   │   │   │   ├── PetRepository.java
│   │   │   │   └── EventoSaudeRepository.java
│   │   │   ├── model/
│   │   │   │   ├── Tutor.java
│   │   │   │   ├── Pet.java
│   │   │   │   ├── EventoSaude.java
│   │   │   │   └── enums/
│   │   │   │       └── TipoEvento.java
│   │   │   ├── dto/
│   │   │   │   ├── TutorRequestDTO.java / TutorResponseDTO.java
│   │   │   │   ├── TutorLoginRequestDTO.java / TutorAuthResponseDTO.java
│   │   │   │   ├── PetRequestDTO.java / PetResponseDTO.java
│   │   │   │   └── EventoSaudeRequestDTO.java / EventoSaudeResponseDTO.java
│   │   │   ├── exception/
│   │   │   │   ├── TratadorDeErros.java
│   │   │   │   └── DadosErroValidacao.java
│   │   │   └── ClyvoPredictApplication.java
│   │   │
│   │   └── resources/
│   │       └── application.properties
│   │
│   └── test/
│       └── java/br/com/fiap/clyvo/
│           └── ClyvoPredictApplicationTests.java
│
├── .gitignore
├── mvnw / mvnw.cmd
└── pom.xml
```

---

## ✅ Pré-requisitos

- **[Java 17+](https://adoptium.net/)** — JDK (não apenas JRE)
- **[Maven 3.8+](https://maven.apache.org/download.cgi)** — ou use o wrapper `./mvnw` incluso
- **Acesso ao Oracle DB** — instância local, Docker ou servidor remoto (FIAP: `oracle.fiap.com.br`)
- **[Git](https://git-scm.com/)** — para clonar o repositório
- **[Postman](https://www.postman.com/) ou [Insomnia](https://insomnia.rest/)** — para testar os endpoints (collection disponível em `/documentos`)

---

## ⚙️ Configuração e Instalação

### 1. Clone o repositório

```bash
git clone https://github.com/gabrielalandim/clyvo-predict.git
cd clyvo-predict
```

### 2. Configure o banco de dados

Edite `src/main/resources/application.properties`:

```properties
spring.datasource.url=jdbc:oracle:thin:@oracle.fiap.com.br:1521:orcl
spring.datasource.username=${DB_USERNAME}
spring.datasource.password=${DB_PASSWORD}
spring.datasource.driver-class-name=oracle.jdbc.OracleDriver

spring.jpa.hibernate.ddl-auto=update
spring.jpa.database-platform=org.hibernate.dialect.OracleDialect
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.format_sql=true

springdoc.swagger-ui.path=/swagger-ui.html
springdoc.api-docs.path=/v3/api-docs
```

Defina `DB_USERNAME` e `DB_PASSWORD` nas variáveis de ambiente da configuração de execução da sua IDE ou no terminal que iniciará o Java. Use suas credenciais reais apenas nesse ambiente, sem salvá-las no repositório.

No PowerShell, você pode informar as credenciais sem colocar a senha no histórico de comandos:

```powershell
$env:DB_USERNAME = Read-Host 'Usuário Oracle'
$dbCredential = Get-Credential -UserName $env:DB_USERNAME -Message 'Informe a senha Oracle'
$env:DB_PASSWORD = $dbCredential.GetNetworkCredential().Password
Remove-Variable dbCredential
```

Execute os comandos Maven nesse mesmo terminal. As variáveis precisam ser configuradas novamente em novos terminais. Um arquivo `.env` não é carregado automaticamente por esta configuração do Spring Boot.

### 3. Instale as dependências

```bash
./mvnw clean install -DskipTests
```

---

## ▶️ Executando a Aplicação

```bash
# Modo desenvolvimento
./mvnw spring-boot:run

# Gerar JAR e executar
./mvnw clean package -DskipTests
java -jar target/clyvo-predict-0.0.1-SNAPSHOT.jar
```

A aplicação sobe em: **http://localhost:8080**

### Executando a interface mobile com Expo

O aplicativo mobile consome esta API Java e está disponível no repositório:
**[Clyvo Predict Mobile - Sprint 3](https://github.com/gabrielalandim/clyvo-predict-mobile-sprint3)**.

**Pré-requisitos:** Node.js e npm instalados, Expo Go no celular Android ou iOS (compatível com o SDK do projeto), backend Java em execução e banco Oracle configurado e acessível.

1. Mantenha o backend Java rodando na porta `8080`. No Windows, você pode iniciá-lo na pasta `clyvo-predict` com:

   ```powershell
   .\mvnw.cmd spring-boot:run
   ```

2. Em outro terminal, clone o aplicativo e instale suas dependências:

   ```bash
   git clone https://github.com/gabrielalandim/clyvo-predict-mobile-sprint3.git
   cd clyvo-predict-mobile-sprint3
   npm install
   ```

3. No projeto mobile, edite `src/config/env.ts` e configure `API_HOST` com o IPv4 do computador que executa o Java. No Windows, consulte esse endereço com `ipconfig`, usando o adaptador Ethernet ou Wi-Fi da sua rede:

   ```typescript
   const API_HOST = '192.168.0.10'; // Exemplo: substitua pelo IPv4 do seu computador.
   const API_PORT = 8080;
   ```

   Para celular físico, conecte o celular à mesma rede local do computador. Não use `localhost` no celular, pois ele aponta para o próprio aparelho. No emulador Android padrão do Android Studio, use `10.0.2.2` para acessar o backend executado no computador.

4. Inicie o Expo:

   ```bash
   npx expo start
   ```

5. Abra o Expo Go no Android e escaneie o QR Code exibido no terminal. No iPhone, escaneie com a câmera. Para usar um emulador Android já iniciado, pressione `a` no terminal do Expo.

6. Na aplicação, crie uma conta de tutor ou faça login com uma conta existente. Em seguida, acesse o cadastro de pets e o registro e consulta de eventos de saúde.

**Cadastro com foto e IA:** esse recurso também exige o serviço Python em execução no endereço definido por `clyvo.ai.url` no backend Java (por padrão, `http://localhost:5000`). O mobile chama o Java, que encaminha a análise ao Python. Consulte as instruções do serviço de IA para configurar suas dependências e iniciá-lo antes de testar esse fluxo.

**Se o app não conectar à API:** confirme o IP em `src/config/env.ts`, recarregue o aplicativo após alterá-lo e abra `http://IP_DO_COMPUTADOR:8080/swagger-ui.html` no navegador do celular. Se a página não abrir, confira se o Java está rodando, se os dispositivos estão na mesma rede e se o firewall permite o acesso à porta `8080` na rede privada. O túnel do Expo, quando utilizado, não disponibiliza automaticamente a API Java ao celular.

---

## 📖 Documentação da API

| Interface | URL |
|---|---|
| **Swagger UI** | http://localhost:8080/swagger-ui.html |
| **OpenAPI JSON** | http://localhost:8080/v3/api-docs |

> A collection do Postman com todos os endpoints testados está disponível na pasta `/documentos` do repositório.

---

## 🧩 Design Patterns

### Strategy Pattern — `TipoEvento`

O cálculo do Health Score utiliza o padrão **Strategy** embutido no enum `TipoEvento`. Cada tipo de evento encapsula seu próprio impacto e a lógica de cálculo, eliminando condicionais espalhadas pelo código:

```java
public enum TipoEvento {
    VACINA(+10), CONSULTA_ROTINA(+5), EXAME(+5),
    DOENCA_LEVE(-15), CIRURGIA(-30), DOENCA_GRAVE(-40), ACIDENTE(-50);

    private final int impactoScore;

    public int calcularNovoScore(int scoreAtual) {
        int novoScore = scoreAtual + this.impactoScore;
        return Math.max(0, Math.min(100, novoScore));
    }
}
```

### Cache Pattern — `PetService`

A listagem de pets utiliza `@Cacheable` para evitar consultas desnecessárias ao banco. O cache é invalidado automaticamente a cada cadastro, atualização ou remoção via `@CacheEvict`.

---

## 🧪 Testes

```bash
# Executar todos os testes
./mvnw test

# Com relatório
./mvnw verify
```

Os relatórios ficam em `target/surefire-reports/`.

A collection do Postman com os testes de todos os endpoints está disponível em `/documentos/clyvo-predict-collection.json`.

---

## 👥 Time

Desenvolvido por estudantes da **FIAP** — Challenge 2026 × **Clyvo**.

| Nome | RM |
|---|---|
| Maria Gabriela Landim Severo | RM565146 |
| Eduarda Weiss Ventura | RM564434 |
| Samara Porto Souza | RM559072 |
| Lucas Nunes Soares | RM566503 |
| Camilly Vitoria Pereira Maciel | RM566520 |

---

<div align="center">

Feito com ☕ e ❤️ por estudantes da **FIAP** · Challenge 2026 × **Clyvo**

</div>
