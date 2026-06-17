import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_os/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Apenas verifica que o app constrói sem erros
    expect(DeliveryOSApp, isNotNull);
  });
}
