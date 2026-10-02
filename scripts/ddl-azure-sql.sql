-- =================================================================
-- CLYVO Predict - DDL das tabelas no Azure SQL Database (SQL Server)
--
-- IMPORTANTE: voce NAO precisa executar este arquivo manualmente.
-- O Flyway executa o mesmo conteudo automaticamente quando a aplicacao
-- sobe no Azure (src/main/resources/db/migration/sqlserver/V1__cria_tabelas.sql).
-- Este arquivo existe para documentacao e para uso manual no Query Editor
-- (nesse caso, sem o Flyway, o Hibernate validaria o mesmo esquema).
-- =================================================================

CREATE TABLE tb_tutor (
    id        BIGINT IDENTITY(1,1) NOT NULL,
    nome      VARCHAR(100) NOT NULL,
    email     VARCHAR(100) NOT NULL,
    telefone  VARCHAR(20)  NOT NULL,
    perfil    VARCHAR(20)  NOT NULL CONSTRAINT df_tb_tutor_perfil DEFAULT 'TUTOR',
    senha     VARCHAR(255) NOT NULL,
    CONSTRAINT pk_tb_tutor PRIMARY KEY (id),
    CONSTRAINT uk_tb_tutor_email UNIQUE (email),
    CONSTRAINT ck_tb_tutor_perfil CHECK (perfil IN ('TUTOR', 'VETERINARIO'))
);

CREATE TABLE tb_veterinario (
    id     BIGINT IDENTITY(1,1) NOT NULL,
    nome   VARCHAR(100) NOT NULL,
    email  VARCHAR(100) NOT NULL,
    senha  VARCHAR(255) NOT NULL,
    crmv   VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_tb_veterinario PRIMARY KEY (id),
    CONSTRAINT uk_tb_veterinario_email UNIQUE (email),
    CONSTRAINT uk_tb_veterinario_crmv UNIQUE (crmv)
);

CREATE TABLE tb_pet (
    id            BIGINT IDENTITY(1,1) NOT NULL,
    nome          VARCHAR(100) NOT NULL,
    especie       VARCHAR(50)  NOT NULL,
    raca          VARCHAR(50)  NULL,
    idade         INT          NOT NULL,
    peso          FLOAT        NOT NULL,
    health_score  INT          NOT NULL CONSTRAINT df_tb_pet_health_score DEFAULT 100,
    tutor_id      BIGINT       NOT NULL,
    CONSTRAINT pk_tb_pet PRIMARY KEY (id),
    CONSTRAINT fk_tb_pet_tutor FOREIGN KEY (tutor_id)
        REFERENCES tb_tutor (id) ON DELETE CASCADE,
    CONSTRAINT ck_tb_pet_health_score CHECK (health_score BETWEEN 0 AND 100)
);

CREATE TABLE tb_evento_saude (
    id           BIGINT IDENTITY(1,1) NOT NULL,
    pet_id       BIGINT       NOT NULL,
    tipo_evento  VARCHAR(255) NOT NULL,
    descricao    VARCHAR(255) NOT NULL,
    data_evento  DATE         NOT NULL,
    CONSTRAINT pk_tb_evento_saude PRIMARY KEY (id),
    CONSTRAINT fk_tb_evento_saude_pet FOREIGN KEY (pet_id)
        REFERENCES tb_pet (id) ON DELETE CASCADE
);

CREATE INDEX ix_tb_pet_tutor_id ON tb_pet (tutor_id);
CREATE INDEX ix_tb_evento_saude_pet_id ON tb_evento_saude (pet_id);
