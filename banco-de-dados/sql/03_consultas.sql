-- =====================================================================
--  Consultas SQL que atendem às interfaces do Módulo de Controle de Acessos
--  PostgreSQL 16 — executar após 01_modelo_fisico.sql e 02_dados_exemplo.sql
--
--  Parâmetros: escritos como variáveis do psql (:'email', :grupo_id, …).
--  Na aplicação, cada variável vira um parâmetro preparado ($1, $2, …),
--  o que evita SQL injection.
--
--  Cada consulta começa com uma linha "-- @Cnn | Tela | Título".
-- =====================================================================
SET search_path TO controle_acesso;

-- Valores de exemplo dos parâmetros ------------------------------------
\set email        'adailton@positivo.com.br'
\set nome_ad      'Adailton Araújo'
\set oid_ad       'a0000000-0000-4000-8000-000000000001'
\set ip           '10.0.0.10'
\set user_agent   'Mozilla/5.0'
\set usuario_id   1
\set admin_id     1
\set grupo_id     4
\set busca        'positivo'
\set busca_grupo  'editais'
\set limite       20
\set deslocamento 0
\set permissao    'EDITAL_GERENCIAR_STATUS'
\set novo_email   'maria.lima@positivo.com.br'
\set grupos       '{1,4}'
\set papeis       '{2}'
\set nome_grupo   'Análise de propostas'
\set permissoes   '{6,7,8,9,11}'
\set usuarios     '{1,2,4}'
-- usados nas telas de edição (agem sobre o usuário/grupo criados em C12/C21)
\set email_edicao      'maria.silva@positivo.com.br'
\set grupos_edicao     '{1,2}'
\set papeis_edicao     '{1,3}'
\set nome_grupo_edicao 'Análise de propostas e editais'
\set permissoes_edicao '{6,7,9,12}'
\set usuarios_edicao   '{2,4}'


-- #####################################################################
-- TELA 1 — LOGIN COM ACTIVE DIRECTORY ("Entrar com Microsoft")
-- #####################################################################

-- @C01 | Login | Parâmetros do Active Directory
-- Monta o redirecionamento para a Microsoft e informa qual grupo do AD
-- deve constar no token ("groups") para o acesso ser permitido.
SELECT tenant_id, client_id, grupo_ad_object_id, grupo_ad_nome, dominio_email
  FROM configuracao_ad
 WHERE id = 1;

-- @C02 | Login | Autorizar o e-mail retornado pelo AD
-- Depois que o AD autentica (a senha fica só no AD), a plataforma confere se o
-- e-mail corporativo está cadastrado e ativo. Nenhuma linha retornada = acesso negado.
SELECT u.id, u.email, u.nome, u.ativo
  FROM usuario u
 WHERE lower(u.email) = lower(:'email');

-- @C03 | Login | Registrar login com sucesso e atualizar o nome vindo do AD
-- O nome não é digitado no cadastro: a plataforma o atualiza a cada autorização.
WITH atualizado AS (
  UPDATE usuario
     SET nome             = :'nome_ad',
         ad_object_id     = :'oid_ad'::uuid,
         ultimo_acesso_em = now()
   WHERE lower(email) = lower(:'email')
     AND ativo
  RETURNING id, email, nome, ultimo_acesso_em
), registro AS (
  INSERT INTO registro_acesso (usuario_id, email_informado, resultado, endereco_ip, user_agent)
  SELECT id, email, 'SUCESSO', :'ip'::inet, :'user_agent' FROM atualizado
  RETURNING id
)
SELECT a.id AS usuario_id, a.nome, a.email, a.ultimo_acesso_em
  FROM atualizado a;

-- @C04 | Login | Registrar tentativa de login negada
-- resultado: NAO_CADASTRADO (e-mail fora da base), FORA_GRUPO_AD ou INATIVO.
INSERT INTO registro_acesso (usuario_id, email_informado, resultado, endereco_ip, user_agent)
SELECT (SELECT id FROM usuario WHERE lower(email) = lower('visitante@gmail.com')),
       'visitante@gmail.com', 'NAO_CADASTRADO', :'ip'::inet, :'user_agent'
RETURNING id, email_informado, resultado, ocorrido_em;

-- @C05 | Login | Permissões efetivas do usuário (carregadas na sessão)
-- O usuário acessa tudo que estiver habilitado em QUALQUER um dos seus grupos.
SELECT DISTINCT p.codigo, p.nome
  FROM usuario_grupo   ug
  JOIN grupo_permissao gp ON gp.grupo_id = ug.grupo_id
  JOIN permissao       p  ON p.id = gp.permissao_id
 WHERE ug.usuario_id = :usuario_id
 ORDER BY p.codigo;

