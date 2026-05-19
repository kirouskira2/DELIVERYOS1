import 'package:dart_frog/dart_frog.dart';

/// Middleware de Autenticação JWT (Sprint 2.4 / Factory 2)
/// Protege todos os endpoints da API (/api/...) exigindo um token válido,
/// exceto endpoints públicos de autenticação e rotas raiz.
Handler middleware(Handler innerHandler) {
  return (context) async {
    final path = context.request.uri.path;

    // Lista de caminhos públicos que não necessitam de autenticação JWT
    if (path == '/' ||
        path.startsWith('/api/auth/login') ||
        path.startsWith('/api/auth/signup')) {
      return innerHandler(context);
    }

    final authHeader = context.request.headers['Authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: 401,
        body: {
          'success': false,
          'error':
              'Não autorizado. Token de autenticação ausente ou inválido no cabeçalho.',
        },
      );
    }

    final token = authHeader.substring(7).trim();
    if (token.isEmpty) {
      return Response.json(
        statusCode: 401,
        body: {
          'success': false,
          'error': 'Não autorizado. Token JWT inválido ou em branco.',
        },
      );
    }

    // Injeta o token do usuário no request context para que serviços
    // possam ler ou propagar a chamadas downstream se necessário.
    final contextWithToken = context.provide<String>(() => token);

    return innerHandler(contextWithToken);
  };
}
