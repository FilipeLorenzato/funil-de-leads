export default {
  // Deixa só os números de um texto. Ex.: '00.000.000/0001-91' -> '00000000000191'
  somenteDigitos(texto) {
    return String(texto || '').replace(/\D/g, '');
  },

  // Coloca a máscara do CNPJ: 00.000.000/0000-00
  formatarCnpj(cnpj) {
    const digitos = this.somenteDigitos(cnpj);
    if (digitos.length !== 14) return cnpj;
    return digitos.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5');
  },

  // Confere os dois dígitos verificadores do CNPJ (regra oficial da Receita).
  cnpjValido(cnpj) {
    const digitos = this.somenteDigitos(cnpj);
    if (digitos.length !== 14 || /^(\d)\1{13}$/.test(digitos)) return false;

    const calcularDigito = (base) => {
      const pesos = base.length === 12
        ? [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
        : [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
      const soma = base.split('').reduce((total, numero, i) => total + Number(numero) * pesos[i], 0);
      const resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    };

    const primeiro = calcularDigito(digitos.slice(0, 12));
    const segundo = calcularDigito(digitos.slice(0, 12) + primeiro);
    return digitos.endsWith(String(primeiro) + String(segundo));
  },

  // 'BELO HORIZONTE' -> 'Belo Horizonte'
  capitalizar(texto) {
    return String(texto || '').toLowerCase().replace(/(^|\s)\S/g, letra => letra.toUpperCase());
  },

  // Abre a janela de cadastro limpa.
  async abrirNova() {
    await storeValue('empresaConsultada', null, false);
    showModal(ModalEmpresa.name);
    resetWidget('ModalEmpresa', true);
  },

  // Valida o CNPJ e busca os dados da empresa na BrasilAPI (dados públicos da Receita Federal).
  async buscarCnpj() {
    const cnpj = this.somenteDigitos(CampoCnpj.text);
    if (!this.cnpjValido(cnpj)) {
      showAlert('CNPJ inválido. Confira os 14 dígitos.', 'warning');
      return;
    }

    try {
      const resposta = await ConsultarCnpj.run({ cnpj: cnpj });
      await storeValue('empresaConsultada', {
        cnpj: cnpj,
        nome: this.capitalizar(resposta.nome_fantasia || resposta.razao_social).slice(0, 100),
        razao_social: (resposta.razao_social || '').slice(0, 150),
        segmento: (resposta.cnae_fiscal_descricao || '').slice(0, 150),
        cidade: this.capitalizar(resposta.municipio).slice(0, 60),
        uf: (resposta.uf || '').toUpperCase(),
        situacao: resposta.descricao_situacao_cadastral || ''
      }, false);
    } catch (erro) {
      await storeValue('empresaConsultada', null, false);
      showAlert('CNPJ não encontrado na Receita Federal.', 'error');
    }
  },

  // Texto mostrado na janela com o resultado da consulta.
  resumoConsulta(empresa) {
    if (!empresa) return 'Digite o CNPJ e clique em "Buscar CNPJ" para trazer os dados da Receita Federal.';
    return [
      'Nome: ' + empresa.nome,
      'Razão social: ' + empresa.razao_social,
      'CNPJ: ' + this.formatarCnpj(empresa.cnpj),
      'Atividade: ' + (empresa.segmento || 'não informada'),
      'Cidade: ' + empresa.cidade + ' - ' + empresa.uf,
      'Situação na Receita: ' + empresa.situacao
    ].join('\n');
  },

  // Grava a empresa consultada. Só aceita empresas com situação ATIVA.
  async salvar() {
    const empresa = appsmith.store.empresaConsultada;
    if (!empresa) {
      showAlert('Busque o CNPJ antes de salvar.', 'warning');
      return;
    }
    if (empresa.situacao.toUpperCase() !== 'ATIVA') {
      showAlert('Só é possível cadastrar empresas com situação ATIVA na Receita.', 'warning');
      return;
    }

    try {
      // O CNPJ vai com a máscara e o banco guarda só os dígitos (ver InserirEmpresa).
      await InserirEmpresa.run({ ...empresa, cnpj: this.formatarCnpj(empresa.cnpj) });
      closeModal(ModalEmpresa.name);
      await ListarEmpresasCompleto.run();
      showAlert('Empresa cadastrada.', 'success');
    } catch (erro) {
      const texto = String(erro && erro.message ? erro.message : erro);
      if (texto.includes('empresa_cnpj_unico')) {
        showAlert('Esta empresa já está cadastrada.', 'warning');
      } else {
        showAlert('Não foi possível salvar. Detalhe: ' + texto, 'error');
      }
    }
  }
}
