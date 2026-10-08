-- =====================================================================
-- Funil de Leads · dados de exemplo
--
-- Rode DEPOIS do 01_estrutura.sql. Todas as pessoas, empresas, e-mails
-- e telefones aqui são fictícios, criados só para demonstração.
-- Pode rodar de novo: ele limpa as tabelas antes de inserir.
-- As datas são calculadas a partir de hoje, então o painel sempre
-- parece recente.
-- =====================================================================

TRUNCATE historico_etapa, interacao, lead, empresa RESTART IDENTITY CASCADE;
DROP TABLE IF EXISTS carga_lead, carga_interacao;


-- ---------------------------------------------------------------------
-- 1. Empresas
-- ---------------------------------------------------------------------

INSERT INTO empresa (nome, cnpj, razao_social, segmento, cidade, uf, criado_em) VALUES
    ('Aurora Engenharia',     '11222333000181', 'Aurora Engenharia e Construções Ltda',  'Construção civil',        'Belo Horizonte',  'MG', now() - interval '75 days'),
    ('Vértice Logística',     '20405060000100', 'Vértice Transportes e Logística S.A.',  'Transporte e logística',  'Contagem',        'MG', now() - interval '72 days'),
    ('Clínica Bem Viver',     '31827165000165', 'Bem Viver Serviços Médicos Ltda',       'Saúde',                   'Belo Horizonte',  'MG', now() - interval '70 days'),
    ('Rede Sabor Mineiro',    '42736451000131', 'Sabor Mineiro Alimentação Ltda',        'Alimentação',             'Uberlândia',      'MG', now() - interval '68 days'),
    ('Colégio Horizonte',     '53645562000159', 'Instituto Educacional Horizonte Ltda',  'Educação',                'Juiz de Fora',    'MG', now() - interval '74 days'),
    ('Tecelagem Serra Azul',  '64554673000176', 'Serra Azul Indústria Têxtil Ltda',      'Indústria têxtil',        'Divinópolis',     'MG', now() - interval '60 days'),
    ('Mercado Bom Preço',     '75463784000193', 'Bom Preço Comércio de Alimentos Ltda',  'Varejo',                  'São Paulo',       'SP', now() - interval '69 days'),
    ('Solar Minas Energia',   '86372895000100', 'Solar Minas Energia Renovável Ltda',    'Energia',                 'Montes Claros',   'MG', now() - interval '58 days'),
    ('Atlas Contabilidade',   '97281906000163', 'Atlas Serviços Contábeis Ltda',         'Serviços contábeis',      'Rio de Janeiro',  'RJ', now() - interval '62 days'),
    ('AgroVale Insumos',      '18191017000139', 'AgroVale Insumos Agrícolas Ltda',       'Agronegócio',             'Patos de Minas',  'MG', now() - interval '56 days');


-- ---------------------------------------------------------------------
-- 2. Leads
-- "caminho" são as etapas por onde o lead já passou depois de Novo.
-- Ex.: {2,3} = foi qualificado e depois recebeu proposta.
-- ---------------------------------------------------------------------

CREATE TABLE carga_lead (
    nome text, email text, telefone text, cargo text, cnpj text,
    origem_id smallint, valor numeric, dias_criado int,
    caminho smallint[], motivo_perda text
);

