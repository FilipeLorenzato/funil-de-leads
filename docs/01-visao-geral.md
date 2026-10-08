# Visão geral

## Problema

Equipes comerciais pequenas costumam controlar leads em planilhas. Nelas não há regra de etapa, o mesmo contato aparece duas vezes, ninguém sabe quando foi o último contato e é difícil responder perguntas simples, como "quantos leads viraram venda" ou "qual origem traz os melhores clientes".

## Objetivo

O Funil de Leads organiza o caminho de cada lead, do primeiro contato até o fechamento. Ele registra empresas e contatos, guarda o histórico de interações, controla a passagem pelas etapas do funil com regras de negócio e mostra indicadores para priorizar o trabalho.

## Usuários

| Perfil | O que faz no sistema |
|---|---|
| Vendedor | Cadastra e edita leads, registra interações, avança o lead no funil ou o marca como perdido. |
| Gestor comercial | Acompanha o painel: leads em aberto, valor em negociação, taxa de conversão, funil e leads parados. |

A aplicação não diferencia perfis hoje: quem tem acesso ao app vê e faz tudo.

## Escopo

**Dentro do escopo**

- Cadastro, edição, busca e filtro de leads.
- Cadastro de empresas a partir do CNPJ, com dados da Receita Federal (via BrasilAPI).
- Registro de interações (ligação, e-mail, reunião, mensagem).
- Funil com seis etapas e regras de avanço.
- Score de 0 a 100 para priorizar leads.
- Histórico automático de mudanças de etapa.
- Painel de indicadores.

**Fora do escopo**

- Login próprio e perfis de acesso: o controle de acesso é o do próprio Appsmith (app privado ou público).
- Exclusão de leads e empresas pela interface: o banco já trata exclusões com segurança (ver [modelo de dados](04-modelo-de-dados.md)), mas não há botão para isso, para evitar perda acidental de histórico.
- Envio de e-mails e integração com agenda: as interações são registradas manualmente.

## Contexto

Projeto individual de portfólio, desenvolvido por Filipe Lorenzato (Ciência da Computação, PUC Minas) para demonstrar desenvolvimento low-code com modelagem de dados, SQL, lógica de negócio e integração com API REST.
