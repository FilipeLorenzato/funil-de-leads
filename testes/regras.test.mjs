// Testes das regras em JavaScript do Appsmith (RegrasLead e RegrasEmpresa).
// Rodar com:  node --test testes/
//
// O Appsmith executa esses objetos no navegador, com acesso aos componentes
// da tela (CampoNome, ModalLead...) e às consultas (InserirLead...). Aqui
// esses nomes são substituídos por versões falsas, que só registram o que
// foi chamado. Assim dá para testar as regras sem abrir o Appsmith.

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const pastaApp = new URL('../appsmith/', import.meta.url);

// Carrega um objeto JS do Appsmith com um "ambiente" falso.
function carregar(arquivo, ambiente) {
  const codigo = readFileSync(new URL(arquivo, pastaApp), 'utf8').replace('export default', 'return');
  const nomes = Object.keys(ambiente);
  return new Function(...nomes, codigo)(...nomes.map(nome => ambiente[nome]));
}

// Ambiente comum: store, alertas e janelas.
function ambienteBase() {
  const alertas = [];
  const chamadas = [];
  const appsmith = { store: {} };
  return {
    alertas, chamadas, appsmith,
    storeValue: async (chave, valor) => { appsmith.store[chave] = valor; },
    showAlert: (mensagem, tipo) => alertas.push({ mensagem, tipo }),
    showModal: nome => chamadas.push('abrir ' + nome),
    closeModal: nome => chamadas.push('fechar ' + nome),
    resetWidget: nome => chamadas.push('limpar ' + nome)
  };
}

// ---------------------------------------------------------------------
// RegrasLead
// ---------------------------------------------------------------------

function ambienteLead() {
  const base = ambienteBase();
  const campos = {
    CampoNome: { text: '' }, CampoEmail: { text: '' }, CampoTelefone: { text: '' },
    CampoCargo: { text: '' }, CampoEmpresa: { selectedOptionValue: '' },
    CampoOrigem: { selectedOptionValue: '' }, CampoValor: { text: null },
    CampoMotivoPerda: { text: '' }, CampoTipoInteracao: { selectedOptionValue: '' },
    CampoDescricaoInteracao: { text: '' }
  };
  const lead = { id: 9, etapa_id: 1, encerrada: false, total_interacoes: 0, valor_estimado: '0.00', origem_id: 1, cargo: 'Analista', telefone: null };
  const etapas = [
    { id: 1, nome: 'Novo' }, { id: 2, nome: 'Qualificado' }, { id: 3, nome: 'Proposta' },
    { id: 4, nome: 'Negociação' }, { id: 5, nome: 'Ganho' }, { id: 6, nome: 'Perdido' }
  ];
  const consultas = {
    BuscarLead: { data: [lead], run: async () => { consultas.BuscarLead.data = [{ ...lead }]; return consultas.BuscarLead.data; } },
    ListarInteracoes: { run: async () => [] },
    ListarHistorico: { run: async () => [] },
    ListarLeads: { run: async () => [] },
    ListarEtapas: { data: etapas },
    InserirLead: { run: async parametros => {
      base.chamadas.push('inserir ' + JSON.stringify(parametros));
      if (campos.CampoEmail.text === 'repetido@exemplo.com') {
        throw new Error('duplicate key value violates unique constraint "lead_email_unico"');
      }
    } },
    AtualizarLead: { run: async parametros => base.chamadas.push('atualizar ' + JSON.stringify(parametros)) },
    MoverEtapa: { run: async ({ etapa }) => { lead.etapa_id = etapa; lead.encerrada = etapa >= 5; } },
    InserirInteracao: { run: async () => { lead.total_interacoes += 1; } },
    AtualizarScore: { run: async parametros => base.chamadas.push('score ' + JSON.stringify(parametros)) }
  };
  const ambiente = { ...base, ...campos, ...consultas, ModalLead: { name: 'ModalLead' }, ModalDetalhe: { name: 'ModalDetalhe' } };
  return { ambiente, campos, lead, regras: carregar('RegrasLead.js', ambiente) };
}

