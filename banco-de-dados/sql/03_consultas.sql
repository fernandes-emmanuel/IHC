-- Consultas SQL das interfaces do Módulo de Controle de Acessos
-- Os valores literais são exemplos; na aplicação viram parâmetros.

-- Tela: Login com Active Directory

-- 1) E-mail autenticado no AD está cadastrado?
SELECT id, nome
FROM usuario
WHERE email = 'adailton@positivo.com.br';

-- 2) Atualizar nome (vindo do AD) e último acesso
UPDATE usuario
SET nome = 'Adailton Araújo',
    ultimo_acesso = now(),
    atualizado_em = now()
WHERE id = 1;

-- 3) Permissões do usuário logado (de todos os seus grupos)
SELECT DISTINCT p.codigo, p.nome
FROM usuario_grupo ug
JOIN grupo_permissao gp ON gp.grupo_id = ug.grupo_id
JOIN permissao p ON p.id = gp.permissao_id
WHERE ug.usuario_id = 1
ORDER BY p.codigo;

-- Tela: Permissões - aba Usuários

-- 4) Listar usuários com busca
SELECT u.id,
       u.nome,
       u.email,
       (SELECT string_agg(g.nome, ', ' ORDER BY g.nome)
          FROM usuario_grupo ug
          JOIN grupo g ON g.id = ug.grupo_id
         WHERE ug.usuario_id = u.id) AS grupos,
       (SELECT string_agg(p.nome, ', ' ORDER BY p.nome)
          FROM usuario_papel up
          JOIN papel p ON p.id = up.papel_id
         WHERE up.usuario_id = u.id) AS papeis,
       u.ultimo_acesso
FROM usuario u
WHERE u.nome ILIKE '%positivo%'
   OR u.email ILIKE '%positivo%'
ORDER BY u.nome;

-- 5) Opções do campo Grupo
SELECT id, nome FROM grupo ORDER BY nome;

-- 6) Opções do campo Papel
SELECT id, nome FROM papel ORDER BY nome;

-- 7) Adicionar usuário
BEGIN;
INSERT INTO usuario (email)
VALUES ('maria.lima@positivo.com.br');

INSERT INTO usuario_grupo (usuario_id, grupo_id)
SELECT u.id, g.id
FROM usuario u, grupo g
WHERE u.email = 'maria.lima@positivo.com.br'
  AND g.id IN (1, 4);

INSERT INTO usuario_papel (usuario_id, papel_id)
SELECT u.id, p.id
FROM usuario u, papel p
WHERE u.email = 'maria.lima@positivo.com.br'
  AND p.id IN (2);
COMMIT;

-- 8) Carregar usuário para edição
SELECT email FROM usuario WHERE id = 6;
SELECT grupo_id FROM usuario_grupo WHERE usuario_id = 6;
SELECT papel_id FROM usuario_papel WHERE usuario_id = 6;

-- 9) Salvar edição do usuário
BEGIN;
UPDATE usuario
SET email = 'maria.silva@positivo.com.br',
    atualizado_em = now()
WHERE id = 6;

DELETE FROM usuario_grupo WHERE usuario_id = 6;
INSERT INTO usuario_grupo (usuario_id, grupo_id)
VALUES (6, 1), (6, 2);

DELETE FROM usuario_papel WHERE usuario_id = 6;
INSERT INTO usuario_papel (usuario_id, papel_id)
VALUES (6, 1);
COMMIT;

-- 10) Excluir usuário (vínculos saem por CASCADE)
DELETE FROM usuario WHERE id = 6;

-- Tela: Permissões - aba Grupos

-- 11) Listar grupos com busca
SELECT g.id,
       g.nome,
       (SELECT count(*) FROM grupo_permissao gp
         WHERE gp.grupo_id = g.id) AS permissoes,
       (SELECT count(*) FROM usuario_grupo ug
         WHERE ug.grupo_id = g.id) AS usuarios
FROM grupo g
WHERE g.nome ILIKE '%editais%'
ORDER BY g.nome;

-- 12) Usuários de um grupo
SELECT u.nome, u.email
FROM usuario_grupo ug
JOIN usuario u ON u.id = ug.usuario_id
WHERE ug.grupo_id = 4
ORDER BY u.nome;

-- Tela: Adicionar / Editar grupo

-- 13) Aba Permissões: toggles do grupo
SELECT m.nome AS modulo,
       f.nome AS funcionalidade,
       p.id   AS permissao_id,
       p.nome AS permissao,
       (gp.grupo_id IS NOT NULL) AS habilitada
FROM permissao p
JOIN funcionalidade f ON f.id = p.funcionalidade_id
JOIN modulo m ON m.id = f.modulo_id
LEFT JOIN grupo_permissao gp
       ON gp.permissao_id = p.id AND gp.grupo_id = 4
ORDER BY m.id, f.id, p.id;

-- 14) Aba Usuários: checkbox de cada usuário
SELECT u.id,
       u.nome,
       u.email,
       EXISTS (SELECT 1 FROM usuario_grupo x
               WHERE x.usuario_id = u.id
                 AND x.grupo_id = 4) AS marcado,
       (SELECT string_agg(g.nome, ', ' ORDER BY g.nome)
          FROM usuario_grupo ug
          JOIN grupo g ON g.id = ug.grupo_id
         WHERE ug.usuario_id = u.id) AS grupos
FROM usuario u
ORDER BY u.nome;

-- 15) Adicionar grupo
BEGIN;
INSERT INTO grupo (nome) VALUES ('Análise de propostas');

INSERT INTO grupo_permissao (grupo_id, permissao_id)
SELECT g.id, p.id
FROM grupo g, permissao p
WHERE g.nome = 'Análise de propostas'
  AND p.id IN (6, 7, 9);

INSERT INTO usuario_grupo (usuario_id, grupo_id)
SELECT u.id, g.id
FROM usuario u, grupo g
WHERE g.nome = 'Análise de propostas' AND u.id IN (2, 4);
COMMIT;

-- 16) Salvar edição do grupo
BEGIN;
UPDATE grupo
SET nome = 'Análise de propostas e editais',
    atualizado_em = now()
WHERE id = 6;

DELETE FROM grupo_permissao WHERE grupo_id = 6;
INSERT INTO grupo_permissao (grupo_id, permissao_id)
VALUES (6, 6), (6, 7), (6, 9), (6, 11);

DELETE FROM usuario_grupo WHERE grupo_id = 6;
INSERT INTO usuario_grupo (usuario_id, grupo_id)
VALUES (2, 6), (4, 6);
COMMIT;

-- 17) Excluir grupo (vínculos saem por CASCADE)
DELETE FROM grupo WHERE id = 6;
