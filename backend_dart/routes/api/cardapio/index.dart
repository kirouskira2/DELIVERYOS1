import 'package:backend_dart/di/setup.dart';
import 'package:backend_dart/services/menu_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// Rota: /api/cardapio
/// Suporta:
/// - POST /api/cardapio: Cria um novo prato no cardápio e associa seus insumos (ficha técnica).
/// - GET /api/cardapio: Lista todos os itens do cardápio com suas fichas técnicas detalhadas.
Future<Response> onRequest(RequestContext context) async {
  switch (context.request.method) {
    case HttpMethod.post:
      return _handleCreate(context);
    case HttpMethod.get:
      return _handleList(context);
    default:
      return Response.json(
        statusCode: 405,
        body: {'success': false, 'error': 'Method Not Allowed'},
      );
  }
}

Future<Response> _handleCreate(RequestContext context) async {
  try {
    final rawBody = await context.request.json();
    if (rawBody is! Map<String, dynamic>) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'error': 'Payload inválido.'},
      );
    }

    final nome = rawBody['nome'] as String?;
    final precoVenda = (rawBody['preco_venda'] as num?)?.toDouble();
    final descricao = rawBody['descricao'] as String?;
    final categoria = rawBody['categoria'] as String?;
    final custoProducao =
        (rawBody['custo_producao'] as num?)?.toDouble() ?? 0.0;
    final rawReceita = rawBody['receita'];

    if (nome == null || nome.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'error': 'O campo "nome" é obrigatório.'},
      );
    }

    if (precoVenda == null || precoVenda < 0) {
      return Response.json(
        statusCode: 400,
        body: {
          'success': false,
          'error':
              'O campo "preco_venda" é obrigatório e não pode ser negativo.',
        },
      );
    }

    final receita = <Map<String, dynamic>>[];
    if (rawReceita != null) {
      if (rawReceita is! List) {
        return Response.json(
          statusCode: 400,
          body: {
            'success': false,
            'error': 'O campo "receita" deve ser uma lista.',
          },
        );
      }

      for (final item in rawReceita) {
        if (item is! Map<String, dynamic>) {
          return Response.json(
            statusCode: 400,
            body: {
              'success': false,
              'error': 'Cada item da receita deve ser um objeto JSON válido.',
            },
          );
        }
        receita.add(item);
      }
    }

    final menuService = getIt<MenuService>();
    final result = await menuService.createMenuItem(
      nome: nome.trim(),
      precoVenda: precoVenda,
      descricao: descricao,
      categoria: categoria,
      custoProducao: custoProducao,
      receita: receita,
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
        'error': 'Erro ao criar item do cardápio',
        'details': e.toString(),
      },
    );
  }
}

Future<Response> _handleList(RequestContext context) async {
  try {
    final menuService = getIt<MenuService>();
    final result = await menuService.getMenuItems();

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
        'error': 'Erro ao buscar itens do cardápio',
        'details': e.toString(),
      },
    );
  }
}
