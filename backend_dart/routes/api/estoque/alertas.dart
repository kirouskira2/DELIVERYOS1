import 'package:backend_dart/di/setup.dart';
import 'package:backend_dart/services/inventory_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// Rota: GET /api/estoque/alertas
/// Retorna todos os insumos abaixo da quantidade mínima configurada no banco.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'error': 'Method Not Allowed'},
    );
  }

  try {
    final inventoryService = getIt<InventoryService>();
    final result = await inventoryService.getLowStockAlerts();

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
        'error': 'Erro ao buscar alertas de estoque',
        'details': e.toString(),
      },
    );
  }
}
