import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getMetrics({DateTime? dataInicio, DateTime? dataFim}) async {
    final start = dataInicio ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
    final end = dataFim ?? DateTime.now();

    try {
      // 1. Buscar pedidos concluídos no período (Receita)
      final pedidosResponse = await _supabase
          .from('pedidos')
          .select('id, valor_total')
          .eq('status', 'concluido')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());

      final pedidos = pedidosResponse as List<dynamic>;
      final quantidadePedidos = pedidos.length;
      final receitaTotal = pedidos.fold<double>(
        0,
        (sum, p) => sum + (p['valor_total'] as num).toDouble(),
      );
      final ticketMedio = quantidadePedidos > 0
          ? receitaTotal / quantidadePedidos
          : 0.0;

      // 2. Calcular CMV via RPC do Postgres
      double cmvTotal = 0.0;
      try {
        final cmvResponse = await _supabase.rpc(
          'calcular_cmv_periodo',
          params: {
            'p_data_inicio': start.toIso8601String(),
            'p_data_fim': end.toIso8601String(),
          },
        );
        cmvTotal = (cmvResponse as num?)?.toDouble() ?? 0.0;
      } catch (_) {
        // Fallback silencioso caso a função RPC não esteja disponível
      }

      final lucroBruto = receitaTotal - cmvTotal;
      final margemPct = receitaTotal > 0
          ? (lucroBruto / receitaTotal) * 100
          : 0.0;

      // 3. Buscar Despesas no período
      final despesasResponse = await _supabase
          .from('financeiro')
          .select('valor')
          .eq('tipo', 'DESPESA')
          .gte('data_transacao', start.toIso8601String())
          .lte('data_transacao', end.toIso8601String());

      final totalDespesas = (despesasResponse as List<dynamic>).fold<double>(
        0,
        (sum, d) => sum + (d['valor'] as num).toDouble(),
      );

      // 4. Buscar Evolução da Receita para o gráfico
      final evolucaoResponse = await _supabase
          .from('view_evolucao_receita')
          .select('data, receita');

      final pedidosLista = (evolucaoResponse as List<dynamic>).map((e) => {
        'data': e['data'],
        'valor_total': (e['receita'] as num).toDouble(),
      }).toList();

      return {
        'receita_total': receitaTotal,
        'cmv_total': cmvTotal,
        'lucro_bruto': lucroBruto,
        'margem_pct': double.parse(margemPct.toStringAsFixed(2)),
        'ticket_medio': double.parse(ticketMedio.toStringAsFixed(2)),
        'quantidade_pedidos': quantidadePedidos,
        'total_despesas': totalDespesas,
        'pedidos_lista': pedidosLista,
      };
    } catch (e) {
      return {
        'receita_total': 0.0,
        'cmv_total': 0.0,
        'lucro_bruto': 0.0,
        'margem_pct': 0.0,
        'ticket_medio': 0.0,
        'quantidade_pedidos': 0,
        'total_despesas': 0.0,
        'pedidos_lista': [],
      };
    }
  }
}
