import 'package:backend_dart/di/setup.dart';
import 'package:backend_dart/services/auth_service.dart';
import 'package:dart_frog/dart_frog.dart';

/// Sprint 3.2 (Parte 1): Route POST /api/auth/login
/// Recebe email e senha, autentica via Supabase e retorna o token de sessão.
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

    final email = rawBody['email'] as String?;
    final password = rawBody['password'] as String?;

    if (email == null ||
        email.trim().isEmpty ||
        password == null ||
        password.trim().isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'error': 'E-mail e senha são obrigatórios.'},
      );
    }

    final authService = getIt<AuthService>();
    final result = await authService.login(email: email, password: password);

    if (!result.success) {
      return Response.json(
        statusCode: result.statusCode,
        body: {'success': false, 'error': result.error},
      );
    }

    final session = result.data!;
    return Response.json(
      body: {
        'success': true,
        'data': {
          'access_token': session.accessToken,
          'refresh_token': session.refreshToken,
          'expires_at': session.expiresAt,
          'user': {
            'id': session.user.id,
            'email': session.user.email,
          },
        },
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 500,
      body: {'success': false, 'error': 'Erro interno do servidor.'},
    );
  }
}
