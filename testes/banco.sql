-- =====================================================================
-- Testes das regras garantidas pelo banco (restrições, gatilho e visão)
--
-- Rodar sobre os dados de exemplo (DEPOIS de 01_estrutura.sql e
-- 02_dados_exemplo.sql), no SQL Editor
-- do Neon ou com psql:   psql "$DATABASE_URL" -f testes/banco.sql
--
-- Tudo roda dentro de uma transação desfeita no final (ROLLBACK), então
-- os dados não mudam. Cada teste imprime "OK: ..." e, se uma regra
-- falhar, o script para com "FALHOU: ...".
-- =====================================================================

BEGIN;

DO $$
DECLARE
    novo_id bigint;
    total   int;
BEGIN
    -- Cada bloco BEGIN ... EXCEPTION tenta algo que o banco DEVE recusar.
    -- Se o comando passar, o teste falha; se o banco recusar, imprime OK.
    -- RN01: e-mail repetido, mesmo com letras maiúsculas
    BEGIN
        INSERT INTO lead (nome, email, empresa_id, origem_id) VALUES ('Dup', 'ANA.RIBEIRO@aurora.example.com', 1, 1);
        RAISE EXCEPTION 'FALHOU: aceitou e-mail repetido';
    EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'OK: e-mail repetido recusado';
    END;

    -- E-mail sem formato válido
    BEGIN
        INSERT INTO lead (nome, email, empresa_id, origem_id) VALUES ('Ruim', 'semarroba', 1, 1);
        RAISE EXCEPTION 'FALHOU: aceitou e-mail inválido';
    EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK: e-mail inválido recusado';
    END;

    -- Valor negativo
    BEGIN
        INSERT INTO lead (nome, email, empresa_id, origem_id, valor_estimado) VALUES ('Neg', 'neg@teste.example.com', 1, 1, -5);
        RAISE EXCEPTION 'FALHOU: aceitou valor negativo';
    EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK: valor negativo recusado';
    END;

    -- RN02: perdido sem motivo (nulo e em branco)
    BEGIN
        UPDATE lead SET etapa_id = 6 WHERE email = 'gabriela.pires@bompreco.example.com';
        RAISE EXCEPTION 'FALHOU: aceitou perdido sem motivo';
    EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK: perdido sem motivo recusado';
    END;
    BEGIN
        UPDATE lead SET etapa_id = 6, motivo_perda = '   ' WHERE email = 'gabriela.pires@bompreco.example.com';
        RAISE EXCEPTION 'FALHOU: aceitou motivo em branco';
    EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK: motivo em branco recusado';
    END;

    -- RN03: ganho com valor zero
    BEGIN
        UPDATE lead SET etapa_id = 5 WHERE email = 'bruno.tavares@vertice.example.com';
        RAISE EXCEPTION 'FALHOU: aceitou ganho com valor zero';
    EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK: ganho com valor zero recusado';
    END;

    -- Empresa: CNPJ fora do formato, CNPJ repetido, UF minúscula
    BEGIN
        INSERT INTO empresa (nome, cnpj) VALUES ('X', '123');
        RAISE EXCEPTION 'FALHOU: aceitou CNPJ com 3 dígitos';
    EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK: CNPJ fora do formato recusado';
    END;
    BEGIN
        INSERT INTO empresa (nome, cnpj) VALUES ('X', '11222333000181');
        RAISE EXCEPTION 'FALHOU: aceitou CNPJ repetido';
    EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'OK: CNPJ repetido recusado';
    END;
    BEGIN
        INSERT INTO empresa (nome, cnpj, uf) VALUES ('X', '99999999999999', 'mg');
        RAISE EXCEPTION 'FALHOU: aceitou UF minúscula';
    EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK: UF fora do padrão recusada';
    END;

    -- RN11: empresa com leads não pode ser apagada
    BEGIN
        DELETE FROM empresa WHERE cnpj = '11222333000181';
        RAISE EXCEPTION 'FALHOU: apagou empresa com leads';
    EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'OK: empresa com leads protegida';
    END;

    -- Interação sem descrição
    BEGIN
        INSERT INTO interacao (lead_id, tipo_id, descricao) VALUES (1, 1, '   ');
        RAISE EXCEPTION 'FALHOU: aceitou interação vazia';
    EXCEPTION WHEN check_violation THEN RAISE NOTICE 'OK: interação vazia recusada';
    END;

    -- Origem inexistente
    BEGIN
        INSERT INTO lead (nome, email, empresa_id, origem_id) VALUES ('Sem origem', 'a@b.example.com', 1, 99);
        RAISE EXCEPTION 'FALHOU: aceitou origem inexistente';
    EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'OK: origem inexistente recusada';
    END;

    -- RN09: o gatilho grava criação e mudança de etapa, e ignora outras alterações
    INSERT INTO lead (nome, email, empresa_id, origem_id) VALUES ('Teste Gatilho', 'gatilho@teste.example.com', 1, 1)
    RETURNING id INTO novo_id;
    UPDATE lead SET etapa_id = 2 WHERE id = novo_id;
    UPDATE lead SET nome = 'Teste Gatilho 2' WHERE id = novo_id;
    UPDATE lead SET etapa_id = 2 WHERE id = novo_id;
    SELECT count(*) INTO total FROM historico_etapa WHERE lead_id = novo_id;
    IF total <> 2 THEN RAISE EXCEPTION 'FALHOU: histórico com % linhas, esperado 2', total; END IF;
    RAISE NOTICE 'OK: histórico registrou criação e mudança de etapa';

    -- RN12: apagar o lead apaga junto interações e histórico
    INSERT INTO interacao (lead_id, tipo_id, descricao) VALUES (novo_id, 1, 'Contato de teste');
    DELETE FROM lead WHERE id = novo_id;
    SELECT (SELECT count(*) FROM historico_etapa WHERE lead_id = novo_id)
         + (SELECT count(*) FROM interacao WHERE lead_id = novo_id) INTO total;
    IF total <> 0 THEN RAISE EXCEPTION 'FALHOU: sobraram % registros do lead apagado', total; END IF;
    RAISE NOTICE 'OK: interações e histórico apagados junto com o lead';

    -- Visão vw_lead: uma linha por lead, com o resumo das interações
    IF (SELECT count(*) FROM vw_lead) <> (SELECT count(*) FROM lead) THEN
        RAISE EXCEPTION 'FALHOU: vw_lead não tem uma linha por lead';
    END IF;
    RAISE NOTICE 'OK: vw_lead tem uma linha por lead';

    RAISE NOTICE 'Todos os testes do banco passaram.';
END;
$$;

ROLLBACK;