test('score: soma origem, cargo, valor, telefone e interações, com teto de 100', () => {
  const { regras } = ambienteLead();
  // Site (10) + diretor (25) + valor >= 20 mil (18) + telefone (10)
  assert.equal(regras.calcularScore({ origem_id: 1, cargo: 'Diretor', valor_estimado: 30000, telefone: '(31) 90000-0999', total_interacoes: 0 }), 63);
  // Indicação (30) + CEO (25) + valor >= 50 mil (25) + telefone (10) + 3 interações (10) = 100
  assert.equal(regras.calcularScore({ origem_id: 2, cargo: 'CEO', valor_estimado: 120000, telefone: 'x', total_interacoes: 5 }), 100);
  // Origem desconhecida (5) e nenhum outro dado
  assert.equal(regras.calcularScore({ origem_id: 99 }), 5);
  // Cargo "Coordenadora" conta como gestão (15)
  assert.equal(regras.calcularScore({ origem_id: 4, cargo: 'Coordenadora de TI' }), 30);
});

test('validação do formulário aponta campos obrigatórios e telefone inválido', () => {
  const { regras, campos } = ambienteLead();
  assert.deepEqual(regras.validar(), [
    'Informe o nome do lead (pelo menos 3 letras).',
    'Informe um e-mail válido.',
    'Selecione a empresa.',
    'Selecione a origem.'
  ]);
  Object.assign(campos.CampoNome, { text: 'Maria Souza' });
  campos.CampoEmail.text = 'maria@exemplo.com';
  campos.CampoTelefone.text = '(31) 9999';
  campos.CampoEmpresa.selectedOptionValue = 3;
  campos.CampoOrigem.selectedOptionValue = 2;
  assert.deepEqual(regras.validar(), ['O telefone deve ter DDD e mais 8 ou 9 dígitos.']);
  campos.CampoTelefone.text = '(31) 99999-0000';
  assert.deepEqual(regras.validar(), []);
});

test('e-mail repetido vira mensagem amigável', async () => {
  const { regras, campos, ambiente } = ambienteLead();
  Object.assign(campos.CampoNome, { text: 'Teste' });
  campos.CampoEmail.text = 'repetido@exemplo.com';
  campos.CampoEmpresa.selectedOptionValue = 1;
  campos.CampoOrigem.selectedOptionValue = 1;
  await regras.abrirNovo();
  await regras.salvar();
  assert.equal(ambiente.alertas.at(-1).mensagem, 'Já existe um lead cadastrado com este e-mail.');
});

test('funil: só avança com interação, exige valor a partir de Proposta e trava leads encerrados', async () => {
  const { regras, campos, lead, ambiente } = ambienteLead();
  const ultimoAlerta = () => ambiente.alertas.at(-1).mensagem;

  await regras.abrirDetalhe({ id: 9 });
  assert.equal(regras.proximaEtapa().nome, 'Qualificado');

  await regras.avancarEtapa();
  assert.equal(ultimoAlerta(), 'Registre pelo menos uma interação antes de avançar o lead.');

  campos.CampoTipoInteracao.selectedOptionValue = 1;
  campos.CampoDescricaoInteracao.text = 'Ligação de apresentação';
  await regras.registrarInteracao();
  assert.equal(ultimoAlerta(), 'Interação registrada.');

  await regras.avancarEtapa();
  assert.equal(lead.etapa_id, 2);

  await regras.avancarEtapa();
  assert.match(ultimoAlerta(), /Informe o valor estimado/);
  assert.equal(lead.etapa_id, 2);

  lead.valor_estimado = '15000.00';
  await regras.recarregarDetalhe();
  await regras.avancarEtapa();
  assert.equal(lead.etapa_id, 3);

  await regras.marcarPerdido();
  assert.equal(ultimoAlerta(), 'Descreva o motivo da perda (pelo menos 5 letras).');

  campos.CampoMotivoPerda.text = 'Sem orçamento';
  await regras.marcarPerdido();
  assert.equal(lead.etapa_id, 6);
  assert.equal(regras.proximaEtapa(), null);

  await regras.avancarEtapa();
  assert.equal(ultimoAlerta(), 'Este lead já foi encerrado e não muda mais de etapa.');
});

