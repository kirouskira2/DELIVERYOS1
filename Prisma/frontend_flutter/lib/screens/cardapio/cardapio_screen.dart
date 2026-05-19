import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sprint 5.8: CardapioScreen — Listagem de produtos com gestão de disponibilidade
class CardapioScreen extends StatefulWidget {
  const CardapioScreen({super.key});

  @override
  State<CardapioScreen> createState() => _CardapioScreenState();
}

class _CardapioScreenState extends State<CardapioScreen> {
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
          .from('cardapio')
          .select('id, nome, descricao, categoria, preco_venda, custo_producao, disponivel')
          .order('categoria')
          .order('nome');
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

  Future<void> _toggleDisponivel(String id, bool atual) async {
    try {
      await _supabase
          .from('cardapio')
          .update({'disponivel': !atual})
          .eq('id', id);
      await _load();
    } catch (_) {}
  }

  List<dynamic> get _filtrado => _itens
      .where((i) =>
          (i['nome'] as String).toLowerCase().contains(_search.toLowerCase()))
      .toList();

  void _abrirModal([Map<String, dynamic>? item]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _CardapioFormModal(
        supabase: _supabase,
        item: item,
        onSaved: _load,
      ),
    );
  }

  void _abrirFichaTecnica(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _FichaTecnicaModal(
        supabase: _supabase,
        item: item,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de busca e botão novo
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'Inter'),
                decoration: InputDecoration(
                  hintText: 'Buscar prato...',
                  hintStyle: const TextStyle(color: Color(0xFF475569)),
                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: Color(0xFF64748B)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1E293B))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1E293B))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF2563EB))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _abrirModal(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(LucideIcons.plus, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Novo Prato',
                      style: TextStyle(fontFamily: 'Inter', color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
            ),
          ]),
        ),

        // Lista de itens
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF2563EB),
                  child: _filtrado.isEmpty
                      ? const Center(
                          child: Text('Nenhum item no cardápio.',
                              style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Inter')))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: _filtrado.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final item = _filtrado[i] as Map<String, dynamic>;
                            final disponivel = item['disponivel'] as bool;
                            final preco = (item['preco_venda'] as num).toDouble();
                            final custo = (item['custo_producao'] as num? ?? 0).toDouble();
                            final margem = preco > 0
                                ? ((preco - custo) / preco * 100).toStringAsFixed(1)
                                : '0.0';

                            return GestureDetector(
                              onTap: () => _abrirModal(item),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: disponivel
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFEF4444).withOpacity(0.3)),
                                ),
                                child: Row(children: [
                                  // Ícone categoria
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF1E293B),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(LucideIcons.utensils,
                                        size: 18, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 14),

                                  // Info
                                  Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item['nome'] ?? '',
                                            style: const TextStyle(fontFamily: 'Inter',
                                                color: Color(0xFFF8FAFC),
                                                fontWeight: FontWeight.w600, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text('${item['categoria'] ?? 'Geral'} · Margem: $margem%',
                                            style: const TextStyle(fontFamily: 'Inter',
                                                color: Color(0xFF64748B), fontSize: 12)),
                                      ])),

                                  // Preço e toggle
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                    Text('R\$ ${preco.toStringAsFixed(2)}',
                                        style: const TextStyle(fontFamily: 'Inter',
                                            color: Color(0xFF34D399),
                                            fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () => _abrirFichaTecnica(item),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFF2563EB).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20)),
                                        child: const Text('Ficha Técnica',
                                            style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    GestureDetector(
                                      onTap: () => _toggleDisponivel(item['id'] as String, disponivel),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                            color: disponivel
                                                ? const Color(0xFF34D399).withOpacity(0.12)
                                                : const Color(0xFFEF4444).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(20)),
                                        child: Text(disponivel ? 'Ativo' : 'Inativo',
                                            style: TextStyle(fontFamily: 'Inter', fontSize: 11,
                                                color: disponivel
                                                    ? const Color(0xFF34D399)
                                                    : const Color(0xFFEF4444),
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () async {
                                      final confirmar = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: const Color(0xFF1E293B),
                                          title: const Text('Excluir Prato', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                                          content: const Text('Tem certeza que deseja excluir este prato? Esta ação não pode ser desfeita e removerá a ficha técnica associada.', style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter')),
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
                                          await _supabase.from('ficha_tecnica').delete().eq('cardapio_id', item['id']);
                                          await _supabase.from('cardapio').delete().eq('id', item['id']);
                                          _load();
                                        } catch (e) {
                                          String msg = 'Erro ao excluir prato: $e';
                                          if (e.toString().contains('foreign key') || e.toString().contains('violates foreign key')) {
                                            msg = 'Não é possível excluir este prato pois ele está associado a pedidos ativos.';
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

class _FichaTecnicaModal extends StatefulWidget {
  final SupabaseClient supabase;
  final Map<String, dynamic> item;
  const _FichaTecnicaModal({required this.supabase, required this.item});

  @override
  State<_FichaTecnicaModal> createState() => _FichaTecnicaModalState();
}

class _FichaTecnicaModalState extends State<_FichaTecnicaModal> {
  bool _isLoading = true;
  List<dynamic> _insumos = [];
  List<dynamic> _estoqueDisponivel = [];
  String? _selectedEstoqueId;
  final _qtdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final fichaData = await widget.supabase
          .from('ficha_tecnica')
          .select('id, estoque_id, quantidade_necessaria, estoque(nome_item, unidade_medida)')
          .eq('cardapio_id', widget.item['id']);
      
      final estoqueData = await widget.supabase
          .from('estoque')
          .select('id, nome_item, unidade_medida')
          .order('nome_item');

      if (mounted) {
        setState(() {
          _insumos = fichaData as List<dynamic>;
          _estoqueDisponivel = estoqueData as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _adicionarInsumo() async {
    if (_selectedEstoqueId == null || _qtdController.text.isEmpty) return;
    
    final qtd = double.tryParse(_qtdController.text.replaceAll(',', '.'));
    if (qtd == null || qtd <= 0) return;

    try {
      await widget.supabase.from('ficha_tecnica').insert({
        'cardapio_id': widget.item['id'],
        'estoque_id': _selectedEstoqueId,
        'quantidade_necessaria': qtd,
      });
      _qtdController.clear();
      setState(() => _selectedEstoqueId = null);
      await _loadData();
    } catch (_) {}
  }

  Future<void> _removerInsumo(String id) async {
    try {
      await widget.supabase.from('ficha_tecnica').delete().eq('id', id);
      await _loadData();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24, right: 24, top: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ficha Técnica: ${widget.item['nome']}',
            style: const TextStyle(fontFamily: 'Inter', color: Color(0xFFF8FAFC),
                fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),
        
        // Adicionar novo insumo
        Row(children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedEstoqueId,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'Inter'),
              decoration: InputDecoration(
                labelText: 'Insumo',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter'),
                filled: true, fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _estoqueDisponivel.map((e) => DropdownMenuItem<String>(
                value: e['id'] as String,
                child: Text('${e['nome_item']} (${e['unidade_medida']})', 
                  style: const TextStyle(fontSize: 13)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedEstoqueId = v),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextField(
              controller: _qtdController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'Inter'),
              decoration: InputDecoration(
                labelText: 'Qtd.',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter'),
                filled: true, fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _adicionarInsumo,
            icon: const Icon(LucideIcons.plusCircle, color: Color(0xFF34D399)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF34D399).withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        
        // Lista de Insumos
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _insumos.isEmpty
              ? const Center(child: Text('Nenhum insumo vinculado.', 
                  style: TextStyle(color: Color(0xFF64748B))))
              : ListView.builder(
                  itemCount: _insumos.length,
                  itemBuilder: (_, i) {
                    final insumo = _insumos[i];
                    final estoque = insumo['estoque'];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(estoque['nome_item'], 
                        style: const TextStyle(color: Color(0xFFF8FAFC))),
                      subtitle: Text('${insumo['quantidade_necessaria']} ${estoque['unidade_medida']}',
                        style: const TextStyle(color: Color(0xFF94A3B8))),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 18),
                        onPressed: () => _removerInsumo(insumo['id']),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}

class _CardapioFormModal extends StatefulWidget {
  final SupabaseClient supabase;
  final Map<String, dynamic>? item;
  final VoidCallback onSaved;
  const _CardapioFormModal({required this.supabase, this.item, required this.onSaved});

  @override
  State<_CardapioFormModal> createState() => _CardapioFormModalState();
}

class _CardapioFormModalState extends State<_CardapioFormModal> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _categoriaCtrl;
  late final TextEditingController _precoCtrl;
  late final TextEditingController _custoCtrl;
  bool _isSaving = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.item?['nome'] ?? '');
    _categoriaCtrl = TextEditingController(text: widget.item?['categoria'] ?? '');
    _precoCtrl = TextEditingController(
        text: widget.item != null
            ? (widget.item!['preco_venda'] as num).toStringAsFixed(2)
            : '');
    _custoCtrl = TextEditingController(
        text: widget.item != null
            ? (widget.item!['custo_producao'] as num? ?? 0).toStringAsFixed(2)
            : '');
  }

  Future<void> _salvar() async {
    final preco = double.tryParse(_precoCtrl.text.replaceAll(',', '.'));
    if (_nomeCtrl.text.isEmpty || preco == null) return;

    setState(() => _isSaving = true);
    final custo = double.tryParse(_custoCtrl.text.replaceAll(',', '.')) ?? 0;
    final payload = {
      'nome': _nomeCtrl.text.trim(),
      'categoria': _categoriaCtrl.text.trim().isEmpty ? 'Geral' : _categoriaCtrl.text.trim(),
      'preco_venda': preco,
      'custo_producao': custo,
    };

    try {
      if (_isEdit) {
        await widget.supabase.from('cardapio').update(payload).eq('id', widget.item!['id']);
      } else {
        await widget.supabase.from('cardapio').insert(payload);
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
        title: const Text('Excluir Prato', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
        content: const Text('Tem certeza que deseja excluir este prato? Esta ação não pode ser desfeita e removerá a ficha técnica associada.', style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter')),
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
      // Deletar da ficha técnica primeiro
      await widget.supabase.from('ficha_tecnica').delete().eq('cardapio_id', widget.item!['id']);
      
      // Deletar do cardapio
      await widget.supabase.from('cardapio').delete().eq('id', widget.item!['id']);
      
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir prato: $e')),
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
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_isEdit ? 'Editar Prato' : 'Novo Prato',
            style: const TextStyle(fontFamily: 'Inter', color: Color(0xFFF8FAFC),
                fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 20),
        _Field(controller: _nomeCtrl, label: 'Nome do Prato', hint: 'Ex: Marmita Executiva'),
        const SizedBox(height: 12),
        _Field(controller: _categoriaCtrl, label: 'Categoria', hint: 'Ex: Marmitas'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Field(controller: _precoCtrl, label: 'Preço Venda (R\$)',
              hint: '0.00', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          const SizedBox(width: 12),
          Expanded(child: _Field(controller: _custoCtrl, label: 'Custo Produção (R\$)',
              hint: '0.00', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
        ]),
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
                      : Text(_isEdit ? 'Salvar Alterações' : 'Criar Prato',
                          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  const _Field({required this.controller, required this.label,
      required this.hint, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'Inter'),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF475569)),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter'),
        filled: true, fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF334155))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF334155))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2563EB))),
      ),
    );
  }
}
