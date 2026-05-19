import 'package:backend_dart/models/pedido.dart';
import 'package:test/test.dart';

void main() {
  group('Pedido Model', () {
    final now = DateTime.now();

    test('deserializa corretamente a partir do JSON do banco', () {
      final json = {
        'id': 'pedido-uuid',
        'user_id': 'user-uuid',
        'cliente_id': 'cliente-uuid',
        'status': 'novo',
        'tipo': 'delivery',
        'valor_total': 54.90,
        'observacoes': 'Sem cebola',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final pedido = Pedido.fromJson(json);

      expect(pedido.id, equals('pedido-uuid'));
      expect(pedido.userId, equals('user-uuid'));
      expect(pedido.clienteId, equals('cliente-uuid'));
      expect(pedido.status, equals('novo'));
      expect(pedido.tipo, equals('delivery'));
      expect(pedido.valorTotal, equals(54.90));
      expect(pedido.observacoes, equals('Sem cebola'));
      expect(pedido.createdAt.day, equals(now.day));
      expect(pedido.updatedAt!.day, equals(now.day));
    });

    test('serializa corretamente para JSON', () {
      final pedido = Pedido(
        id: 'pedido-uuid',
        userId: 'user-uuid',
        clienteId: 'cliente-uuid',
        status: 'novo',
        tipo: 'delivery',
        valorTotal: 54.90,
        observacoes: 'Sem cebola',
        createdAt: now,
        updatedAt: now,
      );

      final json = pedido.toJson();

      expect(json['id'], equals('pedido-uuid'));
      expect(json['user_id'], equals('user-uuid'));
      expect(json['cliente_id'], equals('cliente-uuid'));
      expect(json['status'], equals('novo'));
      expect(json['tipo'], equals('delivery'));
      expect(json['valor_total'], equals(54.90));
      expect(json['observacoes'], equals('Sem cebola'));
      expect(json['created_at'], equals(now.toIso8601String()));
      expect(json['updated_at'], equals(now.toIso8601String()));
    });
  });
}
