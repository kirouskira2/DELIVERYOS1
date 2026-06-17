import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/responsive.dart';

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
        builder: (_) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _ClienteFormContent(
            cliente: cliente,
            onSaved: _load,
          ),
        ),
      );
    } else {
      // Desktop: Slide lateral
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
  }

  Future<void> _excluir(Map<String, dynamic> c) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Exclusão', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
        content: const Text('Deseja realmente excluir este cliente?', style: TextStyle(color: Colors.grey, fontFamily: 'Inter')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Excluir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF3B82F6),
              onPressed: () => _abrirModal(),
              child: const Icon(LucideIcons.plus, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Clientes B2B', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
                      const SizedBox(height: 12),
                      _buildSearchField(),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Clientes B2B', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
                      ElevatedButton.icon(
                        onPressed: () => _abrirModal(),
                        icon: const Icon(LucideIcons.plus, size: 18),
                        label: const Text('Adicionar Cliente'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                      ),
                    ],
                  ),
          ),
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildSearchField(),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
                : isMobile
                    ? _buildMobileList()
                    : _buildDesktopTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (v) => setState(() => _search = v),
      style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
      decoration: InputDecoration(
        hintText: 'Buscar cliente...',
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(LucideIcons.search, color: Colors.grey, size: 20),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  // ─── MOBILE: Lista de cards ──────────────────────────────────────────────

  Widget _buildMobileList() {
    if (_filtrado.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.users, color: Color(0xFF334155), size: 48),
            SizedBox(height: 12),
            Text('Nenhum cliente encontrado.', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Inter')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF3B82F6),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        itemCount: _filtrado.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final c = _filtrado[i] as Map<String, dynamic>;
          final isAtivo = c['contrato_ativo'] == true;
          return GestureDetector(
            onTap: () => _abrirModal(c),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      ((c['nome_empresa'] as String?)?.isNotEmpty == true) ? (c['nome_empresa'] as String)[0].toUpperCase() : 'C',
                      style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['nome_empresa'] ?? '', style: const TextStyle(fontFamily: 'Inter', color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(c['cnpj'] ?? 'Sem CNPJ', style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF94A3B8), fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAtivo ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFFEF4444).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAtivo ? 'Ativo' : 'Inativo',
                          style: TextStyle(color: isAtivo ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _excluir(c),
                        child: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── DESKTOP: DataTable ──────────────────────────────────────────────────

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingTextStyle: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
          dataTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
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
              ),
            ),
            DataCell(Row(
              children: [
                IconButton(icon: const Icon(LucideIcons.edit2, color: Colors.blueAccent, size: 18), onPressed: () => _abrirModal(c)),
                IconButton(icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18), onPressed: () => _excluir(c)),
              ],
            )),
          ])).toList(),
        ),
      ),
    );
  }
}

// ─── FORM: Conteúdo compartilhado ────────────────────────────────────────────

class _ClienteFormContent extends StatefulWidget {
  final Map<String, dynamic>? cliente;
  final VoidCallback onSaved;

  const _ClienteFormContent({this.cliente, required this.onSaved});

  @override
  State<_ClienteFormContent> createState() => _ClienteFormContentState();
}

class _ClienteFormContentState extends State<_ClienteFormContent> {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF475569), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(widget.cliente == null ? 'Novo Cliente' : 'Editar Cliente', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: _nome,
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              decoration: _inputDecoration('Empresa'),
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              onSaved: (v) => _nome = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _cnpj,
              style: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
              decoration: _inputDecoration('CNPJ'),
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _salvar,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Salvar Cliente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
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

// ─── FORM: Modal Desktop (slide lateral) ─────────────────────────────────────

class _ClienteFormModal extends StatelessWidget {
  final Map<String, dynamic>? cliente;
  final VoidCallback onSaved;

  const _ClienteFormModal({this.cliente, required this.onSaved});

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(cliente == null ? 'Novo Cliente' : 'Editar Cliente', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Expanded(
                child: _ClienteFormContent(
                  cliente: cliente,
                  onSaved: onSaved,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
