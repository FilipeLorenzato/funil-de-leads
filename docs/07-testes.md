# Testes

## Testes automatizados das regras em JavaScript

Arquivo: [`testes/regras.test.mjs`](../testes/regras.test.mjs). Usa o executor de testes nativo do Node.js, sem dependências.

```bash
node --test
```

Os objetos `RegrasLead` e `RegrasEmpresa` são carregados direto de [`appsmith/`](../appsmith/), com versões falsas dos componentes da tela e das consultas. Assim as regras são testadas sem abrir o Appsmith.

| Teste | O que verifica |
|---|---|
| score | Soma de origem, cargo, valor, telefone e interações; teto de 100; cargo no feminino ("Coordenadora") reconhecido. |
| validação do formulário | Campos obrigatórios e telefone com quantidade errada de dígitos. |
| e-mail repetido | O erro do banco vira "Já existe um lead cadastrado com este e-mail." |
| funil | Bloqueio sem interação, bloqueio sem valor a partir de Proposta, motivo obrigatório na perda e lead encerrado travado. |
| CNPJ | Dígitos verificadores, CNPJ com todos os dígitos iguais e máscara. |
| empresa | Consulta, cadastro, bloqueio de duplicada e de situação diferente de ATIVA. |

Resultado na última execução: 6 testes, 6 aprovados (Node.js 22).

## Testes das regras do banco

Arquivo: [`testes/banco.sql`](../testes/banco.sql). Roda sobre os dados de exemplo, dentro de uma transação desfeita no final.

```bash
psql "$DATABASE_URL" -f testes/banco.sql
```

Também pode ser colado no SQL Editor do Neon. Cada caso imprime `OK: ...`; se alguma regra falhar, o script para com `FALHOU: ...`.

Cobre: e-mail repetido e inválido, valor negativo, perdido sem motivo, ganho sem valor, CNPJ fora do formato e repetido, UF fora do padrão, empresa com leads protegida, interação vazia, origem inexistente, gatilho do histórico, exclusão em cascata e a visão `vw_lead`.

Resultado na última execução: 15 verificações aprovadas (PostgreSQL 16 local).

## Roteiro de teste manual (pela interface)

| # | Ação | Resultado esperado |
|---|---|---|
| 1 | Leads → filtro de etapa "Qualificado" | Só leads qualificados aparecem. |
| 2 | Leads → busca "aurora" | Só leads da Aurora Engenharia. |
| 3 | Novo lead → Salvar com tudo vazio | "Informe o nome do lead (pelo menos 3 letras)." |
| 4 | Novo lead com e-mail `ana.ribeiro@aurora.example.com` | "Já existe um lead cadastrado com este e-mail." |
| 5 | Novo lead: Site, cargo Diretor, R$ 30.000, com telefone | "Lead cadastrado com score 63." |
| 6 | Editar esse lead e trocar o cargo para Analista | "Lead atualizado." e score 43. |
| 7 | Abrir um lead sem interações → Avançar | "Registre pelo menos uma interação antes de avançar o lead." |
| 8 | Registrar interação | "Interação registrada." e score sobe 5 pontos (primeira interação). |
| 9 | Avançar para Qualificado e depois para Proposta com valor R$ 0 | Primeiro avança; depois "Informe o valor estimado do lead antes de avançar para Proposta." |
| 10 | Marcar como perdido sem motivo | "Descreva o motivo da perda (pelo menos 5 letras)." |
| 11 | Empresas → CNPJ `11.111.111/1111-11` | "CNPJ inválido. Confira os 14 dígitos." |
| 12 | Empresas → CNPJ `47.960.950/0001-21` → Salvar duas vezes | Primeiro "Empresa cadastrada.", depois "Esta empresa já está cadastrada." |

## O que não está coberto

- As telas do Appsmith (posição de componentes, ligações de eventos) não têm teste automatizado; são verificadas pelo roteiro manual acima.
- A chamada real à BrasilAPI não é testada automaticamente, para não depender de rede: nos testes ela é substituída por respostas fixas.
