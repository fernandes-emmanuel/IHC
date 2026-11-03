-- =====================================================================
--  Módulo de Controle de Acessos de uma plataforma WEB
--  Modelo físico — PostgreSQL 16
--
--  Convenções
--    * schema  : controle_acesso
--    * nomes   : snake_case, singular; PK "id"; FK "<tabela>_id"
--    * técnicos: criado_em / atualizado_em / criado_por_id / atualizado_por_id
--    * a SENHA NÃO É ARMAZENADA: a autenticação é feita no Active Directory
--      (Microsoft Entra ID) via OpenID Connect. A plataforma guarda apenas o
--      e-mail corporativo autorizado e os dados vindos do token do AD.
-- =====================================================================

DROP SCHEMA IF EXISTS controle_acesso CASCADE;
CREATE SCHEMA controle_acesso;
SET search_path TO controle_acesso;

-- ---------------------------------------------------------------------
-- Função utilitária: mantém "atualizado_em" sempre correto
-- ---------------------------------------------------------------------
CREATE FUNCTION fn_atualiza_timestamp() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.atualizado_em := now();
  RETURN NEW;
END $$;

-- =====================================================================
-- 1. CONFIGURAÇÃO DO ACTIVE DIRECTORY (tabela de linha única)
--    Identifica o tenant e o GRUPO do AD cujos membros podem acessar.
--    O "client secret" fica no cofre de segredos da aplicação, nunca aqui.
-- =====================================================================
CREATE TABLE configuracao_ad (
  id                  smallint     PRIMARY KEY DEFAULT 1,
  tenant_id           uuid         NOT NULL,
  client_id           uuid         NOT NULL,
  grupo_ad_object_id  uuid         NOT NULL,
  grupo_ad_nome       varchar(150) NOT NULL,
  dominio_email       varchar(120) NOT NULL,            -- ex.: positivo.com.br
  atualizado_em       timestamptz  NOT NULL DEFAULT now(),
  CONSTRAINT ck_configuracao_ad_linha_unica CHECK (id = 1),
  CONSTRAINT ck_configuracao_ad_dominio     CHECK (dominio_email ~ '^[a-z0-9.-]+\.[a-z]{2,}$')
);
CREATE TRIGGER tg_configuracao_ad_atualizado BEFORE UPDATE ON configuracao_ad
  FOR EACH ROW EXECUTE FUNCTION fn_atualiza_timestamp();

