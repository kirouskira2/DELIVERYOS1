import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FornecedoresScreen extends StatefulWidget {
  const FornecedoresScreen({super.key});

  @override
  State<FornecedoresScreen> createState() => _FornecedoresScreenState();
}

class _FornecedoresScreenState extends State<FornecedoresScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _fornecedores = [];
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
          .from('fornecedores')
          .select('id, nome, categoria, contato, telefone, dias_entrega')
          .order('nome');
      if (mounted) {
        setState(() {
          _fornecedores = data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> get _filtrado => _fornecedores
      .where((f) => (f['nome'] as String)
          .toLowerCase()
          .contains(_search.toLowerCase()))
      .toList();

  void _abrirModal([Map<String, dynamic>? fornecedor]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _FornecedorFormModal(
        supabase: _supabase,
        fornecedor: fornecedor,
        onSaved: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Row(children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'Inter'),
                decoration: InputDecoration(
                  hintText: 'Buscar fornecedor...',
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
                  Icon(LucideIcons.truck, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Novo Fornecedor',
                      style: TextStyle(fontFamily: 'Inter', color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
            ),
          ]),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF2563EB),
                  child: _filtrado.isEmpty
                      ? const Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(LucideIcons.truck, color: Color(0xFF334155), size: 48),
                            SizedBox(height: 12),
                            Text('Nenhum fornecedor cadastrado.',
                                style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Inter')),
                          ]))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: _filtrado.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final f = _filtrado[i] as Map<String, dynamic>;
                            return GestureDetector(
                              onTap: () => _abrirModal(f),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF1E293B)),
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      (f['nome'] as String? ?? 'F')[0].toUpperCase(),
                                      style: const TextStyle(
                                          fontFamily: 'Inter', color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(f['nome'] ?? '',
                                            style: const TextStyle(fontFamily: 'Inter',
                                                color: Color(0xFFF8FAFC),
                                                fontWeight: FontWeight.w600, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text(
                                            [
                                              if (f['contato'] != null && (f['contato'] as String).isNotEmpty) f['contato'] as String,
                                              if (f['telefone'] != null && (f['telefone'] as String).isNotEmpty) f['telefone'] as String,
                                              if (f['dias_entrega'] != null && (f['dias_entrega'] as String).isNotEmpty) 'Entregas: ${f['dias_entrega']}',
                                            ].join(' · '),
                                            style: const TextStyle(fontFamily: 'Inter',
                                                color: Color(0xFF64748B), fontSize: 12)),
                                      ])),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 18),
                                    onPressed: () async {
                                      final confirmar = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: const Color(0xFF1E293B),
                                          title: const Text('Excluir Fornecedor', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                                          content: const Text('Tem certeza que deseja excluir este fornecedor? Esta ação não pode ser desfeita.', style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter')),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Inter')),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                              child: const Text('Excluir', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmar == true) {
                                        try {
                                          await _supabase.from('fornecedores').delete().eq('id', f['id']);
                                          _load();
                                        } catch (e) {
                                          String msg = 'Erro ao excluir fornecedor: $e';
                                          if (e.toString().contains('foreign key') || e.toString().contains('violates foreign key')) {
                                            msg = 'Não é possível excluir este fornecedor pois ele possui insumos vinculados no estoque.';
                                          }
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
                                            );
                                          }
                                        }
                                      }
                                    },
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

class _FornecedorFormModal extends StatefulWidget {
  final SupabaseClient supabase;
  final Map<String, dynamic>? fornecedor;
  final VoidCallback onSaved;
  const _FornecedorFormModal({required this.supabase, this.fornecedor, required this.onSaved});

  @override
  State<_FornecedorFormModal> createState() => _FornecedorFormModalState();
}

class _FornecedorFormModalState extends State<_FornecedorFormModal> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _categoriaCtrl;
  late final TextEditingController _contatoCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _diasCtrl;
  bool _isSaving = false;
  bool get _isEdit => widget.fornecedor != null;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.fornecedor?['nome'] ?? '');
    _categoriaCtrl = TextEditingController(text: widget.fornecedor?['categoria'] ?? '');
    _contatoCtrl = TextEditingController(text: widget.fornecedor?['contato'] ?? '');
    _telCtrl = TextEditingController(text: widget.fornecedor?['telefone'] ?? '');
    _diasCtrl = TextEditingController(text: widget.fornecedor?['dias_entrega'] ?? '');
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);

    final payload = {
      'nome': _nomeCtrl.text.trim(),
      'categoria': _categoriaCtrl.text.trim(),
      'contato': _contatoCtrl.text.trim(),
      'telefone': _telCtrl.text.trim(),
      'dias_entrega': _diasCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await widget.supabase.from('fornecedores').update(payload).eq('id', widget.fornecedor!['id']);
      } else {
        await widget.supabase.from('fornecedores').insert(payload);
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
                title: const Text('Excluir Fornecedor', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                content: const Text('Tem certeza que deseja excluir este fornecedor? Esta ação não pode ser desfeita.', style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Inter')),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                    child: const Text('Excluir', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            );

            if (confirmar != true) return;

            setState(() => _isSaving = true);
            try {
              await widget.supabase.from('fornecedores').delete().eq('id', widget.fornecedor!['id']);
              widget.onSaved();
              if (mounted) Navigator.pop(context);
            } catch (e) {
              String msg = 'Erro ao excluir fornecedor: $e';
              if (e.toString().contains('foreign key') || e.toString().contains('violates foreign key')) {
                msg = 'Não é possível excluir este fornecedor pois ele possui insumos vinculados no estoque.';
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
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
                  Text(_isEdit ? 'Editar Fornecedor' : 'Novo Fornecedor',
                      style: const TextStyle(fontFamily: 'Inter', color: Color(0xFFF8FAFC),
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  _FormField(controller: _nomeCtrl, label: 'Nome / Razão Social', hint: 'Ex: Distribuidora ABC'),
                  const SizedBox(height: 12),
                  _FormField(controller: _categoriaCtrl, label: 'Categoria', hint: 'Ex: Hortifruti'),
                  const SizedBox(height: 12),
                  _FormField(controller: _contatoCtrl, label: 'Nome do Contato', hint: 'Ex: João'),
                  const SizedBox(height: 12),
                  _FormField(controller: _telCtrl, label: 'Telefone', hint: '(00) 00000-0000',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _FormField(controller: _diasCtrl, label: 'Dias de Entrega', hint: 'Ex: Segundas e Quintas'),
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
                                : Text(_isEdit ? 'Salvar Alterações' : 'Cadastrar Fornecedor',
                                    style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Colors.white)),
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

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  const _FormField({required this.controller, required this.label,
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
