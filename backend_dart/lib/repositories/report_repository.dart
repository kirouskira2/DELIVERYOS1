import 'package:supabase/supabase.dart';

class ReportRepository {
  ReportRepository(this._supabase);
  final SupabaseClient _supabase;

  Future<Map<String, dynamic>> getDashboardMetrics() async {
    // Busca pedidos concluídos
    final pedidosResponse = await _supabase
        .from('pedidos')
        .select('id, valor_total, created_at')
        .eq('status', 'concluido');

    final pedidos = pedidosResponse as List<dynamic>;

    double receitaTotal = 0;
    final quantidadePedidos = pedidos.length;

    for (final pedido in pedidos) {
      receitaTotal += (pedido['valor_total'] as num).toDouble();
    }

    final ticketMedio = quantidadePedidos > 0
        ? receitaTotal / quantidadePedidos
        : 0;

    return {
      'receita_total': receitaTotal,
      'ticket_medio': ticketMedio,
      'quantidade_pedidos': quantidadePedidos,
    };
  }
}
