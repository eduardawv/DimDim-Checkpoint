-- =================================================================
-- CLYVO Predict - Consultas para mostrar a persistencia no video
-- Use no terminal do banco (bash scripts/db-terminal.sh) ou no
-- Portal Azure > SQL database > Query editor.
-- =================================================================

-- 1) Tutores (senha gravada com hash BCrypt, nunca em texto puro)
SELECT id, nome, email, telefone, perfil, LEFT(senha, 20) + '...' AS senha_bcrypt
FROM tb_tutor ORDER BY id;

-- 2) Pets
SELECT id, nome, especie, raca, idade, peso, health_score, tutor_id
FROM tb_pet ORDER BY id;

-- 3) Relacionamento tutor x pet (FK tb_pet.tutor_id -> tb_tutor.id)
SELECT t.id AS tutor_id, t.nome AS tutor, t.telefone,
       p.id AS pet_id, p.nome AS pet, p.especie, p.raca, p.idade, p.peso
FROM tb_tutor t
LEFT JOIN tb_pet p ON p.tutor_id = t.id
ORDER BY t.id, p.id;

-- 4) Linhas por tabela
SELECT 'tb_tutor' AS tabela, COUNT(*) AS linhas FROM tb_tutor
UNION ALL SELECT 'tb_pet', COUNT(*) FROM tb_pet;

-- 5) Migrations aplicadas pelo Flyway
SELECT installed_rank, version, description, script, success, installed_on
FROM flyway_schema_history ORDER BY installed_rank;
