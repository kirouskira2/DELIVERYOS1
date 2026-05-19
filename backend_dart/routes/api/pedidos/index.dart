import 'package:backend_dart/di/setup.dart';
import 'package:backend_dart/services/order_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// Rota: POST /api/pedidos
/// Cria um novo pedido com seus respectivos itens e calcula o valor total.
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

    final clienteId = rawBody['cliente_id'] as String?;
    final tipo = rawBody['tipo'] as String? ?? 'balcao';
    final observacoes = rawBody['observacoes'] as String?;
    final rawItens = rawBody['itens'];

    if (rawItens is! List) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'error': 'O campo "itens" é obrigatório e deve ser uma lista.',
        },
      );
    }

    // Cast seguro dos itens
    final itens = <Map<String, dynamic>>[];
    for (final item in rawItens) {
      if (item is! Map<String, dynamic>) {
        return Response.json(
          statusCode: 400,
          body: {
            'success': false,
            'error': 'Cada item do pedido deve ser um objeto JSON válido.',
          },
        );
      }

      // Validações básicas de cada item
      if (item['cardapio_id'] == null ||
          item['quantidade'] == null ||
          item['preco_unitario'] == null) {
        return Response.json(
          statusCode: 400,
          body: {
            'success': false,
            'error':
                'Cada item deve conter "cardapio_id", "quantidade" e "preco_unitario".',
          },
        );
      }

      itens.add(item);
    }

    final orderService = getIt<OrderService>();
    final result = await orderService.createOrder(
      clienteId: clienteId,
      tipo: tipo,
      itens: itens,
      observacoes: observacoes,
    );

    return Response.json(
      statusCode: result.statusCode,
      body: result.success
          ? {'success': true, 'data': result.data}
          : {'success': false, 'error': result.error},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'error': 'Erro ao processar criação de pedido',
        'details': e.toString(),
      },
    );
  }
}
