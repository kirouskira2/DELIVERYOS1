import 'package:backend_dart/di/setup.dart';
import 'package:backend_dart/services/auth_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// Sprint 3.2 (Parte 2): Route POST /api/auth/logout
/// Encerra a sessão do usuário no Supabase Auth.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: 405,
      body: {'success': false, 'error': 'Method Not Allowed'},
    );
  }

  try {
    final authService = getIt<AuthService>();
    final result = await authService.logout();

    if (!result.success) {
      return Response.json(
        statusCode: result.statusCode,
        body: {'success': false, 'error': result.error},
      );
    }

    return Response.json(
      body: {'success': true, 'data': 'Sessão encerrada com sucesso.'},
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'error': 'Erro interno do servidor.'},
    );
  }
}
