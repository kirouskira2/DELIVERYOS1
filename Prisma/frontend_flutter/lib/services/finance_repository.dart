import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceRepository {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getFinanceMetrics() async {
    try {
      final transacoes = await _supabase
          .from('financeiro')
          .select('tipo, valor');
      
      double receitas = 0;
      double despesas = 0;
      for (var t in transacoes) {
        final val = (t['valor'] as num).toDouble();
        if (t['tipo'] == 'RECEITA') receitas += val;
        if (t['tipo'] == 'DESPESA') despesas += val;
      }
      return {
        'total_receitas': receitas,
        'total_despesas': despesas,
        'saldo': receitas - despesas
      };
    } catch (e) {
      return {
        'total_receitas': 0,
        'total_despesas': 0,
        'saldo': 0
      };
    }
  }
  
  Future<Map<String, dynamic>> getFinanceData() async {
    try {
      final transacoes = await _supabase
          .from('financeiro')
          .select('*')
          .order('data_transacao', ascending: false);

      final mensal = await _supabase.from('view_financeiro_mensal').select('*');

      return {
        'transacoes': transacoes,
        'mensal': mensal,
      };
    } catch (e) {
      return {'transacoes': [], 'mensal': []};
    }
  }
  
  Future<Map<String, dynamic>> addTransaction(Map<String, dynamic> data) async {
    final payload = {
      ...data,
      if (data['data_transacao'] == null)
        'data_transacao': DateTime.now().toIso8601String(),
    };
    final response = await _supabase
        .from('financeiro')
        .insert(payload)
        .select()
        .single();
    return response;
  }

  Future<void> deleteTransaction(String id) async {
    await _supabase.from('financeiro').delete().eq('id', id);
  }

  Future<Map<String, dynamic>> updateTransaction(String id, Map<String, dynamic> data) async {
    final response = await _supabase
        .from('financeiro')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return response;
  }
}
