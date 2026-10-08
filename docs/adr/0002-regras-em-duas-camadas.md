# 0002. Manter as regras críticas no JavaScript e no banco

- **Status:** Aceita
- **Data:** 2026-10-08

## Contexto

As regras do funil precisam ser confiáveis e, ao mesmo tempo, dar uma resposta clara ao usuário. Exemplos: e-mail único, motivo obrigatório na perda, valor obrigatório no ganho e avanço de uma etapa por vez.

O banco, sozinho, garante a integridade, mas devolve mensagens técnicas em inglês, como `duplicate key value violates unique constraint "lead_email_unico"`. A tela, sozinha, dá boas mensagens, mas não protege o dado gravado por outro caminho: o editor de consultas do Appsmith, o SQL Editor do Neon ou uma futura integração.

Algumas regras dependem de mais de uma tabela ou do momento da ação, como "só avança quem já tem interação". Elas são mais simples de expressar e de explicar no JavaScript.

## Decisão

Vamos dividir as regras assim:

- **Banco** ([`banco/01_estrutura.sql`](../../banco/01_estrutura.sql)): tudo o que define se um dado é válido, com restrições `CHECK`, índice único, chaves estrangeiras e o gatilho do histórico. É a garantia final.
- **JavaScript** ([`appsmith/RegrasLead.js`](../../appsmith/RegrasLead.js), [`appsmith/RegrasEmpresa.js`](../../appsmith/RegrasEmpresa.js)):
  - validar antes de gravar, com mensagem em português;
  - aplicar as regras de fluxo do funil (uma etapa por vez, interação obrigatória, valor a partir de Proposta);
  - calcular o score;
  - traduzir os erros do banco que ainda escaparem (`traduzirErro`).

A tabela de regras em [`02-requisitos.md`](../02-requisitos.md) mostra onde cada regra vive.

## Alternativas consideradas

- **Só no JavaScript.** Descartada porque um dado gravado fora da tela poderia quebrar as regras (lead ganho sem valor, e-mail repetido).
- **Só no banco.** Descartada porque o usuário veria mensagens técnicas. Além disso, as regras de fluxo exigiriam gatilhos mais complexos, mais difíceis de manter e de testar.
- **Regras de fluxo também no banco (gatilho de validação).** Adiada. Seria a evolução natural se o sistema ganhasse outro cliente além destas telas.

## Consequências

- **Positivas:**
  - O usuário recebe mensagens claras.
  - O dado continua íntegro mesmo fora da tela.
  - As duas camadas têm testes próprios ([`testes/regras.test.mjs`](../../testes/regras.test.mjs) e [`testes/banco.sql`](../../testes/banco.sql)).
- **Negativas / riscos:**
  - Algumas regras existem em dois lugares. Se uma mudar, os dois lugares precisam mudar juntos.
  - O caso mais claro é o score: o cálculo está no JavaScript e foi repetido em SQL no script de dados de exemplo ([`banco/02_dados_exemplo.sql`](../../banco/02_dados_exemplo.sql)).
  - As regras de fluxo (RN04 a RN07) só existem no JavaScript. Quem grava direto no banco consegue, por exemplo, pular etapas.