INSERT INTO carga_lead VALUES
    -- Novo
    ('Ana Ribeiro',        'ana.ribeiro@aurora.example.com',        '(31) 90000-0101', 'Gerente de Compras',            '11222333000181', 1,  12000,  2, '{}',        NULL),
    ('Bruno Tavares',      'bruno.tavares@vertice.example.com',     '(31) 90000-0102', 'Analista de Operações',         '20405060000100', 4,      0,  1, '{}',        NULL),
    ('Carla Mendes',       'carla.mendes@bemviver.example.com',     '(31) 90000-0103', 'Diretora Administrativa',       '31827165000165', 2,  35000,  3, '{}',        NULL),
    ('Diego Fonseca',      'diego.fonseca@sabormineiro.example.com','(34) 90000-0104', 'Coordenador de TI',             '42736451000131', 3,   8000,  5, '{}',        NULL),
    ('Elaine Castro',      'elaine.castro@horizonte.example.com',   NULL,              'Secretária Acadêmica',          '53645562000159', 1,      0, 12, '{}',        NULL),
    ('Fábio Nogueira',     'fabio.nogueira@serraazul.example.com',  '(37) 90000-0106', 'Sócio',                         '64554673000176', 5,  20000, 15, '{}',        NULL),
    ('Gabriela Pires',     'gabriela.pires@bompreco.example.com',   NULL,              'Analista de Marketing',         '75463784000193', 4,   4000,  0, '{}',        NULL),
    -- Qualificado
    ('Henrique Lopes',     'henrique.lopes@solarminas.example.com', '(38) 90000-0108', 'Diretor Comercial',             '86372895000100', 2,  60000, 10, '{2}',       NULL),
    ('Isabela Rocha',      'isabela.rocha@atlas.example.com',       '(21) 90000-0109', 'Gerente Financeira',            '97281906000163', 1,  15000, 14, '{2}',       NULL),
    ('João Batista',       'joao.batista@agrovale.example.com',     '(34) 90000-0110', 'Coordenador de Compras',        '18191017000139', 3,  22000,  9, '{2}',       NULL),
    ('Karina Duarte',      'karina.duarte@aurora.example.com',      '(31) 90000-0111', 'Analista de Projetos',          '11222333000181', 4,   6000, 20, '{2}',       NULL),
    ('Leonardo Reis',      'leonardo.reis@vertice.example.com',     '(31) 90000-0112', 'Gerente de Frota',              '20405060000100', 2,  28000, 25, '{2}',       NULL),
    ('Mariana Teles',      'mariana.teles@bemviver.example.com',    '(31) 90000-0113', 'Coordenadora de Atendimento',   '31827165000165', 1,   9000,  7, '{2}',       NULL),
    -- Proposta
    ('Nelson Araújo',      'nelson.araujo@sabormineiro.example.com','(34) 90000-0114', 'Diretor de Expansão',           '42736451000131', 3,  75000, 30, '{2,3}',     NULL),
    ('Olívia Sampaio',     'olivia.sampaio@horizonte.example.com',  '(32) 90000-0115', 'Diretora Pedagógica',           '53645562000159', 2,  40000, 28, '{2,3}',     NULL),
    ('Paulo Vieira',       'paulo.vieira@serraazul.example.com',    '(37) 90000-0116', 'Gerente Industrial',            '64554673000176', 4,  32000, 22, '{2,3}',     NULL),
    ('Queila Barros',      'queila.barros@bompreco.example.com',    '(11) 90000-0117', 'Gerente de Loja',               '75463784000193', 1,  11000, 18, '{2,3}',     NULL),
    ('Rafael Cunha',       'rafael.cunha@solarminas.example.com',   '(38) 90000-0118', 'Coordenador de Projetos',       '86372895000100', 3,  18000, 35, '{2,3}',     NULL),
    -- Negociação
    ('Sabrina Moura',      'sabrina.moura@atlas.example.com',       '(21) 90000-0119', 'Sócia',                         '97281906000163', 2,  55000, 40, '{2,3,4}',   NULL),
    ('Tiago Almeida',      'tiago.almeida@agrovale.example.com',    '(34) 90000-0120', 'Diretor de Operações',          '18191017000139', 3,  90000, 45, '{2,3,4}',   NULL),
    ('Úrsula Farias',      'ursula.farias@aurora.example.com',      '(31) 90000-0121', 'Gerente de Suprimentos',        '11222333000181', 4,  26000, 38, '{2,3,4}',   NULL),
    ('Vinícius Prado',     'vinicius.prado@vertice.example.com',    '(31) 90000-0122', 'CEO',                           '20405060000100', 2, 120000, 50, '{2,3,4}',   NULL),
    -- Ganho
    ('Wagner Leal',        'wagner.leal@bemviver.example.com',      '(31) 90000-0123', 'Diretor Clínico',               '31827165000165', 2,  48000, 60, '{2,3,4,5}', NULL),
    ('Yasmin Corrêa',      'yasmin.correa@sabormineiro.example.com','(34) 90000-0124', 'Gerente de Operações',          '42736451000131', 3,  30000, 55, '{2,3,4,5}', NULL),
    ('José Monteiro',      'jose.monteiro@horizonte.example.com',   '(32) 90000-0125', 'Diretor Financeiro',            '53645562000159', 1,  22000, 70, '{2,3,4,5}', NULL),
    ('Alice Guimarães',    'alice.guimaraes@bompreco.example.com',  '(11) 90000-0126', 'Diretora de Compras',           '75463784000193', 4,  65000, 65, '{2,3,4,5}', NULL),
    -- Perdido
    ('Bernardo Silveira',  'bernardo.silveira@serraazul.example.com','(37) 90000-0127','Gerente de TI',                 '64554673000176', 1,  14000, 48, '{2,6}',     'Sem orçamento para este ano'),
    ('Camila Antunes',     'camila.antunes@solarminas.example.com', NULL,              'Analista Financeira',           '86372895000100', 4,   5000, 42, '{6}',       'Não respondeu aos contatos'),
    ('Daniel Peixoto',     'daniel.peixoto@atlas.example.com',      '(21) 90000-0129', 'Coordenador de TI',             '97281906000163', 3,  19000, 58, '{2,3,6}',   'Fechou com um concorrente'),
    ('Estela Navarro',     'estela.navarro@agrovale.example.com',   '(34) 90000-0130', 'Gerente Administrativa',        '18191017000139', 5,  25000, 52, '{2,3,4,6}', 'Projeto adiado pela diretoria');

