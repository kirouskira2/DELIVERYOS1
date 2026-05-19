import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sprint 5.5: EstoqueScreen — Listagem de insumos com alertas de mínimo e entrada de mercadoria
class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _itens = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('estoque')
          .select('id, nome_item, unidade_medida, quantidade_atual, quantidade_minima, custo_unitario, categoria')
          .order('nome_item');
      if (mounted) {
        setState(() {
          _itens = data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _itens = [];
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filtrado => _itens
      .where((i) => (i['nome_item'] as String)
          .toLowerCase()
          .contains(_search.toLowerCase()))
      .toList();

  bool _isAbaixoMinimo(Map<String, dynamic> item) {
    final atual = (item['quantidade_atual'] as num).toDouble();
    final minima = (item['quantidade_minima'] as num).toDouble();
    return atual <= minima;
  }

  void _abrirModalNovoInsumo([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EstoqueFormModal(
        supabase: _supabase,
        item: item,
        onSaved: _load,
      ),
    );
  }

  void _abrirModalEntrada(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _EntradaEstoqueModal(
        item: item,
        supabase: _supabase,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de busca e botão de novo item
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'Inter'),
                decoration: InputDecoration(
                  hintText: 'Buscar insumo...',
                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                  prefixIcon: const Icon(LucideIcons.search,
                      size: 18, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1E293B))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1E293B))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2563EB))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _abrirModalNovoInsumo(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(LucideIcons.plus, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Novo Insumo',
                      style: TextStyle(fontFamily: 'Inter', color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
            ),
          ]),
        ),

        // Legenda de alertas
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(children: [
            Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B), shape: BoxShape.circle)),
            const SizedBox(width: 6),
            const Text('Abaixo do mínimo',
                style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF94A3B8),
                    fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 12),

        // Lista de itens
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF2563EB),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    itemCount: _filtrado.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = _filtrado[i] as Map<String, dynamic>;
                      final alerta = _isAbaixoMinimo(item);
                      return GestureDetector(
                        onTap: () => _abrirModalNovoInsumo(item),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: alerta
                                    ? const Color(0xFFF59E0B).withOpacity(0.5)
                                    : const Color(0xFF1E293B)),
                          ),
                          child: Row(children: [
                            // Indicador de alerta
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 14),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: alerta
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF34D399)),
                            ),

                            // Info do item
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['nome_item'] ?? '',
                                        style: const TextStyle(
                                            fontFamily: 'Inter',
                                            color: Color(0xFFF8FAFC),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text(
                                        '${item['categoria'] ?? 'Geral'} · R\$ ${(item['custo_unitario'] as num).toStringAsFixed(2)}/${item['unidade_medida']}',
                                        style: const TextStyle(
                                            fontFamily: 'Inter',
                                            color: Color(0xFF64748B),
                                            fontSize: 12)),
                                  ]),
                            ),

                            // Quantidade e mínimo
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      '${(item['quantidade_atual'] as num).toStringAsFixed(2)} ${item['unidade_medida']}',
                                      style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: alerta
                                              ? const Color(0xFFF59E0B)
                                              : const Color(0xFF34D399),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  Text(
                                      'Mín: ${(item['quantidade_minima'] as num).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontFamily: 'Inter',
                                          color: Color(0xFF64748B),
                                          fontSize: 11)),
                                ]),

                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _abrirModalEntrada(item),
                              child: const Icon(LucideIcons.plusCircle,
                                  color: Color(0xFF2563EB), size: 20),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () async {
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E293B),
                                    title: const Text('Excluir Insumo', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                                    content: const Text('Tem certeza que deseja excluir este insumo? Esta ação não pode ser desfeita.', style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter')),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Inter')),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                        child: const Text('Excluir', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmar == true) {
                                  try {
                                    await _supabase.from('estoque').delete().eq('id', item['id']);
                                    _load();
                                  } catch (e) {
                                    String msg = 'Erro ao excluir insumo: $e';
                                    if (e.toString().contains('foreign key') || e.toString().contains('violates foreign key')) {
                                      msg = 'Não é possível excluir este insumo pois ele está associado a fichas técnicas de produtos.';
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
                                      );
                                    }
                                  }
                                }
                              },
                              child: const Icon(LucideIcons.trash2,
                                  color: Color(0xFFEF4444), size: 20),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _EstoqueFormModal extends StatefulWidget {
  final SupabaseClient supabase;
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;
  const _EstoqueFormModal({required this.supabase, this.item, required this.onSaved});

  @override
  State<_EstoqueFormModal> createState() => _EstoqueFormModalState();
}

