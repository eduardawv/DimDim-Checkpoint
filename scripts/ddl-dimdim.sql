-- =================================================================
-- DimDim CP5 - DDL para Azure SQL Database
-- Tabelas: tb_tutor e tb_pet (relacionamento 1:N)
-- Disciplina: DevOps Tools & Cloud Computing - FIAP 2026
-- =================================================================

-- Remover tabelas se existirem (ordem FK)
IF OBJECT_ID('dbo.tb_pet', 'U') IS NOT NULL DROP TABLE dbo.tb_pet;
IF OBJECT_ID('dbo.tb_tutor', 'U') IS NOT NULL DROP TABLE dbo.tb_tutor;

-- ── Tabela TUTOR ─────────────────────────────────────────────
CREATE TABLE tb_tutor (
    id         BIGINT IDENTITY(1,1) PRIMARY KEY,
    nome       NVARCHAR(100) NOT NULL,
    email      NVARCHAR(150) NOT NULL,
    telefone   NVARCHAR(20),
    cpf        NVARCHAR(14)  NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE()
);

-- ── Tabela PET ───────────────────────────────────────────────
CREATE TABLE tb_pet (
    id         BIGINT IDENTITY(1,1) PRIMARY KEY,
    nome       NVARCHAR(100) NOT NULL,
    especie    NVARCHAR(50)  NOT NULL,
    raca       NVARCHAR(80),
    idade      INT,
    peso       DECIMAL(5,2),
    tutor_id   BIGINT NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    CONSTRAINT fk_pet_tutor
        FOREIGN KEY (tutor_id) REFERENCES tb_tutor(id)
        ON DELETE CASCADE
);

-- ── Inserts iniciais (conteudo significativo) ────────────────
INSERT INTO tb_tutor (nome, email, telefone, cpf) VALUES
    ('Maria Silva', 'maria.silva@email.com', '(11) 99999-1234', '123.456.789-00'),
    ('Joao Santos', 'joao.santos@email.com', '(11) 98888-5678', '987.654.321-00'),
    ('Ana Oliveira', 'ana.oliveira@email.com', '(21) 97777-9012', '456.789.123-00');

INSERT INTO tb_pet (nome, especie, raca, idade, peso, tutor_id) VALUES
    ('Rex', 'Cachorro', 'Golden Retriever', 3, 32.50, 1),
    ('Mia', 'Gato', 'Siames', 2, 4.20, 1),
    ('Thor', 'Cachorro', 'Bulldog Frances', 5, 12.80, 2),
    ('Luna', 'Gato', 'Persa', 1, 3.50, 3);
