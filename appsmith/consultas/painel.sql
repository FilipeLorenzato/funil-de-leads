-- =====================================================================
-- Consultas da página Painel (Appsmith)
-- =====================================================================


-- Indicadores: números do topo do painel.
-- Taxa de conversão = ganhos / leads encerrados (ganhos + perdidos).
SELECT count(*) AS total_leads,
       count(*) FILTER (WHERE NOT ef.encerrada) AS em_aberto,
       count(*) FILTER (WHERE l.etapa_id = 5) AS ganhos,
       count(*) FILTER (WHERE l.etapa_id = 6) AS perdidos,
       round(100.0 * count(*) FILTER (WHERE l.etapa_id = 5) / nullif(count(*) FILTER (WHERE ef.encerrada), 0), 1) AS taxa_conversao,
       coalesce(sum(l.valor_estimado) FILTER (WHERE NOT ef.encerrada), 0) AS valor_em_aberto,
       coalesce(sum(l.valor_estimado) FILTER (WHERE l.etapa_id = 5), 0) AS valor_ganho
FROM lead l
JOIN etapa_funil ef ON ef.id = l.etapa_id;


-- FunilConversao: quantos leads chegaram a cada etapa em algum momento.
-- Usa o histórico (preenchido pelo gatilho), não a etapa atual, por isso os
-- números só diminuem de uma etapa para a outra. "Perdido" fica de fora.
SELECT ef.nome AS etapa, count(DISTINCT h.lead_id) AS leads
FROM etapa_funil ef
LEFT JOIN historico_etapa h ON h.etapa_nova_id = ef.id
WHERE NOT (ef.encerrada AND ef.id <> 5)
GROUP BY ef.id, ef.nome, ef.ordem
ORDER BY ef.ordem;


-- ConversaoPorOrigem: de onde vêm os leads e quais origens convertem melhor.
SELECT o.nome AS origem,
       count(l.id) AS leads,
       count(l.id) FILTER (WHERE l.etapa_id = 5) AS ganhos,
       coalesce(round(100.0 * count(l.id) FILTER (WHERE l.etapa_id = 5)
             / nullif(count(l.id) FILTER (WHERE l.etapa_id IN (5, 6)), 0), 1), 0) AS taxa_conversao
FROM origem_lead o
LEFT JOIN lead l ON l.origem_id = o.id
GROUP BY o.id, o.nome
ORDER BY leads DESC, o.nome;


-- LeadsParados: leads em aberto sem contato há mais de 7 dias.
SELECT nome, empresa, etapa, score,
       (current_date - coalesce(ultima_interacao, criado_em)::date) AS dias_sem_contato
FROM vw_lead
WHERE NOT encerrada
  AND coalesce(ultima_interacao, criado_em) < now() - interval '7 days'
ORDER BY dias_sem_contato DESC, score DESC;
