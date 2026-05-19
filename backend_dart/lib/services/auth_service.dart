import 'package:supabase/supabase.dart';

/// Modelo de resposta padrão para todas as actions (equivalente ao ActionResponse do Prisma V4.0)
class ActionResponse<T> {
  const ActionResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.error,
  });
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;
}

/// Sprint 3.1: Auth Service (Factory 2 - Lógica de Autenticação via Supabase)
/// Roda no contexto do Dart Frog Backend, isolado do Flutter Client.
class AuthService {
  AuthService(this._supabase);
  final SupabaseClient _supabase;

  /// Autentica o usuário com e-mail e senha.
  /// Retorna o token da sessão para o Flutter usar no header Authorization.
  Future<ActionResponse<Session>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        return const ActionResponse(
          success: false,
          error: 'Credenciais inválidas.',
          statusCode: 401,
        );
      }

      return ActionResponse(
        success: true,
        data: response.session,
        statusCode: 200,
      );
    } on AuthException catch (e) {
      return ActionResponse(
        success: false,
        error: e.message,
        statusCode: 401,
      );
    } catch (e) {
      return const ActionResponse(
        success: false,
        error: 'Erro interno do servidor.',
        statusCode: 500,
      );
    }
  }

  /// Encerra a sessão do usuário no Supabase Auth.
  Future<ActionResponse<void>> logout() async {
    try {
      await _supabase.auth.signOut();
      return const ActionResponse(success: true, statusCode: 200);
    } catch (e) {
      return const ActionResponse(
        success: false,
        error: 'Erro ao encerrar a sessão.',
        statusCode: 500,
      );
    }
  }
}
