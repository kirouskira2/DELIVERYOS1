import 'package:backend_dart/repositories/order_repository.dart';
import 'package:backend_dart/services/order_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late OrderService orderService;
  late MockSupabaseClient mockSupabase;
  late MockOrderRepository mockRepo;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockRepo = MockOrderRepository();
    orderService = OrderService(mockSupabase, orderRepository: mockRepo);
  });

  group('OrderService.createOrder', () {
    final itensValidos = [
      {'cardapio_id': 'c1', 'quantidade': 2, 'preco_unitario': 15.0},
    ];

    test('cria pedido com itens válidos e calcula valor total', () async {
      when(
        () => mockRepo.insertOrder(
          tipo: 'balcao',
          itens: itensValidos,
        ),
      ).thenAnswer((_) async => {'id': 'pedido-123', 'status': 'novo'});

      when(
        () => mockRepo.updateValorTotal('pedido-123', 30),
      ).thenAnswer((_) async => {});

      final result = await orderService.createOrder(
        tipo: 'balcao',
        itens: itensValidos,
      );

      expect(result.success, isTrue);
      expect(result.statusCode, equals(201));
      expect(result.data!['valor_total'], equals(30.0));

      verify(
        () => mockRepo.insertOrder(
          tipo: 'balcao',
          itens: itensValidos,
        ),
      ).called(1);
      verify(() => mockRepo.updateValorTotal('pedido-123', 30)).called(1);
    });

    test('retorna 400 com lista de itens vazia', () async {
      final result = await orderService.createOrder(tipo: 'balcao', itens: []);
      expect(result.success, isFalse);
      expect(result.statusCode, equals(400));
      expect(result.error, equals('O pedido deve conter ao menos um item.'));
      verifyNever(
        () => mockRepo.insertOrder(
          tipo: any(named: 'tipo'),
          itens: any(named: 'itens'),
        ),
      );
    });
  });

  group('OrderService.updateOrderStatus', () {
    test('atualiza para pendente sem acionar RPC de estoque', () async {
      when(
        () => mockRepo.updateStatus(
          pedidoId: 'pedido-123',
          novoStatus: 'preparando',
        ),
      ).thenAnswer((_) async => {});

      final result = await orderService.updateOrderStatus(
        pedidoId: 'pedido-123',
        novoStatus: 'preparando',
      );

      expect(result.success, isTrue);
      expect(result.statusCode, equals(200));
      verifyNever(() => mockRepo.processarBaixaEstoquePedido(any()));
    });

    test('atualiza para concluido e aciona RPC de baixa', () async {
      when(
        () => mockRepo.updateStatus(
          pedidoId: 'pedido-123',
          novoStatus: 'concluido',
        ),
      ).thenAnswer((_) async => {});
      when(
        () => mockRepo.processarBaixaEstoquePedido('pedido-123'),
      ).thenAnswer((_) async => {});

      final result = await orderService.updateOrderStatus(
        pedidoId: 'pedido-123',
        novoStatus: 'concluido',
      );

      expect(result.success, isTrue);
      expect(result.statusCode, equals(200));
      verify(
        () => mockRepo.processarBaixaEstoquePedido('pedido-123'),
      ).called(1);
    });

    test('retorna 500 quando falha ao atualizar status', () async {
      when(
        () => mockRepo.updateStatus(
          pedidoId: 'pedido-123',
          novoStatus: 'concluido',
        ),
      ).thenThrow(Exception('Erro no banco'));

      final result = await orderService.updateOrderStatus(
        pedidoId: 'pedido-123',
        novoStatus: 'concluido',
      );

      expect(result.success, isFalse);
      expect(result.statusCode, equals(500));
    });
  });
}