-- @C06 | Login | Menu lateral: módulos e funcionalidades liberados
SELECT m.nome AS modulo, f.nome AS funcionalidade, count(DISTINCT p.id) AS permissoes
  FROM usuario_grupo   ug
  JOIN grupo_permissao gp ON gp.grupo_id = ug.grupo_id
  JOIN permissao       p  ON p.id = gp.permissao_id
  JOIN funcionalidade  f  ON f.id = p.funcionalidade_id
  JOIN modulo          m  ON m.id = f.modulo_id
 WHERE ug.usuario_id = :usuario_id
 GROUP BY m.ordem, m.nome, f.ordem, f.nome
 ORDER BY m.ordem, f.ordem;

-- @C07 | Todas as telas | O usuário tem a permissão X?
-- Usada pelo back-end antes de cada ação protegida.
SELECT EXISTS (
  SELECT 1
    FROM usuario         u
    JOIN usuario_grupo   ug ON ug.usuario_id = u.id
    JOIN grupo_permissao gp ON gp.grupo_id = ug.grupo_id
    JOIN permissao       p  ON p.id = gp.permissao_id
   WHERE u.id = :usuario_id
     AND u.ativo
     AND p.codigo = :'permissao'
) AS autorizado;


-- #####################################################################
-- TELA 2 — PERMISSÕES › ABA USUÁRIOS
-- #####################################################################

-- @C08 | Permissões › Usuários | Listagem com busca e paginação
-- Colunas: USUÁRIO (nome + e-mail), GRUPO, PAPEL, ÚLTIMO ACESSO.
-- "Buscar por usuário" filtra por nome ou e-mail; total_registros serve à paginação.
SELECT u.id,
       COALESCE(u.nome, '-')            AS nome,
       u.email,
       COALESCE(g.grupos, '')           AS grupos,
       COALESCE(p.papeis, '-')          AS papeis,
       fn_tempo_desde(u.ultimo_acesso_em) AS ultimo_acesso,
       count(*) OVER ()                 AS total_registros
  FROM usuario u
  LEFT JOIN LATERAL (
       SELECT string_agg(gr.nome, ', ' ORDER BY gr.nome) AS grupos
         FROM usuario_grupo ug JOIN grupo gr ON gr.id = ug.grupo_id
        WHERE ug.usuario_id = u.id) g ON true
  LEFT JOIN LATERAL (
       SELECT string_agg(pa.nome, ', ' ORDER BY pa.nome) AS papeis
         FROM usuario_papel up JOIN papel pa ON pa.id = up.papel_id
        WHERE up.usuario_id = u.id) p ON true
 WHERE :'busca' = ''
    OR u.nome  ILIKE '%' || :'busca' || '%'
    OR u.email ILIKE '%' || :'busca' || '%'
 ORDER BY u.nome NULLS LAST, u.email
 LIMIT :limite OFFSET :deslocamento;

-- @C09 | Adicionar usuário | Opções do campo "Grupo *"
SELECT id, nome FROM grupo ORDER BY nome;

-- @C10 | Adicionar usuário | Opções do campo "Papel"
SELECT id, nome FROM papel ORDER BY nome;

-- @C11 | Adicionar usuário | Validar se o e-mail já está cadastrado
SELECT EXISTS (SELECT 1 FROM usuario WHERE lower(email) = lower(btrim(:'novo_email'))) AS email_ja_cadastrado;

-- @C12 | Adicionar usuário | Inserir usuário com grupos e papéis
-- Um único comando: o trigger adiado RN1 confere no COMMIT se há pelo menos 1 grupo.
WITH novo AS (
  INSERT INTO usuario (email, criado_por_id, atualizado_por_id)
  VALUES (lower(btrim(:'novo_email')), :admin_id, :admin_id)
  RETURNING id, email
), grupos AS (
  INSERT INTO usuario_grupo (usuario_id, grupo_id, criado_por_id)
  SELECT novo.id, g, :admin_id FROM novo, unnest(:'grupos'::bigint[]) AS g
  RETURNING grupo_id
), papeis AS (
  INSERT INTO usuario_papel (usuario_id, papel_id, criado_por_id)
  SELECT novo.id, p, :admin_id FROM novo, unnest(:'papeis'::smallint[]) AS p
  RETURNING papel_id
)
SELECT novo.id, novo.email,
       (SELECT count(*) FROM grupos) AS grupos_vinculados,
       (SELECT count(*) FROM papeis) AS papeis_vinculados
  FROM novo
