import 'package:backend_dart/services/auth_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late AuthService authService;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    authService = AuthService(mockSupabase);
  });

  group('AuthService.login', () {
    test('retorna sucesso com credenciais válidas', () async {
      final fakeUser = User(
        id: 'user-123',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      final fakeSession = Session(
        accessToken: 'access-token-123',
        tokenType: 'bearer',
        user: fakeUser,
      );

      when(
        () => mockAuth.signInWithPassword(
          email: 'usuario@email.com',
          password: 'senha123',
        ),
      ).thenAnswer(
        (_) async => AuthResponse(session: fakeSession, user: fakeUser),
      );

      final result = await authService.login(
        email: 'usuario@email.com',
        password: 'senha123',
      );

      expect(result.success, isTrue);
      expect(result.statusCode, equals(200));
      expect(result.data, isNotNull);
      expect(result.data!.accessToken, equals('access-token-123'));
    });

    test('retorna 401 quando credenciais inválidas', () async {
      when(
        () => mockAuth.signInWithPassword(
          email: 'errado@email.com',
          password: 'senhaerrada',
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      final result = await authService.login(
        email: 'errado@email.com',
        password: 'senhaerrada',
      );

      expect(result.success, isFalse);
      expect(result.statusCode, equals(401));
      expect(result.error, equals('Invalid login credentials'));
    });

    test('retorna 500 em exceção inesperada', () async {
      when(
        () => mockAuth.signInWithPassword(
          email: 'usuario@email.com',
          password: 'senha123',
        ),
      ).thenThrow(Exception('Erro de rede'));

      final result = await authService.login(
        email: 'usuario@email.com',
        password: 'senha123',
      );

      expect(result.success, isFalse);
      expect(result.statusCode, equals(500));
      expect(result.error, equals('Erro interno do servidor.'));
    });
  });

  group('AuthService.logout', () {
    test('retorna sucesso ao fazer logout', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      final result = await authService.logout();
      expect(result.success, isTrue);
      expect(result.statusCode, equals(200));
    });

    test('retorna 500 ao falhar no logout', () async {
      when(() => mockAuth.signOut()).thenThrow(Exception('Erro desconhecido'));
      final result = await authService.logout();
      expect(result.success, isFalse);
      expect(result.statusCode, equals(500));
    });
  });
}
