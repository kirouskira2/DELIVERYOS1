import 'package:supabase/supabase.dart';

/// Repository responsável por operações de dados de pedidos.
/// Regra: sem lógica de negócio — apenas acesso ao banco de dados.
class OrderRepository {
  OrderRepository(this._supabase);
  final SupabaseClient _supabase;

  /// Insere um novo pedido e seus itens no banco de dados.
  /// Retorna os dados do pedido criado.
  Future<Map<String, dynamic>> insertOrder({
    required String tipo,
    required List<Map<String, dynamic>> itens,
    String? clienteId,
    String? observacoes,
  }) async {
    final pedido = await _supabase
        .from('pedidos')
        .insert({
          'cliente_id': clienteId,
          'tipo': tipo,
          'status': 'novo',
          'observacoes': observacoes,
        })
        .select()
        .single();

    final pedidoId = pedido['id'] as String;
    final itensMapped = itens
        .map(
          (item) => {
            'pedido_id': pedidoId,
            'cardapio_id': item['cardapio_id'],
            'quantidade': item['quantidade'],
            'preco_unitario': item['preco_unitario'],
          },
        )
        .toList();

    await _supabase.from('pedido_itens').insert(itensMapped);
    return pedido;
  }

  /// Atualiza o status de um pedido existente.
  Future<void> updateStatus({
    required String pedidoId,
    required String novoStatus,
  }) async {
    await _supabase
        .from('pedidos')
        .update({'status': novoStatus})
        .eq('id', pedidoId);
  }

  /// Atualiza o valor total calculado do pedido.
  Future<void> updateValorTotal(String pedidoId, double valorTotal) async {
    await _supabase
        .from('pedidos')
        .update({'valor_total': valorTotal})
        .eq('id', pedidoId);
  }

  /// Dispara a RPC de baixa de estoque transacional no banco.
  /// Lança [Exception] em caso de falha — não engole o erro com print().
  /// O chamador (OrderService) é responsável pelo tratamento.
  Future<void> processarBaixaEstoquePedido(String pedidoId) async {
    final result = await _supabase.rpc(
      'processar_baixa_estoque_pedido',
      params: {'p_pedido_id': pedidoId},
    );

    // A RPC retorna FALSE ou lança exceção em caso de falha
    if (result == false) {
      throw Exception(
        'A RPC processar_baixa_estoque_pedido retornou false para pedido $pedidoId',
      );
    }
  }
}
