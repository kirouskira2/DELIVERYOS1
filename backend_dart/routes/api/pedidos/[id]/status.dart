import 'package:backend_dart/di/setup.dart';
import 'package:backend_dart/services/order_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// Rota: PATCH /api/pedidos/[id]/status
/// Atualiza o status de um pedido e, se for concluído, realiza a baixa de estoque.
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.patch) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'error': 'Method Not Allowed'},
    );
  }

  try {
    final rawBody = await context.request.json();
    if (rawBody is! Map<String, dynamic>) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'error': 'Payload inválido.'},
      );
    }

    final novoStatus = rawBody['status'] as String?;
    if (novoStatus == null || novoStatus.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'error': 'O campo "status" é obrigatório.'},
      );
    }

    final orderService = getIt<OrderService>();
    final result = await orderService.updateOrderStatus(
      pedidoId: id,
      novoStatus: novoStatus.trim(),
    );

    return Response.json(
      statusCode: result.statusCode,
      body: result.success
          ? {'success': true, 'message': 'Status atualizado com sucesso.'}
          : {'success': false, 'error': result.error},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'error': 'Erro ao atualizar status do pedido',
        'details': e.toString(),
      },
    );
  }
}
