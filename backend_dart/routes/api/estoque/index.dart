import 'package:backend_dart/di/setup.dart';
import 'package:backend_dart/services/inventory_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// Rota: /api/estoque
/// Suporta:
/// - POST /api/estoque: Adiciona um novo item (insumo) ao estoque.
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

    final nomeItem = rawBody['nome_item'] as String?;
    final unidadeMedida = rawBody['unidade_medida'] as String? ?? 'UN';
    final quantidadeAtual =
        (rawBody['quantidade_atual'] as num?)?.toDouble() ?? 0.0;
    final quantidadeMinima =
        (rawBody['quantidade_minima'] as num?)?.toDouble() ?? 0.0;
    final custoUnitario =
        (rawBody['custo_unitario'] as num?)?.toDouble() ?? 0.0;
    final categoria = rawBody['categoria'] as String?;
    final fornecedorId = rawBody['fornecedor_id'] as String?;

    if (nomeItem == null || nomeItem.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'error': 'O campo "nome_item" é obrigatório.'},
      );
    }

    final inventoryService = getIt<InventoryService>();
    final result = await inventoryService.addInventoryItem(
      nomeItem: nomeItem.trim(),
      unidadeMedida: unidadeMedida,
      quantidadeAtual: quantidadeAtual,
      quantidadeMinima: quantidadeMinima,
      custoUnitario: custoUnitario,
      categoria: categoria,
      fornecedorId: fornecedorId,
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
        'error': 'Erro ao adicionar item de estoque',
        'details': e.toString(),
      },
    );
  }
}
