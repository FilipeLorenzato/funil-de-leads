# Integração com a BrasilAPI

O sistema não expõe uma API própria. Ele consome uma API externa: a [BrasilAPI](https://brasilapi.com.br/docs), que publica dados abertos da Receita Federal.

## Chamada usada

### GET /api/cnpj/v1/{cnpj}

Configurada no Appsmith como a API `ConsultarCnpj` (página Empresas).

```
GET https://brasilapi.com.br/api/cnpj/v1/{{this.params.cnpj}}
```

`cnpj` vai só com os 14 dígitos. A função `RegrasEmpresa.buscarCnpj` só chama a API depois de conferir os dígitos verificadores, evitando requisições com CNPJ impossível.

**Exemplo**

```bash
curl https://brasilapi.com.br/api/cnpj/v1/47960950000121
```

**Campos usados da resposta**

| Campo da API | Uso no sistema |
|---|---|
| `nome_fantasia` | Nome da empresa nas telas (se vier vazio, usa a razão social). |
| `razao_social` | Razão social. |
| `cnae_fiscal_descricao` | Segmento. |
| `municipio` | Cidade (convertida de MAIÚSCULAS para "Primeira Letra Maiúscula"). |
| `uf` | Estado. |
| `descricao_situacao_cadastral` | Só empresas `ATIVA` podem ser cadastradas. |

**Respostas tratadas**

| Situação | O que o usuário vê |
|---|---|
| CNPJ com dígito verificador errado | "CNPJ inválido. Confira os 14 dígitos." (a API nem é chamada) |
| API responde com erro (CNPJ inexistente, falha de rede) | "CNPJ não encontrado na Receita Federal." |
| Empresa com situação diferente de ATIVA | "Só é possível cadastrar empresas com situação ATIVA na Receita." |
| CNPJ já cadastrado | "Esta empresa já está cadastrada." |

## Por que o CNPJ é enviado ao banco com máscara

Ao gravar, `InserirEmpresa` recebe o CNPJ formatado (`00.000.000/0001-91`) e o banco remove a pontuação com `regexp_replace`. Enviar só dígitos correria o risco de o valor ser tratado como número e perder os zeros à esquerda; com a pontuação, ele sempre trafega como texto.
