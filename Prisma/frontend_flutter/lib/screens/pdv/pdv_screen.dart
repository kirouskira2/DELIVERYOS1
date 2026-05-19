import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/order_repository.dart';

class PdvScreen extends StatefulWidget {
  const PdvScreen({super.key});

  @override
  State<PdvScreen> createState() => _PdvScreenState();
}

class _PdvScreenState extends State<PdvScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  final _supabase = Supabase.instance.client;

  List<dynamic> _cardapio = [];
  List<dynamic> _clientes = [];
  String _searchQuery = '';
  String _selectedCategory = 'Todos';
  
  final Map<String, Map<String, dynamic>> _carrinho = {};
  bool _isLoading = true;
  bool _isFaturando = false;
  String _tipoPedido = 'balcao';
  String? _clienteSelecionado;

  // Gerenciamento de Pedidos Ativos
  String _activeTab = 'nova_venda';
  List<dynamic> _activeOrders = [];
  bool _isLoadingOrders = false;
  Map<String, dynamic>? _selectedOrderDetails;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final cardapioData = await _supabase.from('cardapio').select('*').order('nome');
      final clientesData = await _supabase.from('clientes').select('*').order('nome_empresa');

      if (mounted) {
        setState(() {
          _cardapio = cardapioData as List<dynamic>;
          _clientes = clientesData as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cardapio = [];
          _clientes = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadActiveOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final orders = await _orderRepository.getActiveOrders();
      if (mounted) {
        setState(() {
          _activeOrders = orders;
          // Atualiza os detalhes do pedido selecionado caso ainda exista na lista
          if (_selectedOrderDetails != null) {
            final idx = orders.indexWhere((o) => o['id'] == _selectedOrderDetails!['id']);
            if (idx != -1) {
              _selectedOrderDetails = orders[idx];
            } else {
              _selectedOrderDetails = null;
            }
          }
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeOrders = [];
          _isLoadingOrders = false;
        });
      }
    }
  }

  List<dynamic> get _filteredCardapio {
    return _cardapio.where((item) {
      final matchesSearch = item['nome'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Todos' || item['categoria'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<String> get _categories {
    final cats = _cardapio.map((e) => e['categoria'].toString()).toSet().toList();
    cats.insert(0, 'Todos');
    return cats;
  }

  void _addToCart(Map<String, dynamic> item) {
    final id = item['id'].toString();
    setState(() {
      if (_carrinho.containsKey(id)) {
        _carrinho[id]!['quantidade'] += 1;
      } else {
        _carrinho[id] = {'item': item, 'quantidade': 1};
      }
    });
  }

  void _removeFromCart(String id) {
    setState(() {
      if (_carrinho[id] != null && _carrinho[id]!['quantidade'] > 1) {
        _carrinho[id]!['quantidade'] -= 1;
      } else {
        _carrinho.remove(id);
      }
    });
  }

  double get _total => _carrinho.values.fold(0, (sum, e) {
        final preco = (e['item']['preco_venda'] as num).toDouble();
        final qtd = e['quantidade'] as int;
        return sum + preco * qtd;
      });

  Future<void> _faturarPedido() async {
    if (_carrinho.isEmpty) return;
    if (_tipoPedido == 'b2b' && _clienteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um cliente B2B')),
      );
      return;
    }
    
    setState(() => _isFaturando = true);

    try {
      final itens = _carrinho.values.map((e) => {
        'cardapio_id': e['item']['id'],
        'quantidade': e['quantidade'],
        'preco_unitario': e['item']['preco_venda'],
      }).toList();

      final payload = {
        'cliente_id': _clienteSelecionado,
        'tipo': _tipoPedido == 'b2b' ? 'delivery' : _tipoPedido,
        'observacoes': '',
        'itens': itens,
      };

      await _orderRepository.createOrder(payload);

      if (mounted) {
        setState(() {
          _carrinho.clear();
          _clienteSelecionado = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0F172A),
            content: const Row(children: [
              Icon(LucideIcons.checkCircle, color: Color(0xFF34D399), size: 18),
              SizedBox(width: 10),
              Text('Pedido faturado com sucesso!', style: TextStyle(color: Color(0xFFF8FAFC), fontFamily: 'Inter')),
            ]),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao faturar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isFaturando = false);
    }
  }

  Widget _buildActiveOrdersSection() {
    if (_isLoadingOrders) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }
    if (_activeOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clipboardList, size: 64, color: const Color(0xFF475569)),
            const SizedBox(height: 16),
            const Text('Nenhum pedido ativo encontrado', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16, fontFamily: 'Inter')),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _activeOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final order = _activeOrders[i];
        final orderId = order['id'].toString();
        final shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
        final valorTotal = (order['valor_total'] as num?)?.toDouble() ?? 0.0;
        final status = order['status'] ?? 'novo';
        final tipo = order['tipo'] ?? 'balcao';
        final clienteNome = order['clientes']?['nome_empresa'] ?? 'Venda Avulsa (Balcão)';
        final itemsList = order['pedido_itens'] as List<dynamic>? ?? [];
        final itemsQty = itemsList.fold<int>(0, (sum, item) => sum + (item['quantidade'] as int? ?? 0));
        
        final isSelected = _selectedOrderDetails?['id'] == order['id'];
        
        Color statusColor;
        Color statusBgColor;
        String statusLabel;
        
        switch (status) {
          case 'novo':
            statusColor = const Color(0xFFEAB308);
            statusBgColor = const Color(0xFFEAB308).withOpacity(0.15);
            statusLabel = 'Pendente';
            break;
          case 'preparando':
            statusColor = const Color(0xFF3B82F6);
            statusBgColor = const Color(0xFF3B82F6).withOpacity(0.15);
            statusLabel = 'Preparando';
            break;
          case 'pronto':
            statusColor = const Color(0xFF8B5CF6);
            statusBgColor = const Color(0xFF8B5CF6).withOpacity(0.15);
            statusLabel = 'Pronto';
            break;
          case 'concluido':
            statusColor = const Color(0xFF10B981);
            statusBgColor = const Color(0xFF10B981).withOpacity(0.15);
            statusLabel = 'Concluído';
            break;
          case 'cancelado':
            statusColor = const Color(0xFFEF4444);
            statusBgColor = const Color(0xFFEF4444).withOpacity(0.15);
            statusLabel = 'Cancelado';
            break;
          default:
            statusColor = Colors.grey;
            statusBgColor = Colors.grey.withOpacity(0.15);
            statusLabel = status.toString().toUpperCase();
        }

        return InkWell(
          onTap: () {
            setState(() {
              _selectedOrderDetails = order;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tipo == 'delivery' ? const Color(0xFF8B5CF6).withOpacity(0.15) : const Color(0xFF3B82F6).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    tipo == 'delivery' ? LucideIcons.truck : LucideIcons.shoppingBag,
                    color: tipo == 'delivery' ? const Color(0xFFA78BFA) : const Color(0xFF60A5FA),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pedido #$shortId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, fontFamily: 'Inter')),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12, fontFamily: 'Inter'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        clienteNome,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$itemsQty pratos · R\$ ${valorTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF34D399), fontSize: 14, fontFamily: 'Inter'),
                          ),
                          Text(
                            'Hoje às ${order['created_at'].toString().substring(11, 16)}',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Inter'),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderDetailsPanel() {
    if (_selectedOrderDetails == null) {
      return Container(
        color: const Color(0xFF1E293B),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.receipt, size: 64, color: const Color(0xFF475569)),
            const SizedBox(height: 16),
            const Text(
              'Nenhum pedido selecionado',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione um pedido na lista ao lado para ver detalhes, alterar status ou realizar a exclusão.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontFamily: 'Inter'),
            ),
          ],
        ),
      );
    }

    final order = _selectedOrderDetails!;
    final orderId = order['id'].toString();
    final shortId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;
    final status = order['status'] ?? 'novo';
    final tipo = order['tipo'] ?? 'balcao';
    final clienteNome = order['clientes']?['nome_empresa'] ?? 'Venda Avulsa (Balcão)';
    final valorTotal = (order['valor_total'] as num?)?.toDouble() ?? 0.0;
    final itemsList = order['pedido_itens'] as List<dynamic>? ?? [];

    String statusLabel = 'Pendente';
    Color statusColor = const Color(0xFFEAB308);
    String nextActionLabel = 'Iniciar Preparo';
    String nextStatus = 'preparando';
    IconData nextActionIcon = LucideIcons.play;

    if (status == 'preparando') {
      statusLabel = 'Em Preparo';
      statusColor = const Color(0xFF3B82F6);
      nextActionLabel = 'Marcar como Pronto';
      nextStatus = 'pronto';
      nextActionIcon = LucideIcons.check;
    } else if (status == 'pronto') {
      statusLabel = 'Pronto';
      statusColor = const Color(0xFF8B5CF6);
      nextActionLabel = 'Finalizar / Concluir';
      nextStatus = 'concluido';
      nextActionIcon = LucideIcons.checkSquare;
    } else if (status == 'concluido') {
      statusLabel = 'Concluído';
      statusColor = const Color(0xFF10B981);
      nextActionLabel = '';
    } else if (status == 'cancelado') {
      statusLabel = 'Cancelado';
      statusColor = const Color(0xFFEF4444);
      nextActionLabel = '';
    }

    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pedido #$shortId', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Inter'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(clienteNome, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Inter')),
          const SizedBox(height: 4),
          Text('Tipo: ${tipo.toString().toUpperCase()}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Inter')),
          const Divider(height: 32, color: Color(0xFF334155)),
          
          const Text('Itens do Pedido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, fontFamily: 'Inter')),
          const SizedBox(height: 12),
          
          Expanded(
            child: itemsList.isEmpty
                ? const Center(child: Text('Nenhum item neste pedido', style: TextStyle(color: Colors.grey, fontFamily: 'Inter')))
                : ListView.separated(
                    itemCount: itemsList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final item = itemsList[idx];
                      final prato = item['cardapio'] ?? {};
                      final nomePrato = prato['nome'] ?? 'Prato Desconhecido';
                      final qtd = item['quantidade'] ?? 0;
                      final precoUnit = (item['preco_unitario'] as num?)?.toDouble() ?? 0.0;
                      final subtotal = qtd * precoUnit;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${qtd}x $nomePrato',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Inter'),
                            ),
                          ),
                          Text(
                            'R\$ ${subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Inter'),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          
          const Divider(color: Color(0xFF334155)),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total do Pedido', style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Inter')),
                Text('R\$ ${valorTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF34D399), fontFamily: 'Inter')),
              ],
            ),
          ),
          
          if (nextActionLabel.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await _orderRepository.updateOrderStatus(orderId, nextStatus);
                    _loadActiveOrders();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Pedido atualizado para: $nextStatus'), backgroundColor: const Color(0xFF10B981)),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao atualizar: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                icon: Icon(nextActionIcon, size: 18, color: Colors.white),
                label: Text(nextActionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white, fontFamily: 'Inter')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: const Text('Excluir / Cancelar Pedido', style: TextStyle(color: Colors.white, fontFamily: 'Inter')),
                    content: const Text('Tem certeza que deseja excluir permanentemente este pedido? Isso removerá o faturamento e histórico.', style: TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Inter')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Voltar', style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Inter')),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                        child: const Text('Confirmar Exclusão', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
                      ),
                    ],
                  ),
                );

                if (confirmar == true) {
                  try {
                    await _orderRepository.deleteOrder(orderId);
                    setState(() {
                      _selectedOrderDetails = null;
                    });
                    _loadActiveOrders();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pedido excluído com sucesso!'), backgroundColor: Color(0xFF10B981)),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao excluir: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              icon: const Icon(LucideIcons.trash2, size: 16),
              label: const Text('EXCLUIR PEDIDO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter')),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          // ESQUERDA: Vitrine (70%)
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _activeTab = 'nova_venda'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _activeTab == 'nova_venda' ? const Color(0xFF2563EB) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.shoppingCart, size: 18, color: _activeTab == 'nova_venda' ? Colors.white : const Color(0xFF94A3B8)),
                                  const SizedBox(width: 8),
                                  Text('Nova Venda', style: TextStyle(fontWeight: FontWeight.bold, color: _activeTab == 'nova_venda' ? Colors.white : const Color(0xFF94A3B8), fontFamily: 'Inter')),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              setState(() => _activeTab = 'pedidos_ativos');
                              _loadActiveOrders();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: _activeTab == 'pedidos_ativos' ? const Color(0xFF2563EB) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.clipboardList, size: 18, color: _activeTab == 'pedidos_ativos' ? Colors.white : const Color(0xFF94A3B8)),
                                  const SizedBox(width: 8),
                                  Text('Pedidos Ativos', style: TextStyle(fontWeight: FontWeight.bold, color: _activeTab == 'pedidos_ativos' ? Colors.white : const Color(0xFF94A3B8), fontFamily: 'Inter')),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_activeTab == 'nova_venda')
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => setState(() { _tipoPedido = 'balcao'; _clienteSelecionado = null; }),
                              icon: const Icon(LucideIcons.store, size: 18),
                              label: const Text('Balcão'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _tipoPedido == 'balcao' ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _tipoPedido = 'b2b'),
                              icon: const Icon(LucideIcons.building, size: 18),
                              label: const Text('B2B'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _tipoPedido == 'b2b' ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  if (_activeTab == 'nova_venda') ...[
                    // Busca e Filtros
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar prato...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: _selectedCategory == cat,
                            onSelected: (val) => setState(() => _selectedCategory = cat),
                            backgroundColor: const Color(0xFF1E293B),
                            selectedColor: const Color(0xFF3B82F6),
                            labelStyle: TextStyle(color: _selectedCategory == cat ? Colors.white : Colors.grey),
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Grid de Produtos
                    Expanded(
                      child: _isLoading 
                          ? const Center(child: CircularProgressIndicator()) 
                          : _filteredCardapio.isEmpty
                              ? const Center(child: Text('Nenhum prato disponível no cardápio.', style: TextStyle(color: Colors.grey, fontFamily: 'Inter')))
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 1.2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: _filteredCardapio.length,
                                  itemBuilder: (context, index) {
                                    final item = _filteredCardapio[index];
                                    return InkWell(
                                      onTap: () => _addToCart(item),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFF334155)),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Icon(LucideIcons.utensils, color: Colors.blue[300], size: 32),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item['nome'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter')),
                                                const SizedBox(height: 4),
                                                Text('R\$ ${(item['preco_venda'] as num).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF34D399), fontSize: 14, fontFamily: 'Inter')),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                              ),
                    ),
                  ] else ...[
                    // Aba de Pedidos Ativos
                    Expanded(
                      child: _buildActiveOrdersSection(),
                    )
                  ]
                ],
              ),
            ),
          ),
          
          // DIREITA: Carrinho (30%) ou Detalhes do Pedido Ativo
          Expanded(
            flex: 3,
            child: _activeTab == 'nova_venda'
                ? Container(
                    color: const Color(0xFF1E293B),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Carrinho', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
                        const SizedBox(height: 16),
                        if (_tipoPedido == 'b2b') ...[
                          DropdownButtonFormField<String>(
                            value: _clienteSelecionado,
                            hint: const Text('Selecione o Cliente', style: TextStyle(color: Colors.grey)),
                            dropdownColor: const Color(0xFF1E293B),
                            items: _clientes.map((c) => DropdownMenuItem<String>(
                              value: c['id'].toString(),
                              child: Text(c['nome_empresa'] ?? '', style: const TextStyle(color: Colors.white, fontFamily: 'Inter')),
                            )).toList(),
                            onChanged: (val) => setState(() => _clienteSelecionado = val),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Expanded(
                          child: _carrinho.isEmpty 
                            ? const Center(child: Text('Carrinho vazio', style: TextStyle(color: Colors.grey, fontFamily: 'Inter')))
                            : ListView.builder(
                                itemCount: _carrinho.length,
                                itemBuilder: (context, index) {
                                  final key = _carrinho.keys.elementAt(index);
                                  final item = _carrinho[key]!;
                                  final preco = (item['item']['preco_venda'] as num).toDouble();
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(item['item']['nome'], style: const TextStyle(color: Colors.white, fontFamily: 'Inter')),
                                    subtitle: Text('R\$ ${preco.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontFamily: 'Inter')),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(LucideIcons.minusCircle, color: Colors.redAccent),
                                          onPressed: () => _removeFromCart(key),
                                        ),
                                        Text('${item['quantidade']}', style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Inter')),
                                        IconButton(
                                          icon: const Icon(LucideIcons.plusCircle, color: Colors.greenAccent),
                                          onPressed: () => _addToCart(item['item']),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                        ),
                        const Divider(color: Color(0xFF334155)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontSize: 20, color: Colors.white, fontFamily: 'Inter')),
                              Text('R\$ ${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF34D399), fontFamily: 'Inter')),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _carrinho.isEmpty || _isFaturando ? null : _faturarPedido,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isFaturando
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('FINALIZAR VENDA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Inter')),
                          ),
                        )
                      ],
                    ),
                  )
                : _buildOrderDetailsPanel(),
          )
        ],
      ),
    );
  }
}
