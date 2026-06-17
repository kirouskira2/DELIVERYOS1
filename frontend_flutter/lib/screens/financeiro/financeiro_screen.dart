import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/finance_repository.dart';
import '../../utils/responsive.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  final FinanceRepository _repository = FinanceRepository();
  List<dynamic> _lancamentos = [];
  List<dynamic> _mensal = [];
  bool _isLoading = true;
  String _filtroTipo = 'TODOS';

  double _totalReceitas = 0;
  double _totalDespesas = 0;
  double _saldo = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final financeData = await _repository.getFinanceData();
      final transacoes = financeData['transacoes'] as List<dynamic>? ?? [];
      final mensal = financeData['mensal'] as List<dynamic>? ?? [];
      
      double rec = 0;
      double des = 0;
      for (var t in transacoes) {
        if (t['tipo'] == 'RECEITA') rec += (t['valor'] as num).toDouble();
        if (t['tipo'] == 'DESPESA') des += (t['valor'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _lancamentos = transacoes;
          _mensal = mensal;
          _totalReceitas = rec;
          _totalDespesas = des;
          _saldo = rec - des;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lancamentos = [];
          _mensal = [];
          _totalReceitas = 0;
          _totalDespesas = 0;
          _saldo = 0;
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filtrado => _filtroTipo == 'TODOS'
      ? _lancamentos
      : _lancamentos.where((l) => l['tipo'] == _filtroTipo).toList();

  void _abrirModalFormLancamento({String? tipoPredefinido, Map<String, dynamic>? transactionToEdit}) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      // Mobile: BottomSheet fullscreen
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1E293B),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: _LancamentoFormContent(
              onSaved: _load,
              tipoPredefinido: tipoPredefinido ?? (transactionToEdit?['tipo'] ?? 'RECEITA'),
              transactionToEdit: transactionToEdit,
              repository: _repository,
            ),
          ),
        ),
      );
    } else {
      // Desktop: Slide lateral
      showGeneralDialog(
        context: context,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, _, __) => _LancamentoFormModal(
          onSaved: _load,
          tipoPredefinido: tipoPredefinido ?? (transactionToEdit?['tipo'] ?? 'RECEITA'),
          transactionToEdit: transactionToEdit,
          repository: _repository,
        ),
        transitionBuilder: (context, anim, secondaryAnim, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
            child: child,
          );
        },
      );
    }
  }

  Future<void> _deletarLancamento(String id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir Lançamento', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        content: const Text('Tem certeza de que deseja excluir permanentemente este lançamento?', style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar', style: TextStyle(color: Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Excluir', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _repository.deleteTransaction(id);
        _load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lançamento excluído com sucesso!'), backgroundColor: Color(0xFF10B981)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      // FAB no mobile para ações rápidas
      floatingActionButton: isMobile
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF2563EB),
              onPressed: () => _showMobileActionSheet(),
              child: const Icon(LucideIcons.plus, color: Colors.white),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── HEADER ──────────────────────────────────────
                  _buildHeader(isMobile),
                  const SizedBox(height: 20),
                  
                  // ─── KPIs ────────────────────────────────────────
                  _buildKPIs(isMobile),
                  const SizedBox(height: 24),
                  
                  // ─── GRÁFICO ─────────────────────────────────────
                  _buildChart(isMobile),
                  const SizedBox(height: 24),

                  // ─── FILTROS + TABELA ─────────────────────────────
                  _buildFilters(isMobile),
                  const SizedBox(height: 16),
                  _buildTransactionsList(isMobile),
                ],
              ),
            ),
    );
  }

  void _showMobileActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF475569), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(LucideIcons.plusCircle, color: Color(0xFF10B981), size: 20),
                ),
                title: const Text('Lançar Receita', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                subtitle: const Text('Adicionar entrada financeira', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                onTap: () { Navigator.pop(context); _abrirModalFormLancamento(tipoPredefinido: 'RECEITA'); },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFEF4444).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(LucideIcons.minusCircle, color: Color(0xFFEF4444), size: 20),
                ),
                title: const Text('Adicionar Despesa', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                subtitle: const Text('Registrar saída / CMV', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                onTap: () { Navigator.pop(context); _abrirModalFormLancamento(tipoPredefinido: 'DESPESA'); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    if (isMobile) {
      return const Text('Financeiro & CMV', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter'));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Financeiro & CMV', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _abrirModalFormLancamento(tipoPredefinido: 'DESPESA'),
              icon: const Icon(LucideIcons.minusCircle, size: 16, color: Colors.white),
              label: const Text('Adicionar Despesa', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _abrirModalFormLancamento(tipoPredefinido: 'RECEITA'),
              icon: const Icon(LucideIcons.plusCircle, size: 16, color: Colors.white),
              label: const Text('Lançar Receita', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPIs(bool isMobile) {
    final cards = [
      _TotalizadorCard(label: 'Receitas', valor: _totalReceitas, cor: const Color(0xFF10B981), icon: LucideIcons.trendingUp),
      _TotalizadorCard(label: 'CMV / Despesas', valor: _totalDespesas, cor: const Color(0xFFEF4444), icon: LucideIcons.trendingDown),
      _TotalizadorCard(label: 'Lucro Bruto', valor: _saldo, cor: const Color(0xFF3B82F6), icon: LucideIcons.wallet),
    ];

    if (isMobile) {
      // Mobile: empilhar verticalmente
      return Column(
        children: cards.map((card) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: card,
        )).toList(),
      );
    }

    // Desktop: 3 em linha
    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
        const SizedBox(width: 16),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _buildChart(bool isMobile) {
    return Container(
      height: isMobile ? 220 : 300,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Receita vs CMV (Mensal)', style: TextStyle(color: Colors.white, fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, m) => Text('M${v.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'Inter')),
                  )),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _mensal.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final receita = (item['receita'] as num?)?.toDouble() ?? 0.0;
                  final despesa = (item['despesa_cmv'] as num?)?.toDouble() ?? 0.0;
                  final barWidth = isMobile ? 8.0 : 12.0;
                  
                  return BarChartGroupData(x: idx, barRods: [
                    BarChartRodData(toY: receita, color: const Color(0xFF10B981), width: barWidth, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                    BarChartRodData(toY: despesa, color: const Color(0xFFEF4444), width: barWidth, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  ]);
                }).toList(),
              ),
              swapAnimationDuration: const Duration(milliseconds: 800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isMobile) {
    final chips = [
      _buildFilterChip('TODOS', 'Todos', const Color(0xFF2563EB)),
      _buildFilterChip('RECEITA', 'Receitas', const Color(0xFF10B981)),
      _buildFilterChip('DESPESA', 'Despesas', const Color(0xFFEF4444)),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Histórico de Transações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: chips),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Histórico de Transações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
        Row(children: chips.map((c) => Padding(padding: const EdgeInsets.only(left: 8), child: c)).toList()),
      ],
    );
  }

  Widget _buildFilterChip(String tipo, String label, Color activeColor) {
    return ChoiceChip(
      label: Text(label),
      selected: _filtroTipo == tipo,
      onSelected: (val) => setState(() => _filtroTipo = tipo),
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: activeColor,
      labelStyle: TextStyle(color: _filtroTipo == tipo ? Colors.white : Colors.grey, fontFamily: 'Inter', fontSize: 13),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTransactionsList(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: _filtrado.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('Nenhuma transação encontrada.', style: TextStyle(color: Colors.grey, fontFamily: 'Inter'))),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filtrado.length,
              separatorBuilder: (c, i) => const Divider(color: Color(0xFF334155), height: 1),
              itemBuilder: (context, index) {
                final t = _filtrado[index];
                final isReceita = t['tipo'] == 'RECEITA';
                final String transId = t['id'].toString();
                final String dataCrua = t['data_transacao'] ?? '';
                final String dataFormatada = dataCrua.length >= 16 ? dataCrua.replaceAll('T', ' ').substring(0, 16) : dataCrua;
                final valorStr = '${isReceita ? '+' : '-'} R\$ ${(t['valor'] as num).toDouble().toStringAsFixed(2)}';

                if (isMobile) {
                  return _buildMobileTransactionTile(t, isReceita, transId, dataFormatada, valorStr);
                }
                return _buildDesktopTransactionTile(t, isReceita, transId, dataFormatada, valorStr);
              },
            ),
    );
  }

  Widget _buildMobileTransactionTile(dynamic t, bool isReceita, String transId, String dataFormatada, String valorStr) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: isReceita ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFEF4444).withOpacity(0.15),
          child: Icon(isReceita ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight, color: isReceita ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 18),
        ),
        title: Text(t['descricao'] ?? 'Sem descrição', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter', fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${t['categoria'] ?? 'Geral'} · $dataFormatada', style: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter', fontSize: 11)),
        trailing: Text(valorStr, style: TextStyle(color: isReceita ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Inter')),
        onTap: () => _showMobileTransactionActions(t, transId),
      ),
    );
  }

  void _showMobileTransactionActions(dynamic t, String transId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF475569), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(t['descricao'] ?? 'Sem descrição', style: const TextStyle(color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(LucideIcons.pencil, color: Color(0xFF60A5FA), size: 20),
                title: const Text('Editar', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                onTap: () { Navigator.pop(context); _abrirModalFormLancamento(transactionToEdit: t); },
              ),
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: Color(0xFFF87171), size: 20),
                title: const Text('Excluir', style: TextStyle(color: Color(0xFFF87171), fontFamily: 'Inter')),
                onTap: () { Navigator.pop(context); _deletarLancamento(transId); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTransactionTile(dynamic t, bool isReceita, String transId, String dataFormatada, String valorStr) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isReceita ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFEF4444).withOpacity(0.15),
          child: Icon(isReceita ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight, color: isReceita ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
        ),
        title: Text(t['descricao'] ?? 'Sem descrição', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        subtitle: Text('${t['categoria'] ?? 'Geral'} · $dataFormatada', style: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(valorStr, style: TextStyle(color: isReceita ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter')),
            const SizedBox(width: 16),
            IconButton(icon: const Icon(LucideIcons.pencil, size: 16, color: Color(0xFF60A5FA)), onPressed: () => _abrirModalFormLancamento(transactionToEdit: t), tooltip: 'Editar'),
            IconButton(icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFF87171)), onPressed: () => _deletarLancamento(transId), tooltip: 'Excluir'),
          ],
        ),
      ),
    );
  }
}

