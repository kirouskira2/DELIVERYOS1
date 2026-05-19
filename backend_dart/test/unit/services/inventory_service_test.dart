import 'dart:async';

import 'package:backend_dart/services/inventory_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

class FakePostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {
  FakePostgrestFilterBuilder(this._future);
  final Future<T> _future;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }
}

class FakePostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {
  FakePostgrestTransformBuilder(this._future);
  final Future<T> _future;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }
}

void main() {
  late InventoryService inventoryService;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    inventoryService = InventoryService(mockSupabase);
  });

  group('InventoryService.addInventoryItem', () {
    test('adiciona item válido', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();

      final mockTransformBuilder =
          FakePostgrestTransformBuilder<Map<String, dynamic>>(
            Future.value({
              'id': '123',
              'nome_item': 'Farinha de Trigo',
            }),
          );

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(
        () => mockSupabase.from('estoque'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.insert({
          'nome_item': 'Farinha de Trigo',
          'unidade_medida': 'KG',
          'quantidade_atual': 10.0,
          'quantidade_minima': 2.0,
          'custo_unitario': 5.0,
          'categoria': 'Ingredientes',
          'fornecedor_id': null,
        }),
      ).thenAnswer((_) => mockFilterBuilder);

      when(
        mockFilterBuilder.select,
      ).thenAnswer((_) => mockFilterBuilder);
      when(
        mockFilterBuilder.single,
      ).thenAnswer((_) => mockTransformBuilder);

      final result = await inventoryService.addInventoryItem(
        nomeItem: 'Farinha de Trigo',
        unidadeMedida: 'KG',
        quantidadeAtual: 10,
        quantidadeMinima: 2,
        custoUnitario: 5,
        categoria: 'Ingredientes',
      );

      if (!result.success) {
        fail('Falhou com erro: ${result.error}');
      }

      expect(result.success, isTrue);
      expect(result.statusCode, equals(201));
      expect(result.data!['id'], equals('123'));
    });

    test('retorna 400 se o nome for vazio', () async {
      final result = await inventoryService.addInventoryItem(
        nomeItem: '',
        unidadeMedida: 'KG',
        quantidadeAtual: 10,
        quantidadeMinima: 2,
        custoUnitario: 5,
      );

      expect(result.success, isFalse);
      expect(result.statusCode, equals(400));
      expect(result.error, equals('O nome do item é obrigatório.'));
    });
  });

  group('InventoryService.updateStock', () {
    test('ajusta estoque adicionando quantidade', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();

      final mockTransformBuilderSelect =
          FakePostgrestTransformBuilder<Map<String, dynamic>>(
            Future.value({'quantidade_atual': 5.0}),
          );

      final mockFilterBuilderSelect = MockPostgrestFilterBuilder();

      when(
        () => mockSupabase.from('estoque'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.select('quantidade_atual'),
      ).thenAnswer((_) => mockFilterBuilderSelect);
      when(
        () => mockFilterBuilderSelect.eq('id', '123'),
      ).thenAnswer((_) => mockFilterBuilderSelect);
      when(
        mockFilterBuilderSelect.single,
      ).thenAnswer((_) => mockTransformBuilderSelect);

      final mockFilterBuilderUpdate =
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
            Future.value([]),
          );
      when(
        () => mockQueryBuilder.update({'quantidade_atual': 8.0}),
      ).thenAnswer((_) => mockFilterBuilderUpdate);
      when(
        () => mockFilterBuilderUpdate.eq('id', '123'),
      ).thenAnswer((_) => mockFilterBuilderUpdate);

      final result = await inventoryService.updateStock(
        itemId: '123',
        quantidade: 3,
        tipo: 'add',
      );

      if (!result.success) {
        fail('Falhou com erro: ${result.error}');
      }

      expect(result.success, isTrue);
      expect(result.statusCode, equals(200));
    });

    test('retorna 422 se o saldo final for negativo ao remover', () async {
      final mockQueryBuilder = MockSupabaseQueryBuilder();

      final mockTransformBuilderSelect =
          FakePostgrestTransformBuilder<Map<String, dynamic>>(
            Future.value({'quantidade_atual': 5.0}),
          );

      final mockFilterBuilderSelect = MockPostgrestFilterBuilder();

      when(
        () => mockSupabase.from('estoque'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.select('quantidade_atual'),
      ).thenAnswer((_) => mockFilterBuilderSelect);
      when(
        () => mockFilterBuilderSelect.eq('id', '123'),
      ).thenAnswer((_) => mockFilterBuilderSelect);
      when(
        mockFilterBuilderSelect.single,
      ).thenAnswer((_) => mockTransformBuilderSelect);

      final result = await inventoryService.updateStock(
        itemId: '123',
        quantidade: 10,
        tipo: 'remove',
      );

      expect(result.success, isFalse);
      expect(result.statusCode, equals(422));
      expect(
        result.error,
        equals('Operação resultaria em saldo negativo de estoque.'),
      );
    });
  });

  group('InventoryService.getLowStockAlerts', () {
    test('chama a RPC get_low_stock_items e retorna dados', () async {
      final mockFilterBuilder = FakePostgrestFilterBuilder<dynamic>(
        Future.value([
          {
            'id': '1',
            'nome_item': 'Leite',
            'quantidade_atual': 1.0,
            'quantidade_minima': 3.0,
          },
        ]),
      );
      when(
        () => mockSupabase.rpc('get_low_stock_items'),
      ).thenAnswer((_) => mockFilterBuilder);

      final result = await inventoryService.getLowStockAlerts();

      if (!result.success) {
        fail('Falhou com erro: ${result.error}');
      }

      expect(result.success, isTrue);
      expect(result.statusCode, equals(200));
      expect(result.data, hasLength(1));
      expect(result.data![0]['nome_item'], equals('Leite'));
    });
  });
}
