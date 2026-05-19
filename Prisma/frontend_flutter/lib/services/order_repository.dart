import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> payload) async {
    final tipo = payload['tipo'] as String;
    final clienteId = payload['cliente_id'] as String?;
    final observacoes = payload['observacoes'] as String?;
    final itens = payload['itens'] as List<dynamic>;

    // 1. Calcular o valor total
    final valorTotal = itens.fold<double>(
      0.0,
      (sum, item) => sum + (item['preco_unitario'] as num).toDouble() * (item['quantidade'] as num).toDouble(),
    );

    // 2. Inserir o pedido com status 'concluido'
    final pedido = await _supabase
        .from('pedidos')
        .insert({
          'cliente_id': clienteId,
          'tipo': tipo,
          'status': 'concluido',
          'observacoes': observacoes,
          'valor_total': valorTotal,
        })
        .select()
        .single();

    final pedidoId = pedido['id'] as String;

    // 3. Mapear e inserir itens do pedido
    final itensMapped = itens.map((item) => {
      'pedido_id': pedidoId,
      'cardapio_id': item['cardapio_id'],
      'quantidade': item['quantidade'],
      'preco_unitario': item['preco_unitario'],
    }).toList();

    await _supabase.from('pedido_itens').insert(itensMapped);

    // 4. Executar RPC de baixa de estoque
    try {
      await _supabase.rpc(
        'processar_baixa_estoque_pedido',
        params: {'p_pedido_id': pedidoId},
      );
    } catch (e) {
      print('Erro ao processar baixa de estoque: $e');
    }

    // 5. Gerar lançamento de RECEITA correspondente no Financeiro
    try {
      await _supabase.from('financeiro').insert({
        'tipo': 'RECEITA',
        'descricao': 'Venda PDV - Pedido #${pedidoId.substring(0, 8)}',
        'valor': valorTotal,
        'categoria': 'Vendas',
        'status': 'pago',
        'pedido_id': pedidoId,
        'data_transacao': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Erro ao criar lancamento financeiro: $e');
    }

    return {...pedido, 'valor_total': valorTotal};
  }

  Future<List<dynamic>> getActiveOrders() async {
    try {
      final res = await _supabase
          .from('pedidos')
          .select('*, clientes(nome_empresa), pedido_itens(*, cardapio(*))')
          .order('created_at', ascending: false);
      return res as List<dynamic>;
    } catch (e) {
      print('Erro ao obter pedidos ativos: $e');
      return [];
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _supabase
        .from('pedidos')
        .update({'status': status})
        .eq('id', orderId);
  }

  Future<void> deleteOrder(String orderId) async {
    // 1. Delete associated finance entry
    try {
      await _supabase.from('financeiro').delete().eq('pedido_id', orderId);
    } catch (_) {}
    
    // 2. Delete order items
    await _supabase.from('pedido_itens').delete().eq('pedido_id', orderId);
    
    // 3. Delete order
    await _supabase.from('pedidos').delete().eq('id', orderId);
  }
}
