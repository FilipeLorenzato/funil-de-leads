-- =====================================================================
-- Consultas da página Empresas (Appsmith)
-- =====================================================================


-- ListarEmpresasCompleto: tabela da página, com o CNPJ já mascarado e a
-- contagem de leads e de negócios ganhos de cada empresa.
SELECT e.id, e.nome,
       regexp_replace(e.cnpj, '^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$', '\1.\2.\3/\4-\5') AS cnpj,
       e.segmento, e.cidade || ' - ' || e.uf AS cidade,
       count(l.id) AS leads,
       count(l.id) FILTER (WHERE l.etapa_id = 5) AS ganhos
FROM empresa e
LEFT JOIN lead l ON l.empresa_id = e.id
GROUP BY e.id
ORDER BY e.nome;


-- InserirEmpresa: grava a empresa consultada na Receita.
-- O CNPJ chega com a máscara (00.000.000/0000-00) e o banco guarda só os
-- dígitos. Enviar com a máscara garante que ele trafegue como texto e não
-- perca zeros à esquerda.
INSERT INTO empresa (nome, cnpj, razao_social, segmento, cidade, uf)
VALUES (
  {{ this.params.nome }}::text,
  regexp_replace({{ this.params.cnpj }}::text, '\D', '', 'g'),
  NULLIF({{ this.params.razao_social }}::text, ''),
  NULLIF({{ this.params.segmento }}::text, ''),
  NULLIF({{ this.params.cidade }}::text, ''),
  NULLIF({{ this.params.uf }}::text, '')
);


-- ConsultarCnpj (API REST, não é SQL)
-- Método: GET
-- URL:    https://brasilapi.com.br/api/cnpj/v1/{{this.params.cnpj}}
-- Campos usados da resposta: razao_social, nome_fantasia, cnae_fiscal_descricao,
-- municipio, uf, descricao_situacao_cadastral.
