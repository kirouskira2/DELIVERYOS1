import 'package:backend_dart/services/auth_service.dart';
import 'package:supabase/supabase.dart';

/// Service de Estoque (Factory 2 — Lógica de Negócio)
/// Gerencia entrada de insumos, ajustes manuais e alertas de estoque mínimo.
class InventoryService {
  InventoryService(this._supabase);
  final SupabaseClient _supabase;

  /// Adiciona um novo insumo ao estoque.
  Future<ActionResponse<Map<String, dynamic>>> addInventoryItem({
    required String nomeItem,
    required String unidadeMedida,
    required double quantidadeAtual,
    required double quantidadeMinima,
    required double custoUnitario,
    String? categoria,
    String? fornecedorId,
  }) async {
    if (nomeItem.trim().isEmpty) {
      return const ActionResponse(
        success: false,
        error: 'O nome do item é obrigatório.',
        statusCode: 400,
      );
    }

    try {
      final response = await _supabase
          .from('estoque')
          .insert({
            'nome_item': nomeItem.trim(),
            'unidade_medida': unidadeMedida,
            'quantidade_atual': quantidadeAtual,
            'quantidade_minima': quantidadeMinima,
            'custo_unitario': custoUnitario,
            'categoria': categoria,
            'fornecedor_id': fornecedorId,
          })
          .select()
          .single();

      return ActionResponse(
        success: true,
        data: response,
        statusCode: 201,
      );
    } catch (e) {
      return ActionResponse(
        success: false,
        error: 'Erro ao adicionar insumo: $e',
        statusCode: 500,
      );
    }
  }

  /// Ajusta manualmente a quantidade de um insumo (entrada de compra ou descarte).
  /// [tipo] deve ser 'add' para entrada ou 'remove' para saída.
  Future<ActionResponse<void>> updateStock({
    required String itemId,
    required double quantidade,
    required String tipo,
  }) async {
    if (quantidade <= 0) {
      return const ActionResponse(
        success: false,
        error: 'A quantidade deve ser maior que zero.',
        statusCode: 400,
      );
    }

    try {
      final current = await _supabase
          .from('estoque')
          .select('quantidade_atual')
          .eq('id', itemId)
          .single();

      final qtdAtual = (current['quantidade_atual'] as num).toDouble();
      final novaQuantidade = tipo == 'add'
          ? qtdAtual + quantidade
          : qtdAtual - quantidade;

      if (novaQuantidade < 0) {
        return const ActionResponse(
          success: false,
          error: 'Operação resultaria em saldo negativo de estoque.',
          statusCode: 422,
        );
      }

      await _supabase
          .from('estoque')
          .update({'quantidade_atual': novaQuantidade})
          .eq('id', itemId);

      return const ActionResponse(success: true, statusCode: 200);
    } catch (e) {
      return ActionResponse(
        success: false,
        error: 'Erro ao ajustar estoque: $e',
        statusCode: 500,
      );
    }
  }

  /// Retorna todos os insumos abaixo da quantidade mínima (alertas de estoque).
  ///
  /// IMPORTANTE: usa a RPC `get_low_stock_items` no banco em vez de filtro client-side.
  /// O filtro `.filter('quantidade_atual', 'lte', 'quantidade_minima')` na API Dart
  /// compara com a STRING LITERAL 'quantidade_minima', não com o valor da coluna.
  /// A RPC garante comparação correta entre colunas dentro do PostgreSQL.
  Future<ActionResponse<List<dynamic>>> getLowStockAlerts() async {
    try {
      final response = await _supabase.rpc('get_low_stock_items');

      return ActionResponse(
        success: true,
        data: response as List<dynamic>,
        statusCode: 200,
      );
    } catch (e) {
      return ActionResponse(
        success: false,
        error: 'Erro ao buscar alertas de estoque: $e',
        statusCode: 500,
      );
    }
  }
}
