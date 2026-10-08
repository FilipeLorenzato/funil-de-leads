# 0003. Registrar o histórico de etapas com um gatilho

- **Status:** Aceita
- **Data:** 2026-10-08

## Contexto

O painel precisa do **funil de conversão**: quantos leads chegaram a cada etapa em algum momento. A etapa atual não basta. Um lead que hoje está em Ganho também passou por Qualificado, Proposta e Negociação, e um lead perdido pode ter chegado até Proposta antes de ser perdido.

Para isso, cada mudança de etapa precisa ficar registrada, com data, sem depender de a tela lembrar de gravar.

## Decisão

Vamos usar o gatilho `lead_historico_etapa` (`AFTER INSERT OR UPDATE OF etapa_id ON lead`), que chama a função `registrar_mudanca_de_etapa`:

- na criação do lead, grava a etapa inicial, com etapa anterior nula;
- em uma alteração de `etapa_id` para um valor diferente, grava a etapa anterior e a nova;
- alterações que não mudam a etapa (nome, valor, score) não geram linha.

A consulta `FunilConversao` conta os leads distintos por etapa na tabela `historico_etapa`. Por isso, os números do funil só diminuem de uma etapa para a seguinte.

## Alternativas consideradas

- **Gravar o histórico pelo JavaScript**, com uma segunda consulta depois de `MoverEtapa`. Descartada por dois motivos: se a segunda consulta falhasse, o lead mudaria de etapa sem registro; e qualquer mudança feita fora da tela ficaria sem histórico.
- **Calcular o funil pela etapa atual.** Descartada porque contaria cada lead só uma vez, na etapa em que está hoje. O resultado seria uma "foto", e não um funil.

## Consequências

- **Positivas:**
  - O histórico é completo e consistente, venha a mudança de onde vier.
  - A tela não precisa de código para isso.
  - O mesmo histórico alimenta o painel e a janela de detalhe do lead.
- **Negativas / riscos:**
  - A regra fica "escondida" no banco. Quem lê só as telas não vê de onde vêm as linhas do histórico; por isso ela está documentada em [`04-modelo-de-dados.md`](../04-modelo-de-dados.md) e coberta por [`testes/banco.sql`](../../testes/banco.sql).
  - O script de dados de exemplo precisa mover cada lead etapa por etapa, em vez de inseri-lo direto na etapa final, para que o histórico fique realista.
