-- Módulo de Controle de Acessos - Modelo físico (PostgreSQL)
-- Sem senha: o login é feito pelo Active Directory.

CREATE TABLE usuario (
  id             bigint       GENERATED ALWAYS AS IDENTITY,
  email          varchar(254) NOT NULL,
  nome           varchar(150),   -- vem do AD
  ultimo_acesso  timestamp,      -- NULL = nunca acessou
  criado_em      timestamp    NOT NULL DEFAULT now(),
  atualizado_em  timestamp    NOT NULL DEFAULT now(),
  CONSTRAINT pk_usuario PRIMARY KEY (id),
  CONSTRAINT uq_usuario_email UNIQUE (email),
  CONSTRAINT ck_usuario_email
    CHECK (email = lower(email) AND email LIKE '%_@_%._%')
);

CREATE TABLE papel (
  id         smallint     GENERATED ALWAYS AS IDENTITY,
  nome       varchar(80)  NOT NULL,
  criado_em  timestamp    NOT NULL DEFAULT now(),
  CONSTRAINT pk_papel PRIMARY KEY (id),
  CONSTRAINT uq_papel_nome UNIQUE (nome)
);

CREATE TABLE grupo (
  id             bigint       GENERATED ALWAYS AS IDENTITY,
  nome           varchar(100) NOT NULL,
  criado_em      timestamp    NOT NULL DEFAULT now(),
  atualizado_em  timestamp    NOT NULL DEFAULT now(),
  CONSTRAINT pk_grupo PRIMARY KEY (id),
  CONSTRAINT uq_grupo_nome UNIQUE (nome)
);

CREATE TABLE modulo (
  id    smallint    GENERATED ALWAYS AS IDENTITY,
  nome  varchar(80) NOT NULL,
  CONSTRAINT pk_modulo PRIMARY KEY (id),
  CONSTRAINT uq_modulo_nome UNIQUE (nome)
);

CREATE TABLE funcionalidade (
  id         smallint     GENERATED ALWAYS AS IDENTITY,
  modulo_id  smallint     NOT NULL,
  nome       varchar(100) NOT NULL,
  CONSTRAINT pk_funcionalidade PRIMARY KEY (id),
  CONSTRAINT uq_funcionalidade_nome UNIQUE (modulo_id, nome),
  CONSTRAINT fk_funcionalidade_modulo FOREIGN KEY (modulo_id)
    REFERENCES modulo (id) ON DELETE RESTRICT
);

CREATE TABLE permissao (
  id                 integer      GENERATED ALWAYS AS IDENTITY,
  funcionalidade_id  smallint     NOT NULL,
  codigo             varchar(80)  NOT NULL,  -- usado no código
  nome               varchar(120) NOT NULL,  -- texto do toggle
  CONSTRAINT pk_permissao PRIMARY KEY (id),
  CONSTRAINT uq_permissao_codigo UNIQUE (codigo),
  CONSTRAINT uq_permissao_nome
    UNIQUE (funcionalidade_id, nome),
  CONSTRAINT fk_permissao_funcionalidade
    FOREIGN KEY (funcionalidade_id)
    REFERENCES funcionalidade (id) ON DELETE RESTRICT
);

-- usuario N:N grupo
CREATE TABLE usuario_grupo (
  usuario_id  bigint    NOT NULL,
  grupo_id    bigint    NOT NULL,
  criado_em   timestamp NOT NULL DEFAULT now(),
  CONSTRAINT pk_usuario_grupo
    PRIMARY KEY (usuario_id, grupo_id),
  CONSTRAINT fk_usuario_grupo_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT fk_usuario_grupo_grupo FOREIGN KEY (grupo_id)
    REFERENCES grupo (id) ON DELETE CASCADE
);

-- usuario N:N papel
CREATE TABLE usuario_papel (
  usuario_id  bigint    NOT NULL,
  papel_id    smallint  NOT NULL,
  criado_em   timestamp NOT NULL DEFAULT now(),
  CONSTRAINT pk_usuario_papel
    PRIMARY KEY (usuario_id, papel_id),
  CONSTRAINT fk_usuario_papel_usuario FOREIGN KEY (usuario_id)
    REFERENCES usuario (id) ON DELETE CASCADE,
  CONSTRAINT fk_usuario_papel_papel FOREIGN KEY (papel_id)
    REFERENCES papel (id) ON DELETE RESTRICT
);

-- grupo N:N permissao (linha = toggle habilitado)
CREATE TABLE grupo_permissao (
  grupo_id      bigint    NOT NULL,
  permissao_id  integer   NOT NULL,
  criado_em     timestamp NOT NULL DEFAULT now(),
  CONSTRAINT pk_grupo_permissao
    PRIMARY KEY (grupo_id, permissao_id),
  CONSTRAINT fk_grupo_permissao_grupo FOREIGN KEY (grupo_id)
    REFERENCES grupo (id) ON DELETE CASCADE,
  CONSTRAINT fk_grupo_permissao_permissao
    FOREIGN KEY (permissao_id)
    REFERENCES permissao (id) ON DELETE CASCADE
);