// ─── KPI CARD ────────────────────────────────────────────────────────────────

class _TotalizadorCard extends StatelessWidget {
  final String label;
  final double valor;
  final Color cor;
  final IconData icon;

  const _TotalizadorCard({required this.label, required this.valor, required this.cor, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cor, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter'), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 12),
          Text('R\$ ${valor.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        ],
      ),
    );
  }
}

// ─── FORM: CONTEÚDO COMPARTILHADO ────────────────────────────────────────────

class _LancamentoFormContent extends StatefulWidget {
  final VoidCallback onSaved;
  final String tipoPredefinido;
  final Map<String, dynamic>? transactionToEdit;
  final FinanceRepository repository;

  const _LancamentoFormContent({required this.onSaved, required this.tipoPredefinido, this.transactionToEdit, required this.repository});

  @override
  State<_LancamentoFormContent> createState() => _LancamentoFormContentState();
}

class _LancamentoFormContentState extends State<_LancamentoFormContent> {
  final _formKey = GlobalKey<FormState>();
  late String _descricao;
  late double _valor;
  late String _categoria;
  bool _isLoading = false;

  static const List<String> _categoriasValidas = ['Geral', 'Insumos', 'Salários', 'Marketing', 'Aluguel', 'Vendas', 'Vendas (PDV)', 'Outros'];

