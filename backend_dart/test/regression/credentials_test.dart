import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Security Regressions', () {
    test('garante que setup.dart não contém chaves de produção hard-coded', () {
      final file = File('lib/di/setup.dart');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();

      // Nenhuma chave do tipo 'https://xnoivcxperibtuovusuo...' ou token deve constar no código
      final hasRealUrl = content.contains('xnoivcxperibtuovusuo');
      final hasRealKey = content.contains(
        'sb_publishable_MEY2Tu7dhx9LfkNjyiC5Gw',
      );

      expect(
        hasRealUrl,
        isFalse,
        reason: 'URL real do Supabase foi hard-coded em setup.dart!',
      );
      expect(
        hasRealKey,
        isFalse,
        reason: 'Chave real do Supabase foi hard-coded em setup.dart!',
      );
    });

    test('garante que o arquivo .env está listado no .gitignore', () {
      final gitignore = File('.gitignore');
      if (gitignore.existsSync()) {
        final content = gitignore.readAsStringSync();
        expect(
          content.contains('.env'),
          isTrue,
          reason:
              'O arquivo .env DEVE estar no .gitignore para evitar vazamento de credenciais.',
        );
      }
    });
  });
}
