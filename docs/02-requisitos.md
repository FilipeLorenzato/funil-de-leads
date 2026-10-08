# Requisitos

## Requisitos funcionais

| ID | Descrição | Prioridade | Status |
|---|---|---|---|
| RF01 | O sistema deve permitir que o vendedor cadastre um lead com nome, e-mail, telefone, cargo, empresa, origem, valor estimado e observações. | Alta | Implementado |
| RF02 | O sistema deve permitir que o vendedor edite os dados de um lead. | Alta | Implementado |
| RF03 | O sistema deve listar os leads com busca por nome, empresa ou e-mail e filtros por etapa e origem. | Alta | Implementado |
| RF04 | O sistema deve permitir que o vendedor registre interações com o lead (tipo, data e descrição). | Alta | Implementado |
| RF05 | O sistema deve permitir que o vendedor avance o lead para a próxima etapa do funil. | Alta | Implementado |
| RF06 | O sistema deve permitir que o vendedor marque um lead como perdido, informando o motivo. | Alta | Implementado |
| RF07 | O sistema deve mostrar o histórico de mudanças de etapa de cada lead. | Média | Implementado |
| RF08 | O sistema deve calcular um score de 0 a 100 para cada lead. | Média | Implementado |
| RF09 | O sistema deve cadastrar empresas a partir do CNPJ, buscando os dados na Receita Federal. | Média | Implementado |
| RF10 | O sistema deve mostrar um painel com leads em aberto, valor em negociação, taxa de conversão, valor ganho, funil de conversão, conversão por origem e leads parados. | Média | Implementado |

## Requisitos não funcionais

| ID | Categoria | Descrição | Critério de aceite |
|---|---|---|---|
| RNF01 | Segurança | Nenhuma consulta monta SQL concatenando texto digitado pelo usuário. | Todos os valores entram por `{{ }}` com *prepared statements* ligado (padrão do Appsmith); nenhuma consulta em [`appsmith/consultas/`](../appsmith/consultas/) concatena texto. |
| RNF02 | Integridade | As regras críticas valem mesmo que o dado não venha da tela. | Todos os casos de [`testes/banco.sql`](../testes/banco.sql) são recusados pelo banco. |
| RNF03 | Segurança | Nenhuma credencial fica no repositório. | A senha do banco existe só na fonte de dados do Appsmith; busca por `npg_` e `password` no repositório não encontra valores reais. |
| RNF04 | Usabilidade | Erros aparecem em português e dizem o que fazer. | Toda violação conhecida de restrição é traduzida por `traduzirErro` (lead) ou tratada em `salvar` (empresa); nenhuma mensagem técnica do banco aparece nesses casos. |
| RNF05 | Custo | O sistema roda sem custo. | Appsmith Cloud (plano gratuito) e Neon (plano gratuito). |
| RNF06 | Manutenibilidade | As regras de negócio têm testes automatizados. | `node --test` passa os 6 testes de [`testes/regras.test.mjs`](../testes/regras.test.mjs). |

## Regras de negócio

| ID | Regra | Onde está |
|---|---|---|
| RN01 | Não pode haver dois leads com o mesmo e-mail, sem diferenciar maiúsculas e minúsculas. | Índice `lead_email_unico` e `RegrasLead.traduzirErro` |
| RN02 | Lead perdido precisa ter motivo (pelo menos 5 letras na tela; não pode ser vazio no banco). | `RegrasLead.marcarPerdido` e restrição `lead_perdido_tem_motivo` |
| RN03 | Lead ganho precisa ter valor estimado maior que zero. | Restrição `lead_ganho_tem_valor` |
| RN04 | O lead avança uma etapa por vez, na ordem Novo → Qualificado → Proposta → Negociação → Ganho. | `RegrasLead.proximaEtapa` e `avancarEtapa` |
| RN05 | Só avança quem tem pelo menos uma interação registrada. | `RegrasLead.avancarEtapa` |
| RN06 | Para ir a Proposta ou além, o valor estimado precisa ser maior que zero. | `RegrasLead.avancarEtapa` |
| RN07 | Lead encerrado (Ganho ou Perdido) não muda mais de etapa. | `RegrasLead.proximaEtapa` e `marcarPerdido` |
| RN08 | Score = origem (até 30) + cargo (até 25) + valor (até 25) + telefone (10) + interações (até 10), com teto de 100. É recalculado ao salvar o lead e a cada nova interação. | `RegrasLead.calcularScore` e restrição `lead_score_faixa` |
| RN09 | Toda criação de lead e mudança de etapa fica registrada no histórico, com data. | Gatilho `lead_historico_etapa` |
| RN10 | Empresa só é cadastrada com CNPJ válido (dígitos verificadores), não repetido e com situação ATIVA na Receita. | `RegrasEmpresa.cnpjValido`, `salvar` e restrição `empresa_cnpj_unico` |
| RN11 | Empresa com leads não pode ser apagada. | Chave estrangeira `lead.empresa_id` com `ON DELETE RESTRICT` |
| RN12 | Ao apagar um lead, suas interações e seu histórico são apagados junto. | Chaves estrangeiras com `ON DELETE CASCADE` |
| RN13 | Telefone é opcional, mas, se informado, precisa ter DDD e 8 ou 9 dígitos. | `RegrasLead.validar` |
