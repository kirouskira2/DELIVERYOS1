import 'package:backend_dart/di/setup.dart';
import 'package:backend_dart/services/inventory_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// Rota: PATCH /api/estoque/[id]
/// Ajusta manualmente a quantidade de um insumo específico (entrada/saída).
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

    final quantidade = (rawBody['quantidade'] as num?)?.toDouble();
    final tipo = rawBody['tipo'] as String?; // 'add' ou 'remove'

    if (quantidade == null || quantidade <= 0) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'error':
              'O campo "quantidade" é obrigatório e deve ser maior que zero.',
        },
      );
    }

    if (tipo == null || (tipo != 'add' && tipo != 'remove')) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'error': 'O campo "tipo" é obrigatório e deve ser "add" ou "remove".',
        },
      );
    }

    final inventoryService = getIt<InventoryService>();
    final result = await inventoryService.updateStock(
      itemId: id,
      quantidade: quantidade,
      tipo: tipo,
    );

    return Response.json(
      statusCode: result.statusCode,
      body: result.success
          ? {'success': true, 'message': 'Estoque ajustado com sucesso.'}
          : {'success': false, 'error': result.error},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {
        'success': false,
        'error': 'Erro ao ajustar estoque do item',
        'details': e.toString(),
      },
    );
  }
}
