-- =====================================================================
-- Funil de Leads · estrutura do banco (PostgreSQL)
-- Autor: Filipe Lorenzato
--
-- Como usar: cole este arquivo inteiro no SQL Editor e clique em Run.
-- Pode rodar de novo quando quiser: ele apaga e recria tudo do zero.
-- =====================================================================

DROP VIEW  IF EXISTS vw_lead;
DROP TABLE IF EXISTS historico_etapa, interacao, lead, empresa,
                     tipo_interacao, origem_lead, etapa_funil CASCADE;
DROP FUNCTION IF EXISTS registrar_mudanca_de_etapa();


-- ---------------------------------------------------------------------
-- 1. LISTAS FIXAS
-- São tabelas (e não texto solto no lead) porque as regras do sistema
-- dependem delas e porque assim o banco impede valores inventados.
-- ---------------------------------------------------------------------

CREATE TABLE etapa_funil (
    id         smallint    PRIMARY KEY,
    nome       varchar(30) NOT NULL UNIQUE,
    ordem      smallint    NOT NULL UNIQUE,          -- posição no funil
    encerrada  boolean     NOT NULL DEFAULT false    -- Ganho e Perdido fecham o lead
);

INSERT INTO etapa_funil (id, nome, ordem, encerrada) VALUES
    (1, 'Novo',        1, false),
    (2, 'Qualificado', 2, false),
    (3, 'Proposta',    3, false),
    (4, 'Negociação',  4, false),
    (5, 'Ganho',       5, true),
    (6, 'Perdido',     6, true);

CREATE TABLE origem_lead (
    id    smallint    PRIMARY KEY,
    nome  varchar(30) NOT NULL UNIQUE
);

INSERT INTO origem_lead (id, nome) VALUES
    (1, 'Site'), (2, 'Indicação'), (3, 'Evento'), (4, 'LinkedIn'), (5, 'Outro');

CREATE TABLE tipo_interacao (
    id    smallint    PRIMARY KEY,
    nome  varchar(30) NOT NULL UNIQUE
);

INSERT INTO tipo_interacao (id, nome) VALUES
    (1, 'Ligação'), (2, 'E-mail'), (3, 'Reunião'), (4, 'Mensagem');


-- ---------------------------------------------------------------------
-- 2. EMPRESA
-- O CNPJ é guardado só com os 14 dígitos. A máscara (pontos e barra)
-- é responsabilidade da tela, não do banco.
-- ---------------------------------------------------------------------

CREATE TABLE empresa (
    id            bigint       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome          varchar(100) NOT NULL,
    cnpj          varchar(14)  NOT NULL,
    razao_social  varchar(150),
    segmento      varchar(150),
    cidade        varchar(60),
    uf            char(2),
    criado_em     timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT empresa_cnpj_unico   UNIQUE (cnpj),
    CONSTRAINT empresa_cnpj_formato CHECK (cnpj ~ '^[0-9]{14}$'),
    CONSTRAINT empresa_uf_formato   CHECK (uf ~ '^[A-Z]{2}$')
);


-- ---------------------------------------------------------------------
-- 3. LEAD
-- Entidade central. Todo lead pertence a uma empresa, está em uma etapa
-- do funil e veio de uma origem.
-- ---------------------------------------------------------------------

