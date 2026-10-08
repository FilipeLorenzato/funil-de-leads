-- =====================================================================
-- Consultas da página Leads (Appsmith, fonte de dados BancoFunil)
--
-- Os trechos {{ ... }} são preenchidos pelo Appsmith com valores da tela.
-- Eles viram parâmetros de uma consulta preparada ($1, $2...), então o
-- texto digitado pelo usuário nunca é concatenado ao SQL.
-- Os ::text, ::bigint etc. fixam o tipo de cada parâmetro.
-- =====================================================================


-- ListarLeads: lista da tela, com busca e filtros feitos no banco.
SELECT *
FROM vw_lead
WHERE ({{ FiltroEtapa.selectedOptionValue || 0 }} = 0 OR etapa_id = {{ FiltroEtapa.selectedOptionValue || 0 }})
  AND ({{ FiltroOrigem.selectedOptionValue || 0 }} = 0 OR origem_id = {{ FiltroOrigem.selectedOptionValue || 0 }})
  AND (   nome    ILIKE {{ '%' + BuscaLead.text + '%' }}
       OR empresa ILIKE {{ '%' + BuscaLead.text + '%' }}
       OR email   ILIKE {{ '%' + BuscaLead.text + '%' }})
ORDER BY criado_em DESC;


-- ListarEtapas, ListarOrigens, ListarEmpresas, ListarTipos: opções das listas.
SELECT id, nome FROM etapa_funil ORDER BY ordem;
SELECT id, nome FROM origem_lead ORDER BY id;
SELECT id, nome FROM empresa ORDER BY nome;
SELECT id, nome FROM tipo_interacao ORDER BY id;


-- InserirLead: cadastro. O score é calculado em JavaScript (RegrasLead.calcularScore).
INSERT INTO lead (nome, email, telefone, cargo, empresa_id, origem_id, valor_estimado, observacoes, score)
VALUES (
  {{ (CampoNome.text || '').trim() }}::text,
  lower({{ (CampoEmail.text || '').trim() }}::text),
  NULLIF({{ (CampoTelefone.text || '').trim() }}::text, ''),
  NULLIF({{ (CampoCargo.text || '').trim() }}::text, ''),
  {{ CampoEmpresa.selectedOptionValue }}::bigint,
  {{ CampoOrigem.selectedOptionValue }}::smallint,
  {{ Number(CampoValor.text) || 0 }}::numeric,
  NULLIF({{ (CampoObservacoes.text || '').trim() }}::text, ''),
  {{ this.params.score }}::smallint
);


-- AtualizarLead: edição.
UPDATE lead SET
  nome           = {{ (CampoNome.text || '').trim() }}::text,
  email          = lower({{ (CampoEmail.text || '').trim() }}::text),
  telefone       = NULLIF({{ (CampoTelefone.text || '').trim() }}::text, ''),
  cargo          = NULLIF({{ (CampoCargo.text || '').trim() }}::text, ''),
  empresa_id     = {{ CampoEmpresa.selectedOptionValue }}::bigint,
  origem_id      = {{ CampoOrigem.selectedOptionValue }}::smallint,
  valor_estimado = {{ Number(CampoValor.text) || 0 }}::numeric,
  observacoes    = NULLIF({{ (CampoObservacoes.text || '').trim() }}::text, ''),
  score          = {{ this.params.score }}::smallint,
  atualizado_em  = now()
WHERE id = {{ this.params.id }}::bigint;


-- BuscarLead: dados do lead aberto na janela de detalhe.
SELECT * FROM vw_lead WHERE id = {{ appsmith.store.leadAbertoId || 0 }}::bigint;


-- ListarInteracoes: histórico de contatos do lead aberto.
SELECT i.id, i.data_hora, t.nome AS tipo, i.descricao
FROM interacao i
JOIN tipo_interacao t ON t.id = i.tipo_id
WHERE i.lead_id = {{ appsmith.store.leadAbertoId || 0 }}::bigint
ORDER BY i.data_hora DESC;


-- ListarHistorico: mudanças de etapa do lead aberto (gravadas pelo gatilho).
SELECT h.alterado_em, coalesce(a.nome, '(criação)') AS de, n.nome AS para
FROM historico_etapa h
LEFT JOIN etapa_funil a ON a.id = h.etapa_anterior_id
JOIN etapa_funil n ON n.id = h.etapa_nova_id
WHERE h.lead_id = {{ appsmith.store.leadAbertoId || 0 }}::bigint
ORDER BY h.alterado_em DESC, h.id DESC;


-- InserirInteracao: registra um contato.
INSERT INTO interacao (lead_id, tipo_id, descricao)
VALUES (
  {{ appsmith.store.leadAbertoId }}::bigint,
  {{ CampoTipoInteracao.selectedOptionValue }}::smallint,
  {{ (CampoDescricaoInteracao.text || '').trim() }}::text
);


-- MoverEtapa: muda a etapa (o gatilho grava o histórico).
UPDATE lead SET
  etapa_id      = {{ this.params.etapa }}::smallint,
  motivo_perda  = NULLIF({{ this.params.motivo }}::text, ''),
  atualizado_em = now()
WHERE id = {{ this.params.id }}::bigint;


-- AtualizarScore: grava o score recalculado depois de uma interação.
UPDATE lead SET
  score         = {{ this.params.score }}::smallint,
  atualizado_em = now()
WHERE id = {{ this.params.id }}::bigint;
