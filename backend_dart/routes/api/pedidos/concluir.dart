import 'package:backend_dart/di/setup.dart';
import 'package:backend_dart/services/order_service.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
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

    final pedidoId = rawBody['pedido_id'] as String?;
    if (pedidoId == null || pedidoId.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'error': 'O campo pedido_id é obrigatório.'},
      );
    }

    final orderService = getIt<OrderService>();
    final result = await orderService.updateOrderStatus(
      pedidoId: pedidoId,
      novoStatus: 'concluido',
    );

    return Response.json(
      statusCode: result.statusCode,
      body: result.success
          ? {
              'success': true,
              'message': 'Baixa de estoque processada com sucesso.',
            }
          : {'success': false, 'error': result.error},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'error': 'Erro interno do servidor',
        'details': e.toString(),
      },
    );
  }
}
