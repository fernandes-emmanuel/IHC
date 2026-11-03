-- =====================================================================
--  Dados de exemplo (os mesmos nomes que aparecem nas telas do enunciado)
-- =====================================================================
SET search_path TO controle_acesso;

BEGIN;

INSERT INTO configuracao_ad (tenant_id, client_id, grupo_ad_object_id, grupo_ad_nome, dominio_email)
VALUES ('6f1d2c3b-0000-4000-8000-000000000001', '6f1d2c3b-0000-4000-8000-000000000002',
        '6f1d2c3b-0000-4000-8000-000000000003', 'GRP-PLATAFORMA-EDITAIS', 'positivo.com.br');

-- Catálogo de funcionalidades -----------------------------------------
INSERT INTO modulo (codigo, nome, ordem) VALUES
  ('EDITAIS',    'Editais',    1),
  ('CONTRATOS',  'Contratos',  2),
  ('FINANCEIRO', 'Financeiro', 3);

INSERT INTO funcionalidade (modulo_id, codigo, nome, ordem)
SELECT m.id, f.codigo, f.nome, f.ordem
  FROM (VALUES ('EDITAIS',    'SELECAO_EDITAIS',    'Seleção de editais',    1),
               ('EDITAIS',    'ANALISE_EDITAIS',    'Análise de editais',    2),
               ('CONTRATOS',  'CONSULTA_CNPJ',      'Consulta de CNPJ',      1),
               ('CONTRATOS',  'CADASTRO_CONTRATOS', 'Cadastro de contratos', 2),
               ('FINANCEIRO', 'CONTAS_RECEBER',     'Contas a receber',      1)
       ) AS f(modulo, codigo, nome, ordem)
  JOIN modulo m ON m.codigo = f.modulo
 ORDER BY m.ordem, f.ordem;

INSERT INTO permissao (funcionalidade_id, codigo, nome, ordem)
SELECT fu.id, p.codigo, p.nome, p.ordem
  FROM (VALUES
    ('SELECAO_EDITAIS',    'EDITAL_VISUALIZAR',            'Visualizar editais',                      1),
    ('SELECAO_EDITAIS',    'EDITAL_GERENCIAR_ANEXOS',      'Gerenciar anexos do edital',              2),
    ('SELECAO_EDITAIS',    'EDITAL_GERENCIAR_STATUS',      'Gerenciar status',                        3),
    ('SELECAO_EDITAIS',    'EDITAL_ADICIONAR_MANUAL',      'Adicionar edital manualmente',            4),
    ('SELECAO_EDITAIS',    'EDITAL_GERENCIAR_GRUPOS',      'Gerenciar grupos de editais',             5),
    ('ANALISE_EDITAIS',    'ANALISE_GERENCIAR',            'Gerenciar análise de edital',             1),
    ('ANALISE_EDITAIS',    'ANALISE_VISUALIZAR_HISTORICO', 'Visualizar histórico de análise de edital',2),
    ('ANALISE_EDITAIS',    'ANALISE_PRE_TECNICA',          'Realizar pré-análise técnica',            3),
    ('ANALISE_EDITAIS',    'ANALISE_REALIZAR',             'Realizar análise de edital',              4),
    ('ANALISE_EDITAIS',    'ANALISE_GERENCIAR_ETAPAS',     'Gerenciar etapas do edital',              5),
    ('ANALISE_EDITAIS',    'ANALISE_REALIZAR_PROPOSTA',    'Realizar proposta',                       6),
    ('ANALISE_EDITAIS',    'ANALISE_GERENCIAR_HISTORICO',  'Gerenciar histórico de análise de edital',7),
    ('CONSULTA_CNPJ',      'CNPJ_GERENCIAR_CONSULTA',      'Gerenciar consulta',                      1),
    ('CADASTRO_CONTRATOS', 'CONTRATO_VISUALIZAR',          'Visualizar contratos',                    1),
    ('CADASTRO_CONTRATOS', 'CONTRATO_CADASTRAR',           'Cadastrar contrato',                      2),
    ('CADASTRO_CONTRATOS', 'CONTRATO_EDITAR',              'Editar contrato',                         3),
    ('CADASTRO_CONTRATOS', 'CONTRATO_EXCLUIR',             'Excluir contrato',                        4),
    ('CONTAS_RECEBER',     'RECEBER_VISUALIZAR',           'Visualizar contas a receber',             1),
    ('CONTAS_RECEBER',     'RECEBER_REGISTRAR',            'Registrar recebimento',                   2)
  ) AS p(funcionalidade, codigo, nome, ordem)
  JOIN funcionalidade fu ON fu.codigo = p.funcionalidade
 ORDER BY fu.id, p.ordem;

-- Dependências entre permissões (toggles desabilitados na tela)
UPDATE permissao p
   SET permissao_requisito_id = r.id
  FROM (VALUES ('EDITAL_GERENCIAR_ANEXOS',     'EDITAL_VISUALIZAR'),
               ('EDITAL_GERENCIAR_STATUS',     'EDITAL_VISUALIZAR'),
               ('EDITAL_ADICIONAR_MANUAL',     'EDITAL_VISUALIZAR'),
               ('EDITAL_GERENCIAR_GRUPOS',     'EDITAL_VISUALIZAR'),
               ('ANALISE_GERENCIAR_HISTORICO', 'ANALISE_VISUALIZAR_HISTORICO'),
               ('CONTRATO_CADASTRAR',          'CONTRATO_VISUALIZAR'),
               ('CONTRATO_EDITAR',             'CONTRATO_VISUALIZAR'),
               ('CONTRATO_EXCLUIR',            'CONTRATO_VISUALIZAR'),
               ('RECEBER_REGISTRAR',           'RECEBER_VISUALIZAR')
       ) AS d(permissao, requisito)
  JOIN permissao r ON r.codigo = d.requisito
 WHERE p.codigo = d.permissao;

