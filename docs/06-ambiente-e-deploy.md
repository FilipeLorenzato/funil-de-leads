# Ambiente e publicação

O sistema roda inteiro na nuvem, sem instalar nada no computador: o banco no Neon e a aplicação no Appsmith Cloud.

## Pré-requisitos

- Conta no [Neon](https://neon.com) (plano gratuito).
- Conta no [Appsmith Cloud](https://app.appsmith.com) (plano gratuito).
- Para rodar os testes automatizados: Node.js 22 e, opcionalmente, `psql`.

## 1. Banco de dados (Neon)

1. Criar um projeto com Postgres. Região recomendada: **AWS US East 2 (Ohio)**, a mesma dos servidores do Appsmith Cloud.
2. No **SQL Editor**, rodar [`banco/01_estrutura.sql`](../banco/01_estrutura.sql). Na primeira execução aparecem avisos "does not exist, skipping": são esperados, porque o script tenta apagar tabelas que ainda não existem.
3. Rodar [`banco/02_dados_exemplo.sql`](../banco/02_dados_exemplo.sql). O último resultado deve listar as 6 etapas com 7, 6, 5, 4, 4 e 4 leads.
4. Em **Connect**, desligar **Connection pooling** e anotar host, banco, usuário e senha.

## 2. Aplicação (Appsmith)

**Opção A: importar o app.** Na tela inicial do Appsmith, em *Create new → Import*, escolher [`appsmith/funil-de-leads.json`](../appsmith/funil-de-leads.json). O Appsmith pede os dados da fonte de dados `BancoFunil`: preencher com os do passo 1.4.

O arquivo exportado não contém usuário nem senha do banco, e o endereço do servidor foi apagado antes de ir para o repositório.

**Opção B: montar do zero.** Criar a fonte de dados PostgreSQL `BancoFunil` com:

| Campo | Valor |
|---|---|
| Host address | host do Neon (`ep-....aws.neon.tech`) |
| Port | `5432` |
| Database name | `neondb` |
| Username | `neondb_owner` |
| Password | senha do Neon |
| SSL mode | `Require` |

Depois criar as consultas de [`appsmith/consultas/`](../appsmith/consultas/) e os objetos JS de [`appsmith/`](../appsmith/), página por página.

A senha fica guardada criptografada na fonte de dados do Appsmith e não vai para o repositório.

## 3. Como verificar

- Página **Leads**: a tabela mostra 30 leads (ou mais, se houver cadastros novos).
- Página **Painel**: "Taxa de conversão: 50%" com os dados de exemplo.
- Página **Empresas**: **Nova empresa** → CNPJ `47.960.950/0001-21` → **Buscar CNPJ** mostra os dados da Receita.

## 4. Restaurar os dados de exemplo

Rodar de novo `02_dados_exemplo.sql`. Ele apaga leads, empresas, interações e histórico e insere tudo de novo, com datas calculadas a partir do dia em que é executado.

## Problemas comuns

| Sintoma | Causa | Solução |
|---|---|---|
| "password authentication failed" ao testar a fonte de dados | Senha copiada incompleta | No Neon, **Connect → Parameters only → Show password**, copiar o valor inteiro de `PGPASSWORD` (começa com `npg_`). |
| Primeira consulta do dia demora ou falha | O banco gratuito do Neon "dorme" após 5 minutos sem uso | Recarregar a página; a segunda tentativa já encontra o banco acordado. |
| Lista de "Label key" vazia ("Not Found") ao configurar um Select | A consulta de origem ainda não foi executada | Rodar a consulta na aba **Queries** e voltar ao componente. |
| Componente arrastado não aparece dentro da janela | O modal estava fechado na hora de soltar | Clicar no modal na lista de componentes para abri-lo e arrastar de novo. |

## Publicação

O app é publicado pelo botão **Deploy** do Appsmith e compartilhado em **Share**.

App publicado (público, com dados fictícios): <https://app.appsmith.com/app/funil-de-leads/painel-6ac7e6f87cdd178ba398507c>

Como o app é público, qualquer pessoa com o link pode cadastrar e editar leads. Para voltar ao estado inicial, rode de novo `02_dados_exemplo.sql`.
