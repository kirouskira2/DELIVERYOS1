import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _clientes = [];
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
      final data = await _supabase.from('clientes').select('*').order('nome_empresa');
      if (mounted) {
        setState(() {
          _clientes = data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _clientes = [];
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filtrado => _clientes
      .where((c) => (c['nome_empresa'] as String).toLowerCase().contains(_search.toLowerCase()))
      .toList();

  void _abrirModal([Map<String, dynamic>? cliente]) {
    showGeneralDialog(
      context: context,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => _ClienteFormModal(
        cliente: cliente,
        onSaved: _load,
      ),
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOut)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Clientes B2B', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ElevatedButton.icon(
                  onPressed: () => _abrirModal(),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: const Text('Adicionar Cliente'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingTextStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        dataTextStyle: const TextStyle(color: Colors.white),
                        columns: const [
                          DataColumn(label: Text('Empresa')),
                          DataColumn(label: Text('CNPJ')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Ações')),
                        ],
                        rows: _filtrado.map((c) => DataRow(cells: [
                          DataCell(Text(c['nome_empresa'] ?? '')),
                          DataCell(Text(c['cnpj'] ?? '')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: c['contrato_ativo'] == true ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFEF4444).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                c['contrato_ativo'] == true ? 'Ativo' : 'Inativo',
                                style: TextStyle(color: c['contrato_ativo'] == true ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 12),
                              ),
                            )
                          ),
                          DataCell(Row(
                            children: [
                              IconButton(icon: const Icon(LucideIcons.edit2, color: Colors.blueAccent, size: 18), onPressed: () => _abrirModal(c)),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xFF1E293B),
                                      title: const Text('Confirmar Exclusão', style: TextStyle(color: Colors.white)),
                                      content: const Text('Deseja realmente excluir este cliente?', style: TextStyle(color: Colors.grey)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true), 
                                          child: const Text('Excluir', style: TextStyle(color: Colors.redAccent))
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await _supabase.from('clientes').delete().eq('id', c['id']);
                                      _load();
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.redAccent)
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          )),
                        ])).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClienteFormModal extends StatefulWidget {
  final Map<String, dynamic>? cliente;
  final VoidCallback onSaved;

  const _ClienteFormModal({this.cliente, required this.onSaved});

  @override
  State<_ClienteFormModal> createState() => _ClienteFormModalState();
}

class _ClienteFormModalState extends State<_ClienteFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  String _nome = '';
  String _cnpj = '';
  bool _isLoading = false;
  bool _contratoAtivo = true;

  @override
  void initState() {
    super.initState();
    if (widget.cliente != null) {
      _nome = widget.cliente!['nome_empresa'] ?? '';
      _cnpj = widget.cliente!['cnpj'] ?? '';
      _contratoAtivo = widget.cliente!['contrato_ativo'] ?? true;
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      final data = {'nome_empresa': _nome, 'cnpj': _cnpj, 'contrato_ativo': _contratoAtivo};
      if (widget.cliente == null) {
        await _supabase.from('clientes').insert(data);
      } else {
        await _supabase.from('clientes').update(data).eq('id', widget.cliente!['id']);
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: const Color(0xFF1E293B),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.cliente == null ? 'Novo Cliente' : 'Editar Cliente', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  initialValue: _nome,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Empresa', labelStyle: TextStyle(color: Colors.grey)),
                  validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                  onSaved: (v) => _nome = v!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _cnpj,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'CNPJ', labelStyle: TextStyle(color: Colors.grey)),
                  onSaved: (v) => _cnpj = v ?? '',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Contrato Ativo', style: TextStyle(color: Colors.white, fontFamily: 'Inter', fontSize: 14)),
                  subtitle: const Text('Clientes inativos não podem realizar novos pedidos.', style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'Inter')),
                  value: _contratoAtivo,
                  activeColor: const Color(0xFF10B981),
                  onChanged: (val) => setState(() => _contratoAtivo = val),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _salvar,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Salvar Cliente', style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