-- Papéis ----------------------------------------------------------------
INSERT INTO papel (nome) VALUES
  ('Analista de proposta'), ('Analista técnico'), ('Analista de documentos');

-- Grupos e suas permissões ---------------------------------------------
INSERT INTO grupo (nome) VALUES
  ('Cadastro de contratos'), ('Contas a receber'), ('Liderança de editais'),
  ('Seleção de editais'), ('Validação de CNPJ');

INSERT INTO grupo_permissao (grupo_id, permissao_id)
SELECT g.id, p.id
  FROM (VALUES
    ('Cadastro de contratos', 'CONTRATO_VISUALIZAR'),
    ('Cadastro de contratos', 'CONTRATO_CADASTRAR'),
    ('Cadastro de contratos', 'CONTRATO_EDITAR'),
    ('Contas a receber',      'RECEBER_VISUALIZAR'),
    ('Contas a receber',      'RECEBER_REGISTRAR'),
    ('Validação de CNPJ',     'CNPJ_GERENCIAR_CONSULTA'),
    ('Validação de CNPJ',     'CONTRATO_VISUALIZAR')
  ) AS x(grupo, permissao)
  JOIN grupo g     ON g.nome = x.grupo
  JOIN permissao p ON p.codigo = x.permissao;

-- Seleção de editais = todas as permissões da funcionalidade
INSERT INTO grupo_permissao (grupo_id, permissao_id)
SELECT g.id, p.id
  FROM grupo g, permissao p JOIN funcionalidade f ON f.id = p.funcionalidade_id
 WHERE g.nome = 'Seleção de editais' AND f.codigo = 'SELECAO_EDITAIS';

-- Liderança de editais = todas as permissões do módulo EDITAIS
INSERT INTO grupo_permissao (grupo_id, permissao_id)
SELECT g.id, p.id
  FROM grupo g, permissao p
  JOIN funcionalidade f ON f.id = p.funcionalidade_id
  JOIN modulo m         ON m.id = f.modulo_id
 WHERE g.nome = 'Liderança de editais' AND m.codigo = 'EDITAIS';

-- Usuários (o nome vem do AD; Guilherme ainda não acessou → nome NULL) --
INSERT INTO usuario (email, nome, ad_object_id, ultimo_acesso_em) VALUES
  ('adailton@positivo.com.br',        'Adailton Araújo',  'a0000000-0000-4000-8000-000000000001', now() - interval '3 hours'),
  ('laishc@positivo.com.br',          'Laís Cândido',     'a0000000-0000-4000-8000-000000000002', now() - interval '6 hours'),
  ('usuario32024@positivo.com',       'Rodrigo Mendes',   'a0000000-0000-4000-8000-000000000003', now() - interval '30 minutes'),
  ('djuliads@positivo.com.br',        'Djulia dos Santos','a0000000-0000-4000-8000-000000000004', now() - interval '1 day'),
  ('guilhermesousa@positivo.com.br',  NULL,               NULL,                                   NULL);

INSERT INTO usuario_grupo (usuario_id, grupo_id)
SELECT u.id, g.id
  FROM (VALUES
    ('adailton@positivo.com.br',       'Cadastro de contratos'),
    ('adailton@positivo.com.br',       'Validação de CNPJ'),
    ('adailton@positivo.com.br',       'Contas a receber'),
    ('adailton@positivo.com.br',       'Liderança de editais'),
    ('adailton@positivo.com.br',       'Seleção de editais'),
    ('laishc@positivo.com.br',         'Validação de CNPJ'),
    ('laishc@positivo.com.br',         'Seleção de editais'),
    ('laishc@positivo.com.br',         'Contas a receber'),
    ('usuario32024@positivo.com',      'Cadastro de contratos'),
    ('usuario32024@positivo.com',      'Validação de CNPJ'),
    ('djuliads@positivo.com.br',       'Cadastro de contratos'),
    ('djuliads@positivo.com.br',       'Seleção de editais'),
    ('guilhermesousa@positivo.com.br', 'Cadastro de contratos'),
    ('guilhermesousa@positivo.com.br', 'Seleção de editais')
  ) AS x(email, grupo)
  JOIN usuario u ON u.email = x.email
  JOIN grupo g   ON g.nome = x.grupo;

INSERT INTO usuario_papel (usuario_id, papel_id)
SELECT u.id, p.id
  FROM (VALUES
    ('adailton@positivo.com.br', 'Analista de proposta'),
    ('adailton@positivo.com.br', 'Analista técnico'),
    ('adailton@positivo.com.br', 'Analista de documentos'),
    ('laishc@positivo.com.br',   'Analista de proposta'),
    ('usuario32024@positivo.com','Analista de documentos'),
    ('djuliads@positivo.com.br', 'Analista técnico')
  ) AS x(email, papel)
  JOIN usuario u ON u.email = x.email
  JOIN papel p   ON p.nome = x.papel;

INSERT INTO registro_acesso (usuario_id, email_informado, resultado, endereco_ip, ocorrido_em)
SELECT id, email, 'SUCESSO', '10.0.0.10', ultimo_acesso_em
  FROM usuario WHERE ultimo_acesso_em IS NOT NULL;

INSERT INTO registro_acesso (usuario_id, email_informado, resultado, endereco_ip, ocorrido_em)
VALUES (NULL, 'visitante@gmail.com', 'NAO_CADASTRADO', '200.1.2.3', now() - interval '2 hours');

COMMIT;