-- =====================================================================
-- 2. USUÁRIO
--    "nome" não é digitado no cadastro: é preenchido/atualizado a partir
--    do AD a cada login (por isso é NULL até o primeiro acesso).
-- =====================================================================
CREATE TABLE usuario (
  id                 bigint       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email              varchar(254) NOT NULL,
  nome               varchar(150),
  ad_object_id       uuid,                               -- "oid" do usuário no AD
  ativo              boolean      NOT NULL DEFAULT true,
  ultimo_acesso_em   timestamptz,                        -- NULL = "Nunca acessou"
  criado_em          timestamptz  NOT NULL DEFAULT now(),
  atualizado_em      timestamptz  NOT NULL DEFAULT now(),
  criado_por_id      bigint,
  atualizado_por_id  bigint,
  CONSTRAINT ck_usuario_email_formato CHECK (email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  CONSTRAINT ck_usuario_nome_vazio    CHECK (nome IS NULL OR btrim(nome) <> ''),
  CONSTRAINT uq_usuario_ad_object_id  UNIQUE (ad_object_id),
  CONSTRAINT fk_usuario_criado_por     FOREIGN KEY (criado_por_id)
             REFERENCES usuario (id) ON DELETE SET NULL,
  CONSTRAINT fk_usuario_atualizado_por FOREIGN KEY (atualizado_por_id)
             REFERENCES usuario (id) ON DELETE SET NULL
);
-- e-mail único sem diferenciar maiúsculas/minúsculas (é a chave de login)
CREATE UNIQUE INDEX uq_usuario_email_lower ON usuario (lower(email));
-- busca da tela "Buscar por usuário" (nome ou e-mail)
CREATE INDEX ix_usuario_nome_lower ON usuario (lower(nome));
CREATE TRIGGER tg_usuario_atualizado BEFORE UPDATE ON usuario
  FOR EACH ROW EXECUTE FUNCTION fn_atualiza_timestamp();

-- =====================================================================
-- 3. PAPEL (ex.: Analista de proposta, Analista técnico)
--    Opcional para o usuário (0..N).
-- =====================================================================
CREATE TABLE papel (
  id             smallint     GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome           varchar(80)  NOT NULL,
  descricao      varchar(255),
  criado_em      timestamptz  NOT NULL DEFAULT now(),
  atualizado_em  timestamptz  NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX uq_papel_nome_lower ON papel (lower(nome));
CREATE TRIGGER tg_papel_atualizado BEFORE UPDATE ON papel
  FOR EACH ROW EXECUTE FUNCTION fn_atualiza_timestamp();

-- Associativa USUÁRIO x PAPEL (N:N)
CREATE TABLE usuario_papel (
  usuario_id     bigint      NOT NULL,
  papel_id       smallint    NOT NULL,
  criado_em      timestamptz NOT NULL DEFAULT now(),
  criado_por_id  bigint,
  CONSTRAINT pk_usuario_papel PRIMARY KEY (usuario_id, papel_id),
  CONSTRAINT fk_usuario_papel_usuario FOREIGN KEY (usuario_id)
             REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT fk_usuario_papel_papel   FOREIGN KEY (papel_id)
             REFERENCES papel (id)   ON DELETE RESTRICT,
  CONSTRAINT fk_usuario_papel_criado_por FOREIGN KEY (criado_por_id)
             REFERENCES usuario (id) ON DELETE SET NULL
);
CREATE INDEX ix_usuario_papel_papel ON usuario_papel (papel_id);

-- =====================================================================
-- 4. GRUPO DE USUÁRIOS
-- =====================================================================
CREATE TABLE grupo (
  id                 bigint       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome               varchar(100) NOT NULL,
  descricao          varchar(255),
  criado_em          timestamptz  NOT NULL DEFAULT now(),
  atualizado_em      timestamptz  NOT NULL DEFAULT now(),
  criado_por_id      bigint,
  atualizado_por_id  bigint,
  CONSTRAINT ck_grupo_nome_vazio CHECK (btrim(nome) <> ''),
  CONSTRAINT fk_grupo_criado_por     FOREIGN KEY (criado_por_id)
             REFERENCES usuario (id) ON DELETE SET NULL,
  CONSTRAINT fk_grupo_atualizado_por FOREIGN KEY (atualizado_por_id)
             REFERENCES usuario (id) ON DELETE SET NULL
);
CREATE UNIQUE INDEX uq_grupo_nome_lower ON grupo (lower(nome));
CREATE TRIGGER tg_grupo_atualizado BEFORE UPDATE ON grupo
  FOR EACH ROW EXECUTE FUNCTION fn_atualiza_timestamp();

-- Associativa USUÁRIO x GRUPO (N:N). Todo usuário deve ter >= 1 grupo.
CREATE TABLE usuario_grupo (
  usuario_id     bigint      NOT NULL,
  grupo_id       bigint      NOT NULL,
  criado_em      timestamptz NOT NULL DEFAULT now(),
  criado_por_id  bigint,
  CONSTRAINT pk_usuario_grupo PRIMARY KEY (usuario_id, grupo_id),
  CONSTRAINT fk_usuario_grupo_usuario FOREIGN KEY (usuario_id)
             REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT fk_usuario_grupo_grupo   FOREIGN KEY (grupo_id)
             REFERENCES grupo (id)   ON DELETE CASCADE,
  CONSTRAINT fk_usuario_grupo_criado_por FOREIGN KEY (criado_por_id)
             REFERENCES usuario (id) ON DELETE SET NULL
);
CREATE INDEX ix_usuario_grupo_grupo ON usuario_grupo (grupo_id);

-- =====================================================================
-- 5. CATÁLOGO DE FUNCIONALIDADES DO SISTEMA
--    MÓDULO (EDITAIS, CONTRATOS…) 1:N FUNCIONALIDADE (Seleção de editais…)
--    FUNCIONALIDADE 1:N PERMISSÃO (Visualizar editais, Gerenciar status…)
-- =====================================================================
CREATE TABLE modulo (
  id      smallint    GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  codigo  varchar(40) NOT NULL,
  nome    varchar(80) NOT NULL,
  ordem   smallint    NOT NULL DEFAULT 0,
  CONSTRAINT uq_modulo_codigo UNIQUE (codigo),
  CONSTRAINT uq_modulo_nome   UNIQUE (nome),
  CONSTRAINT ck_modulo_codigo CHECK (codigo ~ '^[A-Z0-9_]+$')
);

CREATE TABLE funcionalidade (
  id         smallint    GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  modulo_id  smallint    NOT NULL,
  codigo     varchar(60) NOT NULL,
  nome       varchar(100) NOT NULL,
  ordem      smallint    NOT NULL DEFAULT 0,
  CONSTRAINT uq_funcionalidade_codigo      UNIQUE (codigo),
  CONSTRAINT uq_funcionalidade_modulo_nome UNIQUE (modulo_id, nome),
  CONSTRAINT ck_funcionalidade_codigo CHECK (codigo ~ '^[A-Z0-9_]+$'),
  CONSTRAINT fk_funcionalidade_modulo FOREIGN KEY (modulo_id)
             REFERENCES modulo (id) ON DELETE RESTRICT
);

-- "permissao_requisito_id": permissão que precisa estar habilitada antes
-- (na tela, os toggles ficam desabilitados até habilitar "Visualizar editais").
CREATE TABLE permissao (
  id                      integer      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  funcionalidade_id       smallint     NOT NULL,
  codigo                  varchar(80)  NOT NULL,          -- usado no código da aplicação
  nome                    varchar(120) NOT NULL,          -- texto exibido no toggle
  ordem                   smallint     NOT NULL DEFAULT 0,
  permissao_requisito_id  integer,
  CONSTRAINT uq_permissao_codigo              UNIQUE (codigo),
  CONSTRAINT uq_permissao_funcionalidade_nome UNIQUE (funcionalidade_id, nome),
  CONSTRAINT ck_permissao_codigo    CHECK (codigo ~ '^[A-Z0-9_]+$'),
  CONSTRAINT ck_permissao_requisito CHECK (permissao_requisito_id <> id),
  CONSTRAINT fk_permissao_funcionalidade FOREIGN KEY (funcionalidade_id)
             REFERENCES funcionalidade (id) ON DELETE RESTRICT,
  CONSTRAINT fk_permissao_requisito FOREIGN KEY (permissao_requisito_id)
             REFERENCES permissao (id) ON DELETE RESTRICT
);
CREATE INDEX ix_permissao_requisito ON permissao (permissao_requisito_id);

-- Associativa GRUPO x PERMISSÃO (N:N). Linha presente = toggle HABILITADO.
CREATE TABLE grupo_permissao (
  grupo_id          bigint      NOT NULL,
  permissao_id      integer     NOT NULL,
  concedida_em      timestamptz NOT NULL DEFAULT now(),
  concedida_por_id  bigint,
  CONSTRAINT pk_grupo_permissao PRIMARY KEY (grupo_id, permissao_id),
  CONSTRAINT fk_grupo_permissao_grupo     FOREIGN KEY (grupo_id)
             REFERENCES grupo (id)     ON DELETE CASCADE,
  CONSTRAINT fk_grupo_permissao_permissao FOREIGN KEY (permissao_id)
             REFERENCES permissao (id) ON DELETE CASCADE,
  CONSTRAINT fk_grupo_permissao_concedida_por FOREIGN KEY (concedida_por_id)
             REFERENCES usuario (id)   ON DELETE SET NULL
);
CREATE INDEX ix_grupo_permissao_permissao ON grupo_permissao (permissao_id);

-- =====================================================================
-- 6. REGISTRO DE ACESSO (auditoria das tentativas de login)
-- =====================================================================
CREATE TABLE registro_acesso (
  id               bigint       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  usuario_id       bigint,                               -- NULL se e-mail não cadastrado
  email_informado  varchar(254) NOT NULL,
  resultado        varchar(20)  NOT NULL,
  endereco_ip      inet,
  user_agent       varchar(400),
  ocorrido_em      timestamptz  NOT NULL DEFAULT now(),
  CONSTRAINT ck_registro_acesso_resultado CHECK (resultado IN
             ('SUCESSO', 'NAO_CADASTRADO', 'FORA_GRUPO_AD', 'INATIVO')),
  CONSTRAINT fk_registro_acesso_usuario FOREIGN KEY (usuario_id)
             REFERENCES usuario (id) ON DELETE SET NULL
);
CREATE INDEX ix_registro_acesso_usuario_data ON registro_acesso (usuario_id, ocorrido_em DESC);

-- =====================================================================
-- 7. REGRAS DE INTEGRIDADE QUE NÃO CABEM EM PK/FK/CHECK
--    Implementadas como CONSTRAINT TRIGGER DEFERRABLE: a verificação ocorre
--    no COMMIT, permitindo inserir o usuário e seus grupos na mesma transação.
-- =====================================================================

-- RN1: todo usuário deve pertencer a pelo menos um grupo ("Grupo *" obrigatório)
CREATE FUNCTION fn_valida_usuario_tem_grupo() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  v_usuario_id bigint;
BEGIN
  IF TG_TABLE_NAME = 'usuario' THEN
    v_usuario_id := NEW.id;
  ELSE
    v_usuario_id := OLD.usuario_id;
  END IF;

  IF EXISTS (SELECT 1 FROM usuario WHERE id = v_usuario_id)
     AND NOT EXISTS (SELECT 1 FROM usuario_grupo WHERE usuario_id = v_usuario_id) THEN
    RAISE EXCEPTION 'O usuário % deve pertencer a pelo menos um grupo', v_usuario_id
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NULL;
END $$;

CREATE CONSTRAINT TRIGGER ct_usuario_tem_grupo
  AFTER INSERT ON usuario DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION fn_valida_usuario_tem_grupo();

CREATE CONSTRAINT TRIGGER ct_usuario_grupo_remocao
  AFTER DELETE OR UPDATE ON usuario_grupo DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION fn_valida_usuario_tem_grupo();

-- RN2: uma permissão só pode estar habilitada no grupo se a sua
--      permissão-requisito também estiver habilitada no mesmo grupo.
CREATE FUNCTION fn_valida_requisito_permissao() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  v_grupo_id bigint;
  v_nome     text;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_grupo_id := OLD.grupo_id;
  ELSE
    v_grupo_id := NEW.grupo_id;
  END IF;

  SELECT p.nome INTO v_nome
    FROM grupo_permissao gp
    JOIN permissao p ON p.id = gp.permissao_id
   WHERE gp.grupo_id = v_grupo_id
     AND p.permissao_requisito_id IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM grupo_permissao r
                      WHERE r.grupo_id = v_grupo_id
                        AND r.permissao_id = p.permissao_requisito_id)
   LIMIT 1;
  IF v_nome IS NOT NULL THEN
    RAISE EXCEPTION 'A permissão "%" exige que sua permissão-requisito esteja habilitada no grupo', v_nome
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NULL;
END $$;

CREATE CONSTRAINT TRIGGER ct_grupo_permissao_requisito
  AFTER INSERT OR UPDATE OR DELETE ON grupo_permissao DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION fn_valida_requisito_permissao();

-- =====================================================================
-- 8. FUNÇÃO DE APOIO ÀS CONSULTAS: texto da coluna "ÚLTIMO ACESSO"
--    (ex.: "30 minutos", "3 horas", "1 dia", "Nunca acessou")
-- =====================================================================
CREATE FUNCTION fn_tempo_desde(p_momento timestamptz) RETURNS text
LANGUAGE sql STABLE AS $$
  SELECT CASE
    WHEN p_momento IS NULL THEN 'Nunca acessou'
    WHEN now() - p_momento < interval '1 minute' THEN 'Agora'
    WHEN now() - p_momento < interval '1 hour' THEN
         n_min || CASE WHEN n_min = 1 THEN ' minuto' ELSE ' minutos' END
    WHEN now() - p_momento < interval '1 day' THEN
         n_h   || CASE WHEN n_h = 1 THEN ' hora' ELSE ' horas' END
    ELSE n_d   || CASE WHEN n_d = 1 THEN ' dia' ELSE ' dias' END
  END
  FROM (SELECT floor(extract(epoch FROM now() - p_momento) / 60)::int    AS n_min,
               floor(extract(epoch FROM now() - p_momento) / 3600)::int  AS n_h,
               floor(extract(epoch FROM now() - p_momento) / 86400)::int AS n_d) t
$$;

-- =====================================================================
-- 9. DICIONÁRIO DE DADOS (comentários gravados no catálogo do banco)
-- =====================================================================
COMMENT ON TABLE configuracao_ad IS 'Parâmetros do Active Directory usados no login (linha única)';
COMMENT ON TABLE usuario         IS 'Usuário autorizado a acessar a plataforma (autenticado pelo AD; sem senha local)';
COMMENT ON TABLE papel           IS 'Papel/cargo que o usuário exerce (ex.: Analista de proposta); opcional';
COMMENT ON TABLE usuario_papel   IS 'Papéis atribuídos a cada usuário (N:N)';
COMMENT ON TABLE grupo           IS 'Grupo de usuários que concentra permissões de acesso';
COMMENT ON TABLE usuario_grupo   IS 'Usuários vinculados a cada grupo (N:N); todo usuário tem pelo menos 1 grupo';
COMMENT ON TABLE modulo          IS 'Módulo do sistema exibido como seção (ex.: EDITAIS, CONTRATOS)';
COMMENT ON TABLE funcionalidade  IS 'Funcionalidade de um módulo (ex.: Seleção de editais)';
COMMENT ON TABLE permissao       IS 'Ação habilitável por toggle na tela de grupo (ex.: Visualizar editais)';
COMMENT ON TABLE grupo_permissao IS 'Permissões habilitadas em cada grupo (linha presente = toggle ligado)';
COMMENT ON TABLE registro_acesso IS 'Auditoria das tentativas de login';

COMMENT ON COLUMN configuracao_ad.id                 IS 'Identificador fixo da linha única (sempre 1)';
COMMENT ON COLUMN configuracao_ad.tenant_id          IS 'ID do diretório (tenant) da empresa no Microsoft Entra ID / AD';
COMMENT ON COLUMN configuracao_ad.client_id          IS 'ID do aplicativo da plataforma registrado no AD';
COMMENT ON COLUMN configuracao_ad.grupo_ad_object_id IS 'ID do grupo do AD cujos membros podem acessar a plataforma';
COMMENT ON COLUMN configuracao_ad.grupo_ad_nome      IS 'Nome do grupo do AD (exibição)';
COMMENT ON COLUMN configuracao_ad.dominio_email      IS 'Domínio do e-mail corporativo';

COMMENT ON COLUMN usuario.email            IS 'E-mail corporativo; chave de login (único, sem diferenciar maiúsculas)';
COMMENT ON COLUMN usuario.nome             IS 'Nome vindo do AD; preenchido/atualizado pela plataforma a cada login';
COMMENT ON COLUMN usuario.ad_object_id     IS 'Identificador do usuário no AD (claim "oid" do token)';
COMMENT ON COLUMN usuario.ativo            IS 'Indica se o acesso está liberado (bloqueio sem excluir)';
COMMENT ON COLUMN usuario.ultimo_acesso_em IS 'Data/hora do último login com sucesso; NULL = nunca acessou';

COMMENT ON COLUMN papel.nome      IS 'Nome do papel exibido na coluna PAPEL';
COMMENT ON COLUMN papel.descricao IS 'Descrição do papel';
COMMENT ON COLUMN usuario_papel.papel_id IS 'Papel atribuído ao usuário';

COMMENT ON COLUMN grupo.nome      IS 'Nome do grupo ("Nome do grupo" na tela)';
COMMENT ON COLUMN grupo.descricao IS 'Descrição do grupo';
COMMENT ON COLUMN usuario_grupo.grupo_id IS 'Grupo ao qual o usuário pertence';

COMMENT ON COLUMN modulo.codigo IS 'Código estável do módulo, usado pela aplicação';
COMMENT ON COLUMN modulo.nome   IS 'Nome do módulo exibido como seção na tela de grupo';
COMMENT ON COLUMN funcionalidade.modulo_id IS 'Módulo ao qual a funcionalidade pertence';
COMMENT ON COLUMN funcionalidade.codigo    IS 'Código estável da funcionalidade, usado pela aplicação';
COMMENT ON COLUMN funcionalidade.nome      IS 'Nome exibido como título do bloco de toggles';
COMMENT ON COLUMN permissao.funcionalidade_id      IS 'Funcionalidade à qual a permissão pertence';
COMMENT ON COLUMN permissao.codigo                 IS 'Código verificado pelo back-end (ex.: EDITAL_VISUALIZAR)';
COMMENT ON COLUMN permissao.nome                   IS 'Texto exibido ao lado do toggle';
COMMENT ON COLUMN permissao.permissao_requisito_id IS 'Permissão que precisa estar habilitada antes desta';
COMMENT ON COLUMN grupo_permissao.grupo_id     IS 'Grupo que recebe a permissão';
COMMENT ON COLUMN grupo_permissao.permissao_id IS 'Permissão habilitada no grupo';

COMMENT ON COLUMN registro_acesso.usuario_id      IS 'Usuário identificado; NULL se o e-mail não estiver cadastrado';
COMMENT ON COLUMN registro_acesso.email_informado IS 'E-mail retornado pelo AD na tentativa';
COMMENT ON COLUMN registro_acesso.resultado       IS 'SUCESSO, NAO_CADASTRADO, FORA_GRUPO_AD ou INATIVO';
COMMENT ON COLUMN registro_acesso.endereco_ip     IS 'IP de origem da tentativa';
COMMENT ON COLUMN registro_acesso.user_agent      IS 'Navegador/dispositivo de origem';
COMMENT ON COLUMN registro_acesso.ocorrido_em     IS 'Data/hora da tentativa';

-- Comentários padronizados das colunas técnicas repetidas
DO $$
DECLARE c record;
BEGIN
  FOR c IN
    SELECT table_name, column_name FROM information_schema.columns
     WHERE table_schema = 'controle_acesso'
       AND column_name IN ('id','criado_em','atualizado_em','criado_por_id',
                           'atualizado_por_id','concedida_em','concedida_por_id',
                           'ordem','usuario_id')
       AND col_description(format('controle_acesso.%I', table_name)::regclass, ordinal_position) IS NULL
  LOOP
    EXECUTE format('COMMENT ON COLUMN %I.%I IS %L', c.table_name, c.column_name,
      CASE c.column_name
        WHEN 'id'                THEN 'Chave primária (identificador gerado automaticamente)'
        WHEN 'criado_em'         THEN 'Data/hora de criação do registro'
        WHEN 'atualizado_em'     THEN 'Data/hora da última alteração (mantida por trigger)'
        WHEN 'criado_por_id'     THEN 'Usuário que criou o registro'
        WHEN 'atualizado_por_id' THEN 'Usuário que fez a última alteração'
        WHEN 'concedida_em'      THEN 'Data/hora em que a permissão foi habilitada'
        WHEN 'concedida_por_id'  THEN 'Usuário que habilitou a permissão'
        WHEN 'ordem'             THEN 'Ordem de exibição na tela'
        WHEN 'usuario_id'        THEN 'Usuário do vínculo'
      END);
  END LOOP;
END $$;