-- Todo lead nasce na etapa Novo (o gatilho registra a criação no histórico).
INSERT INTO lead (nome, email, telefone, cargo, empresa_id, origem_id, valor_estimado, criado_em, atualizado_em)
SELECT c.nome, c.email, c.telefone, c.cargo, e.id, c.origem_id, c.valor,
       now() - make_interval(days => c.dias_criado, hours => 3),
       now() - make_interval(days => c.dias_criado, hours => 3)
FROM carga_lead c
JOIN empresa e ON e.cnpj = c.cnpj
ORDER BY c.dias_criado DESC;

-- Avança cada lead pelo caminho, uma etapa por vez, como o aplicativo faria.
-- Cada UPDATE dispara o gatilho e gera uma linha no histórico.
DO $$
DECLARE
    r record;
    etapa smallint;
BEGIN
    FOR r IN
        SELECT l.id, c.caminho, c.motivo_perda
        FROM carga_lead c JOIN lead l ON l.email = c.email
        ORDER BY l.id
    LOOP
        FOREACH etapa IN ARRAY r.caminho LOOP
            UPDATE lead
               SET etapa_id     = etapa,
                   motivo_perda = CASE WHEN etapa = 6 THEN r.motivo_perda ELSE motivo_perda END
             WHERE id = r.id;
        END LOOP;
    END LOOP;
END;
$$;


-- ---------------------------------------------------------------------
-- 3. Interações (tipos: 1 Ligação, 2 E-mail, 3 Reunião, 4 Mensagem)
-- ---------------------------------------------------------------------

CREATE TABLE carga_interacao (email text, tipo_id smallint, dias_atras int, descricao text);

