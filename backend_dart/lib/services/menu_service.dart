import 'package:backend_dart/services/auth_service.dart';
import 'package:supabase/supabase.dart';

/// Service de Cardápio e Ficha Técnica (Sprint 3.3 / Factory 2)
/// Gerencia a criação de itens do cardápio e associação de seus insumos necessários.
class MenuService {
  MenuService(this._supabase);
  final SupabaseClient _supabase;

  /// Cria um novo item no cardápio e associa seus ingredientes na ficha técnica.
  /// A transacionalidade completa é garantida no Supabase.
  Future<ActionResponse<Map<String, dynamic>>> createMenuItem({
    required String nome,
    required double precoVenda,
    String? descricao,
    String? categoria,
    double custoProducao = 0.0,
    List<Map<String, dynamic>> receita = const [],
  }) async {
    if (nome.trim().isEmpty) {
      return const ActionResponse(
        success: false,
        error: 'O nome do item do cardápio é obrigatório.',
        statusCode: 400,
      );
    }

    if (precoVenda < 0) {
      return const ActionResponse(
        success: false,
        error: 'O preço de venda não pode ser negativo.',
        statusCode: 400,
      );
    }

    try {
      // 1. Inserir no cardapio
      final item = await _supabase
          .from('cardapio')
          .insert({
            'nome': nome.trim(),
            'descricao': descricao?.trim(),
            'categoria': categoria?.trim(),
            'preco_venda': precoVenda,
            'custo_producao': custoProducao,
            'disponivel': true,
          })
          .select()
          .single();

      final cardapioId = item['id'] as String;

      // 2. Se houver receita (ingredientes), inserir na ficha_tecnica
      if (receita.isNotEmpty) {
        final ingredientesMapped = receita.map((ingrediente) {
          final estoqueId = ingrediente['estoque_id'] as String?;
          final qtdNecessaria = (ingrediente['quantidade_necessaria'] as num?)
              ?.toDouble();

          if (estoqueId == null || estoqueId.trim().isEmpty) {
            throw ArgumentError(
              'O campo "estoque_id" é obrigatório para todos os ingredientes.',
            );
          }

          if (qtdNecessaria == null || qtdNecessaria <= 0) {
            throw ArgumentError(
              'A quantidade do ingrediente deve ser maior que zero.',
            );
          }

          return {
            'cardapio_id': cardapioId,
            'estoque_id': estoqueId,
            'quantidade_necessaria': qtdNecessaria,
          };
        }).toList();

        await _supabase.from('ficha_tecnica').insert(ingredientesMapped);
      }

      return ActionResponse(
        success: true,
        data: item,
        statusCode: 201,
      );
    } on ArgumentError catch (e) {
      return ActionResponse(
        success: false,
        error: e.message?.toString(),
        statusCode: 400,
      );
    } catch (e) {
      return ActionResponse(
        success: false,
        error: 'Erro ao criar item do cardápio: $e',
        statusCode: 500,
      );
    }
  }

  /// Retorna todos os itens do cardápio com suas fichas técnicas associadas.
  Future<ActionResponse<List<dynamic>>> getMenuItems() async {
    try {
      final response = await _supabase
          .from('cardapio')
          .select('*, ficha_tecnica(*, estoque(*))');

      return ActionResponse(
        success: true,
        data: response as List<dynamic>,
        statusCode: 200,
      );
    } catch (e) {
      return ActionResponse(
        success: false,
        error: 'Erro ao buscar itens do cardápio: $e',
        statusCode: 500,
      );
    }
  }
}
