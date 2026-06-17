import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsRepository {
  final _supabase = Supabase.instance.client;

  /// Busca dados de relatórios filtrados por período (últimos N dias).
  Future<Map<String, dynamic>> getReportData({int days = 30}) async {
    try {
      final desde = DateTime.now().subtract(Duration(days: days)).toIso8601String();

      // 1. Buscar pedidos do período
      final pedidosRes = await _supabase
          .from('pedidos')
          .select('id, valor_total, created_at, tipo, status')
          .gte('created_at', desde)
          .order('created_at');

      // 2. Buscar top pratos vendidos
      List topPratos = [];
      try {
        final topSellersRes = await _supabase.from('view_top_sellers').select('*');
        topPratos = (topSellersRes as List<dynamic>).map((item) => {
          'nome': item['nome'] ?? 'Desconhecido',
          'total_vendido': item['quantidade_pedida'] ?? 0,
          'receita': (item['receita_total'] as num?)?.toDouble() ?? 0.0,
        }).toList();
      } catch (_) {}

      // 3. Buscar melhores clientes B2B
      List topClientes = [];
      try {
        final clientesRes = await _supabase.from('view_melhores_clientes_b2b').select('*');
        topClientes = (clientesRes as List<dynamic>).map((item) {
          final totalGastoVal = item['total_gasto'];
          double totalGasto = 0.0;
          if (totalGastoVal is num) {
            totalGasto = totalGastoVal.toDouble();
          } else if (totalGastoVal != null) {
            totalGasto = double.tryParse(totalGastoVal.toString()) ?? 0.0;
          }
          return {
            'nome_empresa': item['nome'] ?? 'Desconhecido',
            'total_pedidos': item['total_pedidos'] ?? 0,
            'total_gasto': totalGasto,
          };
        }).toList();
      } catch (_) {}

      return {
        'pedidos_lista': pedidosRes,
        'top_pratos': topPratos,
        'top_clientes': topClientes,
      };
    } catch (e) {
      return {
        'pedidos_lista': [],
        'top_pratos': [],
        'top_clientes': [],
      };
    }
  }

  /// Método legado preservado para compatibilidade reversa.
  Future<Map<String, dynamic>> getReportsData() async {
    return getReportData(days: 30);
  }
}