CREATE TABLE lead (
    id              bigint        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome            varchar(100)  NOT NULL,
    email           varchar(150)  NOT NULL,
    telefone        varchar(20),
    cargo           varchar(60),
    empresa_id      bigint        NOT NULL REFERENCES empresa (id) ON DELETE RESTRICT,
    etapa_id        smallint      NOT NULL DEFAULT 1 REFERENCES etapa_funil (id),
    origem_id       smallint      NOT NULL REFERENCES origem_lead (id),
    valor_estimado  numeric(12,2) NOT NULL DEFAULT 0,
    score           smallint      NOT NULL DEFAULT 0,
    observacoes     varchar(500),
    motivo_perda    varchar(200),
    criado_em       timestamptz   NOT NULL DEFAULT now(),
    atualizado_em   timestamptz   NOT NULL DEFAULT now(),

    CONSTRAINT lead_email_formato   CHECK (email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
    CONSTRAINT lead_valor_positivo  CHECK (valor_estimado >= 0),
    CONSTRAINT lead_score_faixa     CHECK (score BETWEEN 0 AND 100),

    -- Regras de negócio garantidas pelo banco (5 = Ganho, 6 = Perdido):
    CONSTRAINT lead_ganho_tem_valor    CHECK (etapa_id <> 5 OR valor_estimado > 0),
    -- (o coalesce é necessário porque um CHECK com resultado nulo é aceito)
    CONSTRAINT lead_perdido_tem_motivo CHECK (etapa_id <> 6 OR coalesce(length(trim(motivo_perda)), 0) > 0)
);

-- Bloqueio de lead duplicado: mesmo e-mail, ignorando maiúsculas.
CREATE UNIQUE INDEX lead_email_unico ON lead (lower(email));

-- Índices das colunas usadas em filtros e junções.
CREATE INDEX lead_etapa_idx   ON lead (etapa_id);
CREATE INDEX lead_empresa_idx ON lead (empresa_id);


-- ---------------------------------------------------------------------
-- 4. INTERAÇÃO
-- Histórico de contatos. Não existe sem o lead, por isso ON DELETE CASCADE.
-- ---------------------------------------------------------------------

CREATE TABLE interacao (
    id         bigint       GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lead_id    bigint       NOT NULL REFERENCES lead (id) ON DELETE CASCADE,
    tipo_id    smallint     NOT NULL REFERENCES tipo_interacao (id),
    data_hora  timestamptz  NOT NULL DEFAULT now(),
    descricao  varchar(500) NOT NULL,
    criado_em  timestamptz  NOT NULL DEFAULT now(),

    CONSTRAINT interacao_descricao_preenchida CHECK (length(trim(descricao)) > 0)
);

CREATE INDEX interacao_lead_idx ON interacao (lead_id, data_hora DESC);


-- ---------------------------------------------------------------------
-- 5. HISTÓRICO DE ETAPAS (auditoria)
-- Guarda cada mudança de etapa. É preenchido por um gatilho, então o
-- registro acontece mesmo que a alteração venha de fora do aplicativo.
-- ---------------------------------------------------------------------

CREATE TABLE historico_etapa (
    id                 bigint      GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    lead_id            bigint      NOT NULL REFERENCES lead (id) ON DELETE CASCADE,
    etapa_anterior_id  smallint    REFERENCES etapa_funil (id),   -- nulo quando o lead é criado
    etapa_nova_id      smallint    NOT NULL REFERENCES etapa_funil (id),
    alterado_em        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX historico_lead_idx ON historico_etapa (lead_id, alterado_em);

CREATE FUNCTION registrar_mudanca_de_etapa() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO historico_etapa (lead_id, etapa_anterior_id, etapa_nova_id)
        VALUES (NEW.id, NULL, NEW.etapa_id);
    ELSIF NEW.etapa_id <> OLD.etapa_id THEN
        INSERT INTO historico_etapa (lead_id, etapa_anterior_id, etapa_nova_id)
        VALUES (NEW.id, OLD.etapa_id, NEW.etapa_id);
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER lead_historico_etapa
AFTER INSERT OR UPDATE OF etapa_id ON lead
FOR EACH ROW EXECUTE FUNCTION registrar_mudanca_de_etapa();


-- ---------------------------------------------------------------------
-- 6. VISÃO PARA AS TELAS
-- Junta o lead com os nomes de empresa, etapa e origem e com o resumo
-- das interações. As telas consultam esta visão em vez de repetir os JOINs.
-- ---------------------------------------------------------------------

CREATE VIEW vw_lead AS
SELECT
    l.id,
    l.nome,
    l.email,
    l.telefone,
    l.cargo,
    l.empresa_id,
    e.nome            AS empresa,
    l.etapa_id,
    ef.nome           AS etapa,
    ef.ordem          AS etapa_ordem,
    ef.encerrada,
    l.origem_id,
    o.nome            AS origem,
    l.valor_estimado,
    l.score,
    l.observacoes,
    l.motivo_perda,
    l.criado_em,
    l.atualizado_em,
    count(i.id)       AS total_interacoes,
    max(i.data_hora)  AS ultima_interacao
FROM lead l
JOIN empresa     e  ON e.id  = l.empresa_id
JOIN etapa_funil ef ON ef.id = l.etapa_id
JOIN origem_lead o  ON o.id  = l.origem_id
LEFT JOIN interacao i ON i.lead_id = l.id
GROUP BY l.id, e.nome, ef.nome, ef.ordem, ef.encerrada, o.nome;
