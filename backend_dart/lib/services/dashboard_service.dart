import 'package:backend_dart/services/auth_service.dart';
import 'package:supabase/supabase.dart';

/// Sprint 3.2 (Negócios): Dashboard Service (Factory 2)
/// Lógica de cálculo dos KPIs: Receita, CMV, Ticket Médio e Margem de Lucro.
/// Roda 100% no servidor. Nenhum cálculo sensível escapa para o Flutter client.
class DashboardService {
  DashboardService(this._supabase);
  final SupabaseClient _supabase;

  /// Retorna todos os KPIs do dashboard para um período de datas.
  Future<ActionResponse<Map<String, dynamic>>> getMetrics({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      // 1. Buscar pedidos concluídos no período (Receita)
      final pedidosResponse = await _supabase
          .from('pedidos')
          .select('id, valor_total')
          .eq('status', 'concluido')
          .gte('created_at', dataInicio.toIso8601String())
          .lte('created_at', dataFim.toIso8601String());

      final pedidos = pedidosResponse as List<dynamic>;
      final quantidadePedidos = pedidos.length;
      final receitaTotal = pedidos.fold<double>(
        0,
        (sum, p) => sum + (p['valor_total'] as num).toDouble(),
      );
      final ticketMedio = quantidadePedidos > 0
          ? receitaTotal / quantidadePedidos
          : 0.0;

      // 2. Calcular CMV: soma dos itens vendidos * custo_unitario do insumo via ficha_tecnica
      final cmvResponse = await _supabase.rpc(
        'calcular_cmv_periodo',
        params: {
          'p_data_inicio': dataInicio.toIso8601String(),
          'p_data_fim': dataFim.toIso8601String(),
        },
      );
      final cmvTotal = (cmvResponse as num?)?.toDouble() ?? 0.0;

      // 3. Calcular Lucro Bruto e Margem
      final lucroBruto = receitaTotal - cmvTotal;
      final margemPct = receitaTotal > 0
          ? (lucroBruto / receitaTotal) * 100
          : 0.0;

      // 4. Buscar Despesas do período na tabela financeiro
      final despesasResponse = await _supabase
          .from('financeiro')
          .select('valor')
          .eq('tipo', 'DESPESA')
          .gte('data_transacao', dataInicio.toIso8601String())
          .lte('data_transacao', dataFim.toIso8601String());

      final totalDespesas = (despesasResponse as List<dynamic>).fold<double>(
        0,
        (sum, d) => sum + (d['valor'] as num).toDouble(),
      );

      // 5. Buscar Evolução da Receita (para o gráfico)
      final evolucaoResponse = await _supabase
          .from('view_evolucao_receita')
          .select('data, receita');


      final pedidosLista = (evolucaoResponse as List<dynamic>).map((e) => {
        'data': e['data'],
        'valor_total': (e['receita'] as num).toDouble(),
      }).toList();

      return ActionResponse(
        success: true,
        statusCode: 200,
        data: {
          'receita_total': receitaTotal,
          'cmv_total': cmvTotal,
          'lucro_bruto': lucroBruto,
          'margem_pct': double.parse(margemPct.toStringAsFixed(2)),
          'ticket_medio': double.parse(ticketMedio.toStringAsFixed(2)),
          'quantidade_pedidos': quantidadePedidos,
          'total_despesas': totalDespesas,
          'pedidos_lista': pedidosLista,
        },
      );
    } catch (e) {
      return ActionResponse(
        success: false,
        error: 'Erro ao calcular métricas: $e',
        statusCode: 500,
      );
    }
  }
}