  @override
  void initState() {
    super.initState();
    _descricao = widget.transactionToEdit?['descricao'] ?? '';
    _valor = (widget.transactionToEdit?['valor'] as num?)?.toDouble() ?? 0.0;
    final categoriaFromEdit = widget.transactionToEdit?['categoria'] ?? 'Geral';
    _categoria = _categoriasValidas.contains(categoriaFromEdit) ? categoriaFromEdit : 'Geral';
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      if (widget.transactionToEdit != null) {
        await widget.repository.updateTransaction(widget.transactionToEdit!['id'].toString(), {'descricao': _descricao, 'valor': _valor, 'categoria': _categoria});
      } else {
        await widget.repository.addTransaction({'tipo': widget.tipoPredefinido, 'descricao': _descricao, 'valor': _valor, 'categoria': _categoria, 'status': 'pago'});
      }
      if (mounted) { Navigator.pop(context); widget.onSaved(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.transactionToEdit != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF475569), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(isEdit ? 'Editar Lançamento' : 'Novo ${widget.tipoPredefinido}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: _descricao,
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              decoration: _inputDecoration('Descrição'),
              validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
              onSaved: (v) => _descricao = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: isEdit ? _valor.toString() : '',
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration('Valor (R\$)'),
              validator: (v) { if (v == null || v.isEmpty) return 'Campo obrigatório'; if (double.tryParse(v) == null) return 'Valor inválido'; return null; },
              onSaved: (v) => _valor = double.parse(v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoria,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              decoration: _inputDecoration('Categoria'),
              items: _categoriasValidas.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _categoria = val ?? 'Geral'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.tipoPredefinido == 'RECEITA' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? 'SALVAR ALTERAÇÕES' : 'SALVAR LANÇAMENTO', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15, fontFamily: 'Inter')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label, labelStyle: const TextStyle(color: Colors.grey),
    filled: true, fillColor: const Color(0xFF0F172A),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF334155))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
  );
}

// ─── FORM: MODAL DESKTOP (Slide lateral) ─────────────────────────────────────

class _LancamentoFormModal extends StatelessWidget {
  final VoidCallback onSaved;
  final String tipoPredefinido;
  final Map<String, dynamic>? transactionToEdit;
  final FinanceRepository repository;

  const _LancamentoFormModal({required this.onSaved, required this.tipoPredefinido, this.transactionToEdit, required this.repository});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: const Color(0xFF1E293B),
        child: Container(
          width: screenWidth < 500 ? screenWidth : 400,
          height: double.infinity,
          decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF334155)))),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: _LancamentoFormContent(
                    onSaved: onSaved,
                    tipoPredefinido: tipoPredefinido,
                    transactionToEdit: transactionToEdit,
                    repository: repository,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
