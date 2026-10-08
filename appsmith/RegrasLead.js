export default {
  // Pontuação do lead, de 0 a 100. É a mesma regra usada na carga de dados do banco.
  // Origem (até 30) + cargo (até 25) + valor (até 25) + telefone (10) + interações (até 10).
  calcularScore(lead) {
    const pontosPorOrigem = { 2: 30, 3: 20, 4: 15, 1: 10 }; // Indicação, Evento, LinkedIn, Site
    let pontos = pontosPorOrigem[lead.origem_id] || 5;

    const cargo = (lead.cargo || '').toLowerCase();
    if (/(diretor|ceo|s[oó]ci[oa]|presidente|propriet)/.test(cargo)) pontos += 25;
    else if (/(gerente|coordenador|supervisor|head)/.test(cargo)) pontos += 15;
    else if (cargo.trim() !== '') pontos += 5;

    const valor = Number(lead.valor_estimado) || 0;
    if (valor >= 50000) pontos += 25;
    else if (valor >= 20000) pontos += 18;
    else if (valor >= 5000) pontos += 10;
    else if (valor > 0) pontos += 5;

    if ((lead.telefone || '').trim() !== '') pontos += 10;

    const interacoes = Number(lead.total_interacoes) || 0;
    if (interacoes >= 3) pontos += 10;
    else if (interacoes >= 1) pontos += 5;

    return Math.min(pontos, 100);
  },

  // Confere o formulário e devolve a lista de problemas. Lista vazia = pode salvar.
  validar() {
    const problemas = [];
    const nome = (CampoNome.text || '').trim();
    const email = (CampoEmail.text || '').trim();
    const telefone = (CampoTelefone.text || '').replace(/\D/g, ''); // só os dígitos

    if (nome.length < 3) problemas.push('Informe o nome do lead (pelo menos 3 letras).');
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) problemas.push('Informe um e-mail válido.');
    if (telefone !== '' && telefone.length !== 10 && telefone.length !== 11) {
      problemas.push('O telefone deve ter DDD e mais 8 ou 9 dígitos.');
    }
    if (!CampoEmpresa.selectedOptionValue) problemas.push('Selecione a empresa.');
    if (!CampoOrigem.selectedOptionValue) problemas.push('Selecione a origem.');
    if (Number(CampoValor.text) < 0) problemas.push('O valor estimado não pode ser negativo.');

    return problemas;
  },

  // Transforma um erro do banco em uma mensagem que o usuário entende.
  traduzirErro(erro) {
    const texto = String(erro && erro.message ? erro.message : erro);
    if (texto.includes('lead_email_unico')) return 'Já existe um lead cadastrado com este e-mail.';
    if (texto.includes('lead_email_formato')) return 'O e-mail informado não é válido.';
    if (texto.includes('lead_ganho_tem_valor')) return 'Um lead ganho precisa ter valor estimado maior que zero.';
    if (texto.includes('lead_valor_positivo')) return 'O valor estimado não pode ser negativo.';
    if (texto.includes('lead_perdido_tem_motivo')) return 'Informe o motivo para marcar o lead como perdido.';
    if (texto.includes('interacao_descricao_preenchida')) return 'Descreva a interação antes de registrar.';
    return 'Não foi possível concluir a operação. Detalhe: ' + texto;
  },

  // Abre o formulário vazio, para cadastrar.
  async abrirNovo() {
    await storeValue('leadEmEdicao', null, false);
    showModal(ModalLead.name);
    resetWidget('ModalLead', true);
  },

  // Abre o formulário preenchido com um lead da tabela, para editar.
  async abrirEdicao(lead) {
    await storeValue('leadEmEdicao', lead, false);
    showModal(ModalLead.name);
    resetWidget('ModalLead', true);
  },

  // Valida, calcula o score e grava (insere ou atualiza).
  async salvar() {
    const problemas = this.validar();
    if (problemas.length > 0) {
      showAlert(problemas[0], 'warning');
      return;
    }

    const emEdicao = appsmith.store.leadEmEdicao;
    const score = this.calcularScore({
      origem_id: CampoOrigem.selectedOptionValue,
      cargo: CampoCargo.text,
      valor_estimado: CampoValor.text,
      telefone: CampoTelefone.text,
      total_interacoes: emEdicao ? emEdicao.total_interacoes : 0
    });

    try {
      if (emEdicao) {
        await AtualizarLead.run({ id: emEdicao.id, score: score });
      } else {
        await InserirLead.run({ score: score });
      }
      closeModal(ModalLead.name);
      await ListarLeads.run();
      showAlert(emEdicao ? 'Lead atualizado.' : 'Lead cadastrado com score ' + score + '.', 'success');
    } catch (erro) {
      showAlert(this.traduzirErro(erro), 'error');
    }
  },

  // ---------------------------------------------------------------
  // Detalhe do lead: interações e mudança de etapa
  // ---------------------------------------------------------------

  // Busca de novo no banco os dados do lead aberto e devolve o lead atualizado.
  async recarregarDetalhe() {
    const resultados = await Promise.all([
      BuscarLead.run(),
      ListarInteracoes.run(),
      ListarHistorico.run()
    ]);
    return resultados[0][0];
  },

  // Abre a janela de detalhe do lead clicado na tabela.
  async abrirDetalhe(lead) {
    await storeValue('leadAbertoId', lead.id, false);
    await this.recarregarDetalhe();
    showModal(ModalDetalhe.name);
    resetWidget('ModalDetalhe', true);
  },

  // Próxima etapa do funil para o lead aberto. Devolve null se ele já foi encerrado.
  proximaEtapa() {
    const lead = (BuscarLead.data || [])[0];
    const etapas = ListarEtapas.data || [];
    if (!lead || lead.encerrada) return null;
    const posicao = etapas.findIndex(etapa => etapa.id === lead.etapa_id);
    return etapas[posicao + 1] || null;
  },

  // Avança o lead uma etapa, se as regras do funil permitirem.
  async avancarEtapa() {
    const lead = (BuscarLead.data || [])[0];
    const proxima = this.proximaEtapa();

    if (!proxima) {
      showAlert('Este lead já foi encerrado e não muda mais de etapa.', 'warning');
      return;
    }
    if (Number(lead.total_interacoes) === 0) {
      showAlert('Registre pelo menos uma interação antes de avançar o lead.', 'warning');
      return;
    }
    if (proxima.id >= 3 && Number(lead.valor_estimado) <= 0) {
      showAlert('Informe o valor estimado do lead antes de avançar para ' + proxima.nome + '.', 'warning');
      return;
    }

    try {
      await MoverEtapa.run({ id: lead.id, etapa: proxima.id, motivo: '' });
      await this.recarregarDetalhe();
      await ListarLeads.run();
      showAlert('Lead movido para ' + proxima.nome + '.', 'success');
    } catch (erro) {
      showAlert(this.traduzirErro(erro), 'error');
    }
  },

  // Encerra o lead como perdido. O motivo é obrigatório.
  async marcarPerdido() {
    const lead = (BuscarLead.data || [])[0];
    const motivo = (CampoMotivoPerda.text || '').trim();

    if (!lead || lead.encerrada) {
      showAlert('Este lead já foi encerrado e não muda mais de etapa.', 'warning');
      return;
    }
    if (motivo.length < 5) {
      showAlert('Descreva o motivo da perda (pelo menos 5 letras).', 'warning');
      return;
    }

    try {
      await MoverEtapa.run({ id: lead.id, etapa: 6, motivo: motivo });
      await this.recarregarDetalhe();
      await ListarLeads.run();
      resetWidget('CampoMotivoPerda');
      showAlert('Lead marcado como perdido.', 'success');
    } catch (erro) {
      showAlert(this.traduzirErro(erro), 'error');
    }
  },

  // Registra um contato com o lead e recalcula o score, que depende do número de interações.
  async registrarInteracao() {
    const descricao = (CampoDescricaoInteracao.text || '').trim();

    if (!CampoTipoInteracao.selectedOptionValue) {
      showAlert('Selecione o tipo de interação.', 'warning');
      return;
    }
    if (descricao.length < 5) {
      showAlert('Descreva a interação (pelo menos 5 letras).', 'warning');
      return;
    }

    try {
      await InserirInteracao.run();
      const lead = await this.recarregarDetalhe(); // já com a nova contagem de interações
      await AtualizarScore.run({ id: lead.id, score: this.calcularScore(lead) });
      await BuscarLead.run();
      await ListarLeads.run();
      resetWidget('CampoDescricaoInteracao');
      showAlert('Interação registrada.', 'success');
    } catch (erro) {
      showAlert(this.traduzirErro(erro), 'error');
    }
  }
}