INSERT INTO carga_interacao VALUES
    ('ana.ribeiro@aurora.example.com',          2,  1, 'Enviado e-mail de apresentação com o portfólio de soluções.'),
    ('carla.mendes@bemviver.example.com',       1,  2, 'Primeiro contato por telefone. Pediu material por e-mail.'),
    ('diego.fonseca@sabormineiro.example.com',  4,  4, 'Conversa rápida após o evento. Interesse em automatizar pedidos.'),
    ('fabio.nogueira@serraazul.example.com',    1, 14, 'Ligação sem sucesso. Recado deixado com a recepção.'),

    ('henrique.lopes@solarminas.example.com',   1,  9, 'Ligação de qualificação. Confirmou orçamento e prazo.'),
    ('henrique.lopes@solarminas.example.com',   3,  4, 'Reunião de diagnóstico com a equipe comercial.'),
    ('henrique.lopes@solarminas.example.com',   2,  1, 'Enviado resumo da reunião e próximos passos.'),
    ('isabela.rocha@atlas.example.com',         2, 13, 'Resposta ao formulário do site com perguntas iniciais.'),
    ('isabela.rocha@atlas.example.com',         1,  6, 'Ligação para entender o processo financeiro atual.'),
    ('joao.batista@agrovale.example.com',       4,  8, 'Troca de mensagens para agendar uma demonstração.'),
    ('joao.batista@agrovale.example.com',       3,  3, 'Reunião online com demonstração do fluxo de compras.'),
    ('karina.duarte@aurora.example.com',        2, 19, 'E-mail de apresentação respondido com interesse.'),
    ('karina.duarte@aurora.example.com',        1,  5, 'Ligação para levantar o volume mensal de projetos.'),
    ('leonardo.reis@vertice.example.com',       1, 24, 'Primeira ligação. Indicado por cliente atual.'),
    ('leonardo.reis@vertice.example.com',       2, 16, 'Enviado questionário de levantamento. Sem retorno ainda.'),
    ('mariana.teles@bemviver.example.com',      1,  6, 'Ligação de qualificação. Dor principal: fila de atendimento.'),
    ('mariana.teles@bemviver.example.com',      4,  2, 'Confirmou participação na reunião da próxima semana.'),

    ('nelson.araujo@sabormineiro.example.com',  1, 29, 'Contato inicial após palestra no evento.'),
    ('nelson.araujo@sabormineiro.example.com',  3, 20, 'Reunião de diagnóstico com a diretoria de expansão.'),
    ('nelson.araujo@sabormineiro.example.com',  2,  8, 'Proposta comercial enviada.'),
    ('nelson.araujo@sabormineiro.example.com',  1,  2, 'Ligação para tirar dúvidas sobre a proposta.'),
    ('olivia.sampaio@horizonte.example.com',    3, 26, 'Reunião presencial na escola para entender a operação.'),
    ('olivia.sampaio@horizonte.example.com',    2, 12, 'Proposta enviada com dois cenários de escopo.'),
    ('olivia.sampaio@horizonte.example.com',    4,  3, 'Avisou que a proposta está em análise pelo conselho.'),
    ('paulo.vieira@serraazul.example.com',      1, 21, 'Ligação de qualificação. Decisão compartilhada com o sócio.'),
    ('paulo.vieira@serraazul.example.com',      3, 14, 'Visita à fábrica e levantamento dos processos.'),
    ('paulo.vieira@serraazul.example.com',      2,  6, 'Proposta enviada.'),
    ('queila.barros@bompreco.example.com',      2, 17, 'Pedido de orçamento recebido pelo site.'),
    ('queila.barros@bompreco.example.com',      3, 10, 'Reunião online para detalhar o escopo.'),
    ('queila.barros@bompreco.example.com',      2,  5, 'Proposta enviada com condições para três lojas.'),
    ('rafael.cunha@solarminas.example.com',     1, 34, 'Contato feito durante a feira do setor.'),
    ('rafael.cunha@solarminas.example.com',     3, 27, 'Reunião técnica com a equipe de projetos.'),
    ('rafael.cunha@solarminas.example.com',     2, 19, 'Proposta enviada. Aguardando retorno.'),

    ('sabrina.moura@atlas.example.com',         1, 39, 'Ligação inicial por indicação de parceiro.'),
    ('sabrina.moura@atlas.example.com',         3, 30, 'Reunião de diagnóstico com os sócios.'),
    ('sabrina.moura@atlas.example.com',         2, 21, 'Proposta enviada.'),
    ('sabrina.moura@atlas.example.com',         3,  6, 'Reunião de negociação. Pediu ajuste no prazo de pagamento.'),
    ('sabrina.moura@atlas.example.com',         4,  1, 'Confirmou que responde até sexta-feira.'),
    ('tiago.almeida@agrovale.example.com',      3, 44, 'Primeira reunião, marcada durante o evento.'),
    ('tiago.almeida@agrovale.example.com',      2, 33, 'Proposta enviada com cronograma de implantação.'),
    ('tiago.almeida@agrovale.example.com',      3, 18, 'Reunião com o financeiro para discutir valores.'),
    ('tiago.almeida@agrovale.example.com',      1,  3, 'Ligação: pediu revisão de uma cláusula do contrato.'),
    ('ursula.farias@aurora.example.com',        1, 37, 'Ligação de qualificação.'),
    ('ursula.farias@aurora.example.com',        3, 25, 'Reunião para apresentar a solução ao time de suprimentos.'),
    ('ursula.farias@aurora.example.com',        2, 15, 'Proposta enviada.'),
    ('ursula.farias@aurora.example.com',        1,  4, 'Negociação de desconto por volume.'),
    ('vinicius.prado@vertice.example.com',      3, 49, 'Reunião inicial com o CEO.'),
    ('vinicius.prado@vertice.example.com',      3, 35, 'Workshop de levantamento com as áreas.'),
    ('vinicius.prado@vertice.example.com',      2, 22, 'Proposta enviada.'),
    ('vinicius.prado@vertice.example.com',      1,  9, 'Ligação para alinhar o escopo final.'),
    ('vinicius.prado@vertice.example.com',      3,  2, 'Reunião de negociação com o jurídico.'),

    ('wagner.leal@bemviver.example.com',        1, 59, 'Primeiro contato por indicação.'),
    ('wagner.leal@bemviver.example.com',        3, 50, 'Reunião de diagnóstico na clínica.'),
    ('wagner.leal@bemviver.example.com',        2, 41, 'Proposta enviada.'),
    ('wagner.leal@bemviver.example.com',        3, 33, 'Contrato assinado.'),
    ('yasmin.correa@sabormineiro.example.com',  3, 54, 'Reunião após contato no evento.'),
    ('yasmin.correa@sabormineiro.example.com',  2, 44, 'Proposta enviada.'),
    ('yasmin.correa@sabormineiro.example.com',  1, 36, 'Aceite da proposta por telefone.'),
    ('jose.monteiro@horizonte.example.com',     2, 69, 'Pedido de contato recebido pelo site.'),
    ('jose.monteiro@horizonte.example.com',     3, 60, 'Reunião de apresentação.'),
    ('jose.monteiro@horizonte.example.com',     2, 49, 'Proposta enviada.'),
    ('jose.monteiro@horizonte.example.com',     1, 45, 'Fechamento confirmado por telefone.'),
    ('alice.guimaraes@bompreco.example.com',    1, 64, 'Ligação inicial.'),
    ('alice.guimaraes@bompreco.example.com',    3, 55, 'Reunião de diagnóstico com a área de compras.'),
    ('alice.guimaraes@bompreco.example.com',    2, 46, 'Proposta enviada.'),
    ('alice.guimaraes@bompreco.example.com',    3, 40, 'Reunião de fechamento. Contrato assinado.'),

    ('bernardo.silveira@serraazul.example.com', 1, 47, 'Ligação de qualificação.'),
    ('bernardo.silveira@serraazul.example.com', 2, 40, 'Informou que o orçamento do ano já está comprometido.'),
    ('camila.antunes@solarminas.example.com',   2, 41, 'E-mail de apresentação enviado.'),
    ('camila.antunes@solarminas.example.com',   1, 36, 'Ligação sem resposta.'),
    ('camila.antunes@solarminas.example.com',   4, 30, 'Última tentativa de contato por mensagem.'),
    ('daniel.peixoto@atlas.example.com',        1, 57, 'Contato feito após o evento.'),
    ('daniel.peixoto@atlas.example.com',        3, 48, 'Reunião técnica.'),
    ('daniel.peixoto@atlas.example.com',        2, 39, 'Avisou que escolheu outro fornecedor.'),
    ('estela.navarro@agrovale.example.com',     1, 51, 'Ligação inicial.'),
    ('estela.navarro@agrovale.example.com',     3, 42, 'Reunião de diagnóstico.'),
    ('estela.navarro@agrovale.example.com',     2, 33, 'Proposta enviada.'),
    ('estela.navarro@agrovale.example.com',     1, 26, 'Diretoria decidiu adiar o projeto para o próximo ano.');

