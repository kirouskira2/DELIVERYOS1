import 'dart:async';

import 'package:backend_dart/services/dashboard_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

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

void main() {
  late DashboardService dashboardService;
  late MockSupabaseClient mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    dashboardService = DashboardService(mockSupabase);
  });

  group('DashboardService.getMetrics', () {
    final dataInicio = DateTime(2026);
    final dataFim = DateTime(2026, 1, 31);

    test('retorna todos os 7 KPIs calculados corretamente', () async {
      final mockQueryBuilderPedidos = MockSupabaseQueryBuilder();
      final mockFilterBuilderPedidos =
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
            Future.value([
              {'id': '1', 'valor_total': 100.0},
              {'id': '2', 'valor_total': 150.0},
            ]),
          );

      when(
        () => mockSupabase.from('pedidos'),
      ).thenAnswer((_) => mockQueryBuilderPedidos);
      when(
        () => mockQueryBuilderPedidos.select('id, valor_total'),
      ).thenAnswer((_) => mockFilterBuilderPedidos);
      when(
        () => mockFilterBuilderPedidos.eq('status', 'concluido'),
      ).thenAnswer((_) => mockFilterBuilderPedidos);
      when(
        () => mockFilterBuilderPedidos.gte('created_at', any()),
      ).thenAnswer((_) => mockFilterBuilderPedidos);
      when(
        () => mockFilterBuilderPedidos.lte('created_at', any()),
      ).thenAnswer((_) => mockFilterBuilderPedidos);

      final mockFilterBuilderRpc = FakePostgrestFilterBuilder<dynamic>(
        Future.value(80.0),
      );
      when(
        () => mockSupabase.rpc(
          'calcular_cmv_periodo',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => mockFilterBuilderRpc);

      final mockQueryBuilderFinanceiro = MockSupabaseQueryBuilder();
      final mockFilterBuilderFinanceiro =
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
            Future.value([
              {'valor': 30.0},
              {'valor': 20.0},
            ]),
          );

      when(
        () => mockSupabase.from('financeiro'),
      ).thenAnswer((_) => mockQueryBuilderFinanceiro);
      when(
        () => mockQueryBuilderFinanceiro.select('valor'),
      ).thenAnswer((_) => mockFilterBuilderFinanceiro);
      when(
        () => mockFilterBuilderFinanceiro.eq('tipo', 'DESPESA'),
      ).thenAnswer((_) => mockFilterBuilderFinanceiro);
      when(
        () => mockFilterBuilderFinanceiro.gte('data_transacao', any()),
      ).thenAnswer((_) => mockFilterBuilderFinanceiro);
      when(
        () => mockFilterBuilderFinanceiro.lte('data_transacao', any()),
      ).thenAnswer((_) => mockFilterBuilderFinanceiro);

      final mockQueryBuilderEvolucao = MockSupabaseQueryBuilder();
      final mockFilterBuilderEvolucao =
          FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
            Future.value([
              {'data': '2026-01-01', 'receita': 250.0},
            ]),
          );

      when(
        () => mockSupabase.from('view_evolucao_receita'),
      ).thenAnswer((_) => mockQueryBuilderEvolucao);
      when(
        () => mockQueryBuilderEvolucao.select('data, receita'),
      ).thenAnswer((_) => mockFilterBuilderEvolucao);

      final result = await dashboardService.getMetrics(
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      if (!result.success) {
        fail('Falhou com erro: ${result.error}');
      }

      expect(result.success, isTrue);
      expect(result.statusCode, equals(200));

      final data = result.data!;
      expect(data['receita_total'], equals(250.0));
      expect(data['cmv_total'], equals(80.0));
      expect(data['lucro_bruto'], equals(170.0));
      expect(data['margem_pct'], equals(68.0));
      expect(data['ticket_medio'], equals(125.0));
      expect(data['quantidade_pedidos'], equals(2));
      expect(data['total_despesas'], equals(50.0));
    });

    test(
      'retorna KPIs zerados quando nenhum pedido ou CMV cadastrado',
      () async {
        final mockQueryBuilderPedidos = MockSupabaseQueryBuilder();
        final mockFilterBuilderPedidos =
            FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
              Future.value([]),
            );

        when(
          () => mockSupabase.from('pedidos'),
        ).thenAnswer((_) => mockQueryBuilderPedidos);
        when(
          () => mockQueryBuilderPedidos.select('id, valor_total'),
        ).thenAnswer((_) => mockFilterBuilderPedidos);
        when(
          () => mockFilterBuilderPedidos.eq('status', 'concluido'),
        ).thenAnswer((_) => mockFilterBuilderPedidos);
        when(
          () => mockFilterBuilderPedidos.gte('created_at', any()),
        ).thenAnswer((_) => mockFilterBuilderPedidos);
        when(
          () => mockFilterBuilderPedidos.lte('created_at', any()),
        ).thenAnswer((_) => mockFilterBuilderPedidos);

        final mockFilterBuilderRpc = FakePostgrestFilterBuilder<dynamic>(
          Future.value(0.0),
        );
        when(
          () => mockSupabase.rpc(
            'calcular_cmv_periodo',
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) => mockFilterBuilderRpc);

        final mockQueryBuilderFinanceiro = MockSupabaseQueryBuilder();
        final mockFilterBuilderFinanceiro =
            FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
              Future.value([]),
            );

        when(
          () => mockSupabase.from('financeiro'),
        ).thenAnswer((_) => mockQueryBuilderFinanceiro);
        when(
          () => mockQueryBuilderFinanceiro.select('valor'),
        ).thenAnswer((_) => mockFilterBuilderFinanceiro);
        when(
          () => mockFilterBuilderFinanceiro.eq('tipo', 'DESPESA'),
        ).thenAnswer((_) => mockFilterBuilderFinanceiro);
        when(
          () => mockFilterBuilderFinanceiro.gte('data_transacao', any()),
        ).thenAnswer((_) => mockFilterBuilderFinanceiro);
        when(
          () => mockFilterBuilderFinanceiro.lte('data_transacao', any()),
        ).thenAnswer((_) => mockFilterBuilderFinanceiro);

        final mockQueryBuilderEvolucao = MockSupabaseQueryBuilder();
        final mockFilterBuilderEvolucao =
            FakePostgrestFilterBuilder<List<Map<String, dynamic>>>(
              Future.value([]),
            );

        when(
          () => mockSupabase.from('view_evolucao_receita'),
        ).thenAnswer((_) => mockQueryBuilderEvolucao);
        when(
          () => mockQueryBuilderEvolucao.select('data, receita'),
        ).thenAnswer((_) => mockFilterBuilderEvolucao);

        final result = await dashboardService.getMetrics(
          dataInicio: dataInicio,
          dataFim: dataFim,
        );

        if (!result.success) {
          fail('Falhou com erro: ${result.error}');
        }

        expect(result.success, isTrue);
        expect(result.statusCode, equals(200));

        final data = result.data!;
        expect(data['receita_total'], equals(0.0));
        expect(data['cmv_total'], equals(0.0));
        expect(data['lucro_bruto'], equals(0.0));
        expect(data['margem_pct'], equals(0.0));
        expect(data['ticket_medio'], equals(0.0));
        expect(data['quantidade_pedidos'], equals(0));
        expect(data['total_despesas'], equals(0.0));
      },
    );
  });
}