\gset novo_
SELECT :novo_id AS id_criado;

-- @C13 | Editar usuário | Carregar o usuário no formulário
SELECT u.id, u.email, u.nome,
       ARRAY(SELECT grupo_id FROM usuario_grupo WHERE usuario_id = u.id ORDER BY grupo_id) AS grupo_ids,
       ARRAY(SELECT papel_id FROM usuario_papel WHERE usuario_id = u.id ORDER BY papel_id) AS papel_ids
  FROM usuario u
 WHERE u.id = :usuario_id;

-- @C14 | Editar usuário | Salvar e-mail, grupos e papéis
-- Sincroniza os vínculos: remove os desmarcados e insere os novos.
-- (no exemplo, edita o usuário criado em C12)
BEGIN;
UPDATE usuario
   SET email = lower(btrim(:'email_edicao')), atualizado_por_id = :admin_id
 WHERE id = :novo_id;

DELETE FROM usuario_grupo
 WHERE usuario_id = :novo_id AND grupo_id <> ALL (:'grupos_edicao'::bigint[]);
INSERT INTO usuario_grupo (usuario_id, grupo_id, criado_por_id)
SELECT :novo_id, g, :admin_id FROM unnest(:'grupos_edicao'::bigint[]) AS g
ON CONFLICT DO NOTHING;

DELETE FROM usuario_papel
 WHERE usuario_id = :novo_id AND papel_id <> ALL (:'papeis_edicao'::smallint[]);
INSERT INTO usuario_papel (usuario_id, papel_id, criado_por_id)
SELECT :novo_id, p, :admin_id FROM unnest(:'papeis_edicao'::smallint[]) AS p
ON CONFLICT DO NOTHING;
COMMIT;

-- @C15 | Permissões › Usuários | Excluir usuário (ícone da lixeira)
-- Os vínculos com grupos e papéis são removidos em cascata (ON DELETE CASCADE);
-- o histórico em registro_acesso é mantido (ON DELETE SET NULL).
-- (no exemplo, exclui o usuário criado em C12)
DELETE FROM usuario
 WHERE id = :novo_id
RETURNING id, email;


-- #####################################################################
-- TELA 3 — PERMISSÕES › ABA GRUPOS
-- #####################################################################

-- @C16 | Permissões › Grupos | Listagem com busca
-- Colunas: GRUPO, PERMISSÕES (habilitadas), USUÁRIOS (vinculados).
SELECT g.id, g.nome,
       (SELECT count(*) FROM grupo_permissao gp WHERE gp.grupo_id = g.id) AS permissoes,
       (SELECT count(*) FROM usuario_grupo  ug WHERE ug.grupo_id = g.id) AS usuarios
  FROM grupo g
 WHERE :'busca_grupo' = '' OR g.nome ILIKE '%' || :'busca_grupo' || '%'
 ORDER BY g.nome;

-- @C17 | Permissões › Grupos | Usuários do grupo (ícone de usuários)
SELECT u.id, COALESCE(u.nome, '-') AS nome, u.email
  FROM usuario_grupo ug
  JOIN usuario u ON u.id = ug.usuario_id
 WHERE ug.grupo_id = :grupo_id
 ORDER BY u.nome NULLS LAST, u.email;


-- #####################################################################
-- TELA 4 — ADICIONAR / EDITAR GRUPO
-- #####################################################################

-- @C18 | Grupo › aba Permissões | Toggles agrupados por módulo e funcionalidade
-- habilitada = estado do toggle; bloqueada = o toggle fica cinza porque a
-- permissão-requisito não está habilitada. Para "Adicionar grupo", use
-- grupo_id = 0 (nenhum toggle habilitado).
SELECT m.nome  AS modulo,
       f.nome  AS funcionalidade,
       p.id    AS permissao_id,
       p.nome  AS permissao,
       (gp.permissao_id IS NOT NULL) AS habilitada,
       (p.permissao_requisito_id IS NOT NULL AND req.permissao_id IS NULL) AS bloqueada
  FROM permissao p
  JOIN funcionalidade f ON f.id = p.funcionalidade_id
  JOIN modulo         m ON m.id = f.modulo_id
  LEFT JOIN grupo_permissao gp  ON gp.permissao_id  = p.id
                               AND gp.grupo_id      = :grupo_id
  LEFT JOIN grupo_permissao req ON req.permissao_id = p.permissao_requisito_id
                               AND req.grupo_id     = :grupo_id
 ORDER BY m.ordem, f.ordem, p.ordem;

