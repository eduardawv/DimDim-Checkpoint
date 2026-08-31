-- =================================================================
-- Projeto DimDim — script_bd.sql (MySQL 8)
-- DDL + inserts significativos
-- Checkpoint 1 DevOps — 2o Semestre — FIAP 2026
-- =================================================================

CREATE TABLE IF NOT EXISTS tb_tutor (
    id       BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID unico do tutor',
    nome     VARCHAR(100) NOT NULL             COMMENT 'Nome completo',
    email    VARCHAR(100) UNIQUE               COMMENT 'E-mail unico',
    telefone VARCHAR(20)                       COMMENT 'Telefone contato',
    senha    VARCHAR(255)                      COMMENT 'Senha hash'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Donos dos pets';

CREATE TABLE IF NOT EXISTS tb_pet (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID unico do pet',
    nome         VARCHAR(100) NOT NULL             COMMENT 'Nome do pet',
    especie      VARCHAR(50)                       COMMENT 'Especie (Cachorro, Gato)',
    raca         VARCHAR(50)                       COMMENT 'Raca do animal',
    idade        INT                               COMMENT 'Idade em anos',
    peso         DECIMAL(5,2)                      COMMENT 'Peso em kg',
    health_score INT DEFAULT 100                   COMMENT 'Score de saude 0-100',
    tutor_id     BIGINT NOT NULL                   COMMENT 'FK para tb_tutor',
    CONSTRAINT fk_pet_tutor FOREIGN KEY (tutor_id) REFERENCES tb_tutor(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Pacientes veterinarios';

-- Inserts significativos
INSERT INTO tb_tutor (nome, email, telefone, senha) VALUES
    ('Carlos Silva', 'carlos@email.com', '11999990001', 'hash123'),
    ('Ana Souza', 'ana@email.com', '11999990002', 'hash456');

INSERT INTO tb_pet (nome, especie, raca, idade, peso, health_score, tutor_id) VALUES
    ('Thor', 'Cachorro', 'Golden Retriever', 5, 32.50, 85, 1),
    ('Luna', 'Gato', 'Siames', 3, 4.20, 92, 2);
