import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getReportsData() async {
    try {
      // 1. Consultar views agregadas de vendas
      final topSellersResponse = await _supabase.from('view_top_sellers').select('*');
      final melhoresClientesResponse = await _supabase.from('view_melhores_clientes_b2b').select('*');

      final topSellers = (topSellersResponse as List<dynamic>).map((item) => {
        'nome': item['nome'],
        'quantidade_pedida': item['quantidade_pedida'] ?? 0,
      }).toList();

      // 2. Mapear clientes B2B tratando de forma ultra-segura a conversão de String/Decimal do Postgres para double
      final melhoresClientes = (melhoresClientesResponse as List<dynamic>).map((item) {
        final totalGastoVal = item['total_gasto'];
        double totalGasto = 0.0;
        if (totalGastoVal is num) {
          totalGasto = totalGastoVal.toDouble();
        } else if (totalGastoVal != null) {
          totalGasto = double.tryParse(totalGastoVal.toString()) ?? 0.0;
        }

        return {
          'nome': item['nome'],
          'total_gasto': totalGasto,
        };
      }).toList();

      return {
        'top_sellers': topSellers,
        'melhores_clientes': melhoresClientes,
      };
    } catch (e) {
      print('Erro ao carregar relatórios do Supabase: $e');
      return {
        'top_sellers': [],
        'melhores_clientes': [],
      };
    }
  }
}