-- @C19 | Grupo › aba Usuários | Usuários com checkbox e grupos atuais
-- marcado = o usuário já pertence ao grupo editado.
SELECT u.id,
       COALESCE(u.nome, split_part(u.email, '@', 1)) AS nome,
       u.email,
       EXISTS (SELECT 1 FROM usuario_grupo x
                WHERE x.usuario_id = u.id AND x.grupo_id = :grupo_id) AS marcado,
       (SELECT string_agg(g.nome, ', ' ORDER BY g.nome)
          FROM usuario_grupo ug JOIN grupo g ON g.id = ug.grupo_id
         WHERE ug.usuario_id = u.id) AS grupos
  FROM usuario u
 WHERE u.ativo
 ORDER BY nome;

-- @C20 | Adicionar grupo | Validar se o nome do grupo já existe
SELECT EXISTS (SELECT 1 FROM grupo WHERE lower(nome) = lower(btrim(:'nome_grupo'))) AS nome_ja_existe;

-- @C21 | Adicionar grupo | Inserir grupo com permissões e usuários
-- O trigger adiado RN2 garante que os requisitos das permissões também foram habilitados.
WITH novo AS (
  INSERT INTO grupo (nome, criado_por_id, atualizado_por_id)
  VALUES (btrim(:'nome_grupo'), :admin_id, :admin_id)
  RETURNING id, nome
), perms AS (
  INSERT INTO grupo_permissao (grupo_id, permissao_id, concedida_por_id)
  SELECT novo.id, p, :admin_id FROM novo, unnest(:'permissoes'::int[]) AS p
  RETURNING permissao_id
), membros AS (
  INSERT INTO usuario_grupo (usuario_id, grupo_id, criado_por_id)
  SELECT u, novo.id, :admin_id FROM novo, unnest(:'usuarios'::bigint[]) AS u
  RETURNING usuario_id
)
SELECT novo.id, novo.nome,
       (SELECT count(*) FROM perms)   AS permissoes,
       (SELECT count(*) FROM membros) AS usuarios
  FROM novo
\gset novo_grupo_
SELECT :novo_grupo_id AS id_criado;

-- @C22 | Editar grupo | Salvar nome, permissões (toggles) e usuários
-- (no exemplo, edita o grupo criado em C21)
BEGIN;
UPDATE grupo
   SET nome = btrim(:'nome_grupo_edicao'), atualizado_por_id = :admin_id
 WHERE id = :novo_grupo_id;

DELETE FROM grupo_permissao
 WHERE grupo_id = :novo_grupo_id AND permissao_id <> ALL (:'permissoes_edicao'::int[]);
INSERT INTO grupo_permissao (grupo_id, permissao_id, concedida_por_id)
SELECT :novo_grupo_id, p, :admin_id FROM unnest(:'permissoes_edicao'::int[]) AS p
ON CONFLICT DO NOTHING;

DELETE FROM usuario_grupo
 WHERE grupo_id = :novo_grupo_id AND usuario_id <> ALL (:'usuarios_edicao'::bigint[]);
INSERT INTO usuario_grupo (usuario_id, grupo_id, criado_por_id)
SELECT u, :novo_grupo_id, :admin_id FROM unnest(:'usuarios_edicao'::bigint[]) AS u
ON CONFLICT DO NOTHING;
COMMIT;

-- @C23 | Excluir grupo | Usuários que ficariam sem nenhum grupo
-- Exibido na confirmação; se retornar linhas, a exclusão é barrada pela RN1.
-- (no exemplo, verifica o grupo criado em C21)
SELECT u.id, COALESCE(u.nome, '-') AS nome, u.email
  FROM usuario_grupo ug
  JOIN usuario u ON u.id = ug.usuario_id
 WHERE ug.grupo_id = :novo_grupo_id
   AND NOT EXISTS (SELECT 1 FROM usuario_grupo o
                    WHERE o.usuario_id = ug.usuario_id AND o.grupo_id <> ug.grupo_id);

-- @C24 | Excluir grupo | Excluir o grupo
-- Permissões e vínculos com usuários são removidos em cascata.
-- (no exemplo, exclui o grupo criado em C21)
DELETE FROM grupo
 WHERE id = :novo_grupo_id
RETURNING id, nome;
