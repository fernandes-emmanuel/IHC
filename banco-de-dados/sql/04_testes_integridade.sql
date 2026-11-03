-- =====================================================================
--  Testes das restrições de integridade.
--  Todos os comandos abaixo DEVEM FALHAR: o erro mostra a restrição atuando.
--  Executar sem ON_ERROR_STOP:  psql -f 04_testes_integridade.sql
-- =====================================================================
SET search_path TO controle_acesso;

-- @T01 | PK | Vincular o mesmo usuário duas vezes ao mesmo grupo
INSERT INTO usuario_grupo (usuario_id, grupo_id) VALUES (1, 1);

-- @T02 | UNIQUE | E-mail repetido, mesmo com letras maiúsculas
INSERT INTO usuario (email) VALUES ('ADAILTON@positivo.com.br');

-- @T03 | CHECK | E-mail em formato inválido
INSERT INTO usuario (email) VALUES ('fulano');

-- @T04 | FK | Vincular um grupo inexistente
INSERT INTO usuario_grupo (usuario_id, grupo_id) VALUES (1, 999);

-- @T05 | FK RESTRICT | Excluir um papel que ainda está em uso
DELETE FROM papel WHERE nome = 'Analista técnico';

-- @T06 | RN1 | Cadastrar usuário sem nenhum grupo ("Grupo *" é obrigatório)
INSERT INTO usuario (email) VALUES ('sem.grupo@positivo.com.br');

-- @T07 | RN1 | Remover o único grupo de um usuário
BEGIN;
INSERT INTO usuario (email) VALUES ('so.um.grupo@positivo.com.br');
INSERT INTO usuario_grupo (usuario_id, grupo_id)
SELECT id, 5 FROM usuario WHERE email = 'so.um.grupo@positivo.com.br';
COMMIT;
DELETE FROM grupo WHERE id = 5;   -- o usuário acima ficaria sem grupo

-- @T08 | RN2 | Habilitar permissão sem habilitar a permissão-requisito
INSERT INTO grupo_permissao (grupo_id, permissao_id)
SELECT 2, id FROM permissao WHERE codigo = 'CONTRATO_EDITAR';

-- @T09 | RN2 | Desabilitar "Visualizar editais" mantendo as permissões dependentes
DELETE FROM grupo_permissao
 WHERE grupo_id = 4
   AND permissao_id = (SELECT id FROM permissao WHERE codigo = 'EDITAL_VISUALIZAR');

-- @T10 | CHECK | Segunda linha na configuração do AD (tabela de linha única)
INSERT INTO configuracao_ad (id, tenant_id, client_id, grupo_ad_object_id, grupo_ad_nome, dominio_email)
VALUES (2, gen_random_uuid(), gen_random_uuid(), gen_random_uuid(), 'OUTRO', 'outra.com');

-- Limpeza: remove o usuário criado no teste T07
DELETE FROM usuario WHERE email = 'so.um.grupo@positivo.com.br';