INSERT INTO interacao (lead_id, tipo_id, data_hora, descricao, criado_em)
SELECT l.id, c.tipo_id,
       now() - make_interval(days => c.dias_atras, hours => 1),
       c.descricao,
       now() - make_interval(days => c.dias_atras, hours => 1)
FROM carga_interacao c
JOIN lead l ON l.email = c.email
ORDER BY c.dias_atras DESC;


-- ---------------------------------------------------------------------
-- 4. Ajustes para os dados parecerem reais
-- ---------------------------------------------------------------------

-- 4.1 Datas do histórico: espalha as mudanças de etapa entre a criação do
--     lead e o fechamento (ou, para leads abertos, até 3/4 do tempo de vida).
WITH resumo AS (
    SELECT l.id AS lead_id, l.criado_em,
           CASE WHEN ef.encerrada
                THEN coalesce((SELECT max(i.data_hora) FROM interacao i WHERE i.lead_id = l.id), now()) + interval '1 hour'
                ELSE l.criado_em + (now() - l.criado_em) * 0.75
           END AS fim
    FROM lead l
    JOIN etapa_funil ef ON ef.id = l.etapa_id
),
numerado AS (
    SELECT h.id, r.criado_em, r.fim,
           row_number() OVER (PARTITION BY h.lead_id ORDER BY h.id) AS posicao,
           count(*)     OVER (PARTITION BY h.lead_id)               AS total
    FROM historico_etapa h
    JOIN resumo r ON r.lead_id = h.lead_id
)
UPDATE historico_etapa h
   SET alterado_em = CASE WHEN n.total = 1 THEN n.criado_em
                          ELSE n.criado_em + (n.fim - n.criado_em) * (n.posicao - 1) / (n.total - 1)
                     END