// ---------------------------------------------------------------------
// RegrasEmpresa
// ---------------------------------------------------------------------

function ambienteEmpresa() {
  const base = ambienteBase();
  const inseridas = [];
  const respostas = {
    '47960950000121': { razao_social: 'MAGAZINE LUIZA S/A', nome_fantasia: 'MAGAZINE LUIZA', municipio: 'FRANCA', uf: 'SP', cnae_fiscal_descricao: 'Lojas de departamentos', descricao_situacao_cadastral: 'ATIVA' },
    '11222333000181': { razao_social: 'EMPRESA BAIXADA LTDA', nome_fantasia: '', municipio: 'BELO HORIZONTE', uf: 'MG', cnae_fiscal_descricao: '', descricao_situacao_cadastral: 'BAIXADA' }
  };
  const ambiente = {
    ...base,
    CampoCnpj: { text: '' },
    ModalEmpresa: { name: 'ModalEmpresa' },
    ConsultarCnpj: { run: async ({ cnpj }) => { if (respostas[cnpj]) return respostas[cnpj]; throw new Error('404'); } },
    InserirEmpresa: { run: async empresa => {
      if (inseridas.includes(empresa.cnpj)) throw new Error('duplicate key value violates unique constraint "empresa_cnpj_unico"');
      inseridas.push(empresa.cnpj);
    } },
    ListarEmpresasCompleto: { run: async () => [] }
  };
  return { ambiente, inseridas, regras: carregar('RegrasEmpresa.js', ambiente) };
}

test('CNPJ: confere dígitos verificadores e aplica máscara', () => {
  const { regras } = ambienteEmpresa();
  assert.equal(regras.cnpjValido('00.000.000/0001-91'), true);
  assert.equal(regras.cnpjValido('47960950000121'), true);
  assert.equal(regras.cnpjValido('11222333000182'), false); // dígito errado
  assert.equal(regras.cnpjValido('11111111111111'), false); // todos iguais
  assert.equal(regras.cnpjValido('123'), false);
  assert.equal(regras.formatarCnpj('00000000000191'), '00.000.000/0001-91');
});

test('empresa: consulta, cadastra uma vez e barra duplicada e situação diferente de ATIVA', async () => {
  const { regras, ambiente, inseridas } = ambienteEmpresa();
  const ultimoAlerta = () => ambiente.alertas.at(-1).mensagem;

  await regras.salvar();
  assert.equal(ultimoAlerta(), 'Busque o CNPJ antes de salvar.');

  ambiente.CampoCnpj.text = '11.111.111/1111-11';
  await regras.buscarCnpj();
  assert.equal(ultimoAlerta(), 'CNPJ inválido. Confira os 14 dígitos.');

  ambiente.CampoCnpj.text = '47.960.950/0001-21';
  await regras.buscarCnpj();
  assert.equal(ambiente.appsmith.store.empresaConsultada.nome, 'Magazine Luiza');
  assert.equal(ambiente.appsmith.store.empresaConsultada.cidade, 'Franca');
  assert.match(regras.resumoConsulta(ambiente.appsmith.store.empresaConsultada), /Situação na Receita: ATIVA/);

  await regras.salvar();
  assert.equal(ultimoAlerta(), 'Empresa cadastrada.');
  assert.deepEqual(inseridas, ['47.960.950/0001-21']);

  await regras.salvar();
  assert.equal(ultimoAlerta(), 'Esta empresa já está cadastrada.');

  ambiente.CampoCnpj.text = '11.222.333/0001-81';
  await regras.buscarCnpj();
  await regras.salvar();
  assert.equal(ultimoAlerta(), 'Só é possível cadastrar empresas com situação ATIVA na Receita.');
});
