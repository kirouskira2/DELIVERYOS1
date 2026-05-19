/// Modelo de domínio para a entidade Pedido.
/// Reflete todos os campos da tabela `public.pedidos` no Supabase.
class Pedido {
  const Pedido({
    required this.id,
    required this.userId,
    required this.status,
    required this.tipo,
    required this.valorTotal,
    required this.createdAt,
    this.clienteId,
    this.observacoes,
    this.updatedAt,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      clienteId: json['cliente_id'] as String?,
      status: json['status'] as String,
      tipo: json['tipo'] as String,
      valorTotal: (json['valor_total'] as num).toDouble(),
      observacoes: json['observacoes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
  final String id;
  final String userId;
  final String? clienteId;
  final String status;
  final String tipo;
  final double valorTotal;
  final String? observacoes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'cliente_id': clienteId,
      'status': status,
      'tipo': tipo,
      'valor_total': valorTotal,
      'observacoes': observacoes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'Pedido(id: $id, status: $status, tipo: $tipo, valorTotal: $valorTotal)';
}
