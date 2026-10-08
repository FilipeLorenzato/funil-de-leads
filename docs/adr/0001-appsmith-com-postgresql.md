# 0001. Usar Appsmith com PostgreSQL (Neon)

- **Status:** Aceita
- **Data:** 2026-10-08

## Contexto

O projeto precisava ser entregue em poucos dias, em uma plataforma low-code, e mostrar mais do que telas arrastadas: modelagem de dados, SQL, regras de negócio e integração com uma API REST.

A primeira tentativa foi no OutSystems, mas a conta ficou bloqueada: o e-mail de recuperação de senha não chegava, o que impediu continuar o desenvolvimento.

## Decisão

Vamos usar o **Appsmith Cloud** para as telas, as consultas e as regras em JavaScript, ligado a um banco **PostgreSQL no Neon**.

O banco foi criado na região **AWS US East 2 (Ohio)**, e não em São Paulo. As consultas saem dos servidores do Appsmith Cloud, e não do navegador do usuário. Por isso, o que importa é a distância entre o Appsmith e o banco.

## Alternativas consideradas

- **OutSystems** foi descartado por causa do bloqueio de acesso à conta, que inviabilizou o prazo.
- **Planilha como fonte de dados** foi descartada porque não tem chave estrangeira, restrição nem gatilho. As regras ficariam só na tela, e o histórico de etapas dependeria de a tela lembrar de gravá-lo.
- **Neon na região de São Paulo** foi descartado porque cada consulta faria uma viagem extra entre os servidores do Appsmith, nos EUA, e o Brasil.

## Consequências

- **Positivas:**
  - O SQL é PostgreSQL padrão, versionado em [`banco/`](../../banco/) e testável fora do Appsmith ([`testes/banco.sql`](../../testes/banco.sql)).
  - As regras do banco valem para qualquer cliente, não só para estas telas (ver [ADR 0002](0002-regras-em-duas-camadas.md)).
  - Custo zero: os dois serviços estão no plano gratuito.
- **Negativas / riscos:**
  - No plano gratuito, o Neon "dorme" após 5 minutos sem uso. A primeira consulta depois disso demora alguns segundos.
  - O plano gratuito do Neon tem limite mensal de horas de processamento. Uso contínuo e intenso pode esgotar o limite antes do fim do mês.
  - As telas ficam no Appsmith, e não em arquivos de código. Para versioná-las, é preciso exportar o app em JSON. As consultas e os objetos JS foram copiados para [`appsmith/`](../../appsmith/) para poderem ser lidos e testados no repositório.
