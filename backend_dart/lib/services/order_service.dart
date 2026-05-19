import 'package:backend_dart/repositories/order_repository.dart';
import 'package:backend_dart/services/auth_service.dart';
import 'package:supabase/supabase.dart';

/// Service de Pedidos (Factory 2 — Lógica de Negócio)
/// Orquestra criação, atualização de status e baixa de estoque.
/// Depende do OrderRepository para acesso a dados — segue o padrão Repository.
class OrderService {
  OrderService(SupabaseClient supabase, {OrderRepository? orderRepository})
    : _orderRepository = orderRepository ?? OrderRepository(supabase);
  final OrderRepository _orderRepository;

  /// Cria um novo pedido com seus itens.
  /// Valida a lista de itens antes de persistir.
  Future<ActionResponse<Map<String, dynamic>>> createOrder({
    required String tipo,
    required List<Map<String, dynamic>> itens,
    String? clienteId,
    String? observacoes,
  }) async {
    if (itens.isEmpty) {
      return const ActionResponse(
        success: false,
        error: 'O pedido deve conter ao menos um item.',
        statusCode: 400,
      );
    }

    try {
      // Calcular valor total antes de persistir
      final valorTotal = itens.fold<double>(
        0,
        (sum, item) =>
            sum +
            (item['preco_unitario'] as num).toDouble() *
                (item['quantidade'] as num).toInt(),
      );

      final pedido = await _orderRepository.insertOrder(
        tipo: tipo,
        itens: itens,
        clienteId: clienteId,
        observacoes: observacoes,
      );

      // Atualiza valor total calculado no pedido criado através do repository
      await _orderRepository.updateValorTotal(
        pedido['id'] as String,
        valorTotal,
      );

      return ActionResponse(
        success: true,
        data: {...pedido, 'valor_total': valorTotal},
        statusCode: 201,
      );
    } catch (e) {
      return ActionResponse(
        success: false,
        error: 'Erro ao criar pedido: $e',
        statusCode: 500,
      );
    }
  }

  /// Atualiza o status do pedido.
  /// Regra de negócio core: ao status 'concluido', dispara RPC de baixa de estoque.
  Future<ActionResponse<void>> updateOrderStatus({
    required String pedidoId,
    required String novoStatus,
  }) async {
    if (pedidoId.isEmpty) {
      return const ActionResponse(
        success: false,
        error: 'O campo pedidoId é obrigatório.',
        statusCode: 400,
      );
    }

    try {
      await _orderRepository.updateStatus(
        pedidoId: pedidoId,
        novoStatus: novoStatus,
      );

      // Core business logic: baixa automática no estoque ao concluir pedido
      if (novoStatus == 'concluido') {
        await _orderRepository.processarBaixaEstoquePedido(pedidoId);
      }

      return const ActionResponse(success: true, statusCode: 200);
    } catch (e) {
      return ActionResponse(
        success: false,
        error: 'Erro ao atualizar status: $e',
        statusCode: 500,
      );
    }
  }
}