FROM numerado n
WHERE n.id = h.id;

-- 4.2 Última atualização do lead = mudança de etapa ou interação mais recente.
UPDATE lead l
   SET atualizado_em = greatest(
           (SELECT max(h.alterado_em) FROM historico_etapa h WHERE h.lead_id = l.id),
           coalesce((SELECT max(i.data_hora) FROM interacao i WHERE i.lead_id = l.id), l.criado_em)
       );

-- 4.3 Score: mesma regra que o aplicativo aplica em JavaScript.
--     Origem (até 30) + cargo (até 25) + valor (até 25) + telefone (10) + interações (até 10).
UPDATE lead l
   SET score =
         CASE l.origem_id WHEN 2 THEN 30 WHEN 3 THEN 20 WHEN 4 THEN 15 WHEN 1 THEN 10 ELSE 5 END
       + CASE WHEN l.cargo ~* '(diretor|ceo|s[oó]ci[oa]|presidente|propriet)'  THEN 25
              WHEN l.cargo ~* '(gerente|coordenador|supervisor|head)'          THEN 15
              WHEN coalesce(trim(l.cargo), '') <> ''                           THEN 5
              ELSE 0 END
       + CASE WHEN l.valor_estimado >= 50000 THEN 25
              WHEN l.valor_estimado >= 20000 THEN 18
              WHEN l.valor_estimado >=  5000 THEN 10
              WHEN l.valor_estimado >      0 THEN 5
              ELSE 0 END
       + CASE WHEN coalesce(trim(l.telefone), '') <> '' THEN 10 ELSE 0 END
       + CASE WHEN n.total >= 3 THEN 10 WHEN n.total >= 1 THEN 5 ELSE 0 END
FROM (
    SELECT l2.id, count(i.id) AS total
    FROM lead l2 LEFT JOIN interacao i ON i.lead_id = l2.id
    GROUP BY l2.id
) n
WHERE n.id = l.id;

DROP TABLE carga_lead, carga_interacao;


-- ---------------------------------------------------------------------
-- 5. Conferência: deve listar as 6 etapas com 7, 6, 5, 4, 4 e 4 leads.
-- ---------------------------------------------------------------------

SELECT ef.ordem, ef.nome AS etapa, count(l.id) AS leads, coalesce(sum(l.valor_estimado), 0) AS valor_total
FROM etapa_funil ef
LEFT JOIN lead l ON l.etapa_id = ef.id
GROUP BY ef.id
ORDER BY ef.ordem;
