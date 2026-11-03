-- Dados de exemplo (baseados nas telas do enunciado)

INSERT INTO modulo (nome) VALUES ('Editais'), ('Contratos'), ('Financeiro');

INSERT INTO funcionalidade (modulo_id, nome) VALUES
  (1, 'Seleção de editais'),
  (1, 'Análise de editais'),
  (2, 'Consulta de CNPJ'),
  (2, 'Cadastro de contratos'),
  (3, 'Contas a receber');

INSERT INTO permissao (funcionalidade_id, codigo, nome) VALUES
  (1, 'EDITAL_VISUALIZAR',            'Visualizar editais'),
  (1, 'EDITAL_GERENCIAR_ANEXOS',      'Gerenciar anexos do edital'),
  (1, 'EDITAL_GERENCIAR_STATUS',      'Gerenciar status'),
  (1, 'EDITAL_ADICIONAR_MANUAL',      'Adicionar edital manualmente'),
  (1, 'EDITAL_GERENCIAR_GRUPOS',      'Gerenciar grupos de editais'),
  (2, 'ANALISE_GERENCIAR',            'Gerenciar análise de edital'),
  (2, 'ANALISE_VISUALIZAR_HISTORICO', 'Visualizar histórico de análise de edital'),
  (2, 'ANALISE_PRE_TECNICA',          'Realizar pré-análise técnica'),
  (2, 'ANALISE_REALIZAR',             'Realizar análise de edital'),
  (2, 'ANALISE_GERENCIAR_ETAPAS',     'Gerenciar etapas do edital'),
  (2, 'ANALISE_REALIZAR_PROPOSTA',    'Realizar proposta'),
  (2, 'ANALISE_GERENCIAR_HISTORICO',  'Gerenciar histórico de análise de edital'),
  (3, 'CNPJ_GERENCIAR_CONSULTA',      'Gerenciar consulta'),
  (4, 'CONTRATO_VISUALIZAR',          'Visualizar contratos'),
  (4, 'CONTRATO_CADASTRAR',           'Cadastrar contrato'),
  (4, 'CONTRATO_EDITAR',              'Editar contrato'),
  (5, 'RECEBER_VISUALIZAR',           'Visualizar contas a receber'),
  (5, 'RECEBER_REGISTRAR',            'Registrar recebimento');

INSERT INTO papel (nome) VALUES
  ('Analista de proposta'), ('Analista técnico'), ('Analista de documentos');

INSERT INTO grupo (nome) VALUES
  ('Cadastro de contratos'), ('Contas a receber'), ('Liderança de editais'),
  ('Seleção de editais'), ('Validação de CNPJ');

INSERT INTO grupo_permissao (grupo_id, permissao_id) VALUES
  (1, 14), (1, 15), (1, 16),
  (2, 17), (2, 18),
  (3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (3, 10), (3, 11), (3, 12),
  (4, 1), (4, 2), (4, 3), (4, 4), (4, 5),
  (5, 13), (5, 14);

INSERT INTO usuario (email, nome, ultimo_acesso) VALUES
  ('adailton@positivo.com.br',       'Adailton Araújo',   now() - interval '3 hours'),
  ('laishc@positivo.com.br',         'Laís Cândido',      now() - interval '6 hours'),
  ('usuario32024@positivo.com',      'Rodrigo Mendes',    now() - interval '30 minutes'),
  ('djuliads@positivo.com.br',       'Djulia dos Santos', now() - interval '1 day'),
  ('guilhermesousa@positivo.com.br', NULL,                NULL);

INSERT INTO usuario_grupo (usuario_id, grupo_id) VALUES
  (1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
  (2, 1), (2, 2), (2, 5),
  (3, 1), (3, 5),
  (4, 1), (4, 4),
  (5, 1), (5, 4);

INSERT INTO usuario_papel (usuario_id, papel_id) VALUES
  (1, 1), (1, 2), (1, 3),
  (2, 1),
  (3, 3),
  (4, 2);