class _EstoqueFormModalState extends State<_EstoqueFormModal> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _unidadeCtrl;
  late final TextEditingController _qtdMinimaCtrl;
  late final TextEditingController _custoCtrl;
  bool _isSaving = false;
  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.item?['nome_item'] ?? '');
    _unidadeCtrl = TextEditingController(text: widget.item?['unidade_medida'] ?? 'UN');
    _qtdMinimaCtrl = TextEditingController(text: widget.item?['quantidade_minima']?.toString() ?? '0');
    _custoCtrl = TextEditingController(text: widget.item?['custo_unitario']?.toString() ?? '0.0');
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);

    final payload = {
      'nome_item': _nomeCtrl.text.trim(),
      'unidade_medida': _unidadeCtrl.text.trim(),
      'quantidade_minima': double.tryParse(_qtdMinimaCtrl.text.replaceAll(',', '.')) ?? 0,
      'custo_unitario': double.tryParse(_custoCtrl.text.replaceAll(',', '.')) ?? 0,
    };

    try {
      if (_isEdit) {
        await widget.supabase.from('estoque').update(payload).eq('id', widget.item!['id']);
      } else {
        await widget.supabase.from('estoque').insert(payload);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deletar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Excluir Insumo', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
        content: const Text('Tem certeza que deseja excluir este insumo? Esta ação não pode ser desfeita e removerá os vínculos deste insumo nas fichas técnicas.', style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Inter')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Excluir', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isSaving = true);
    try {
      // 1. Deletar vínculos na ficha técnica primeiro
      await widget.supabase.from('ficha_tecnica').delete().eq('estoque_id', widget.item!['id']);
      
      // 2. Deletar do estoque
      await widget.supabase.from('estoque').delete().eq('id', widget.item!['id']);
      
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir insumo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isEdit ? 'Editar Insumo' : 'Novo Insumo',
              style: const TextStyle(fontFamily: 'Inter', color: Color(0xFFF8FAFC),
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          TextField(
            controller: _nomeCtrl,
            style: const TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'Inter'),
            decoration: InputDecoration(labelText: 'Nome do Insumo',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true, fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _unidadeCtrl,
            style: const TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'Inter'),
            decoration: InputDecoration(labelText: 'Unidade de Medida (KG, L, UN)',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true, fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtdMinimaCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'Inter'),
            decoration: InputDecoration(labelText: 'Estoque Mínimo',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true, fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _custoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'Inter'),
            decoration: InputDecoration(labelText: 'Custo Unitário Base',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
              filled: true, fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_isEdit) ...[
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _deletar,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Icon(LucideIcons.trash2, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: _isEdit ? 3 : 1,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _salvar,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: _isSaving
                        ? const SizedBox(height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Salvar Alterações' : 'Cadastrar Insumo',
                            style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

/// Modal de Entrada de Estoque (Bottom Sheet)
class _EntradaEstoqueModal extends StatefulWidget {
  final Map<String, dynamic> item;
  final SupabaseClient supabase;
  final VoidCallback onSaved;

  const _EntradaEstoqueModal({
    required this.item,
    required this.supabase,
    required this.onSaved,
  });

  @override
  State<_EntradaEstoqueModal> createState() => _EntradaEstoqueModalState();
}

class _EntradaEstoqueModalState extends State<_EntradaEstoqueModal> {
  final _qtdController = TextEditingController();
  bool _isSaving = false;

  Future<void> _salvar() async {
    final qtd = double.tryParse(_qtdController.text.replaceAll(',', '.'));
    if (qtd == null || qtd <= 0) return;

    setState(() => _isSaving = true);
    try {
      final atual =
          (widget.item['quantidade_atual'] as num).toDouble();
      await widget.supabase.from('estoque').update({
        'quantidade_atual': atual + qtd,
      }).eq('id', widget.item['id'] as String);

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Entrada: ${widget.item['nome_item']}',
            style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFFF8FAFC),
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 4),
        Text(
            'Estoque atual: ${(widget.item['quantidade_atual'] as num).toStringAsFixed(2)} ${widget.item['unidade_medida']}',
            style: const TextStyle(
                fontFamily: 'Inter', color: Color(0xFF64748B), fontSize: 13)),
        const SizedBox(height: 20),
        TextField(
          controller: _qtdController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'Inter'),
          decoration: InputDecoration(
            labelText: 'Quantidade a adicionar (${widget.item['unidade_medida']})',
            labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter'),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF334155))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF334155))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF2563EB))),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _salvar,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: _isSaving
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Confirmar Entrada',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}
