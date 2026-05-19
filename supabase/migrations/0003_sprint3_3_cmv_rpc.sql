-- =========================================================================
-- SPRINT 3.3: KERNEL PRISMA V4.0 - RPC DE CÁLCULO DO CMV
-- Pendência identificada na auditoria do DashboardService.
-- =========================================================================

-- Função RPC: calcular_cmv_periodo
-- Calcula o Custo da Mercadoria Vendida (CMV) de um período específico.
-- Lógica: Para cada item vendido (pedido_itens), busca sua ficha técnica
-- e multiplica a quantidade_necessaria * custo_unitario do insumo (estoque).
-- Roda com SECURITY DEFINER para garantir acesso seguro entre tabelas.

CREATE OR REPLACE FUNCTION calcular_cmv_periodo(
    p_data_inicio TIMESTAMP WITH TIME ZONE,
    p_data_fim    TIMESTAMP WITH TIME ZONE
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_cmv_total NUMERIC := 0;
BEGIN
    SELECT
        COALESCE(
            SUM(
                pi.quantidade           -- Quantidade de pratos vendidos
                * ft.quantidade_necessaria  -- Insumo necessário por prato
                * e.custo_unitario          -- Custo atual do insumo
            ),
            0
        )
    INTO v_cmv_total
    FROM public.pedido_itens pi
    -- Vincula o item do pedido ao pedido principal (para filtro por data e status)
    JOIN public.pedidos p
        ON p.id = pi.pedido_id
    -- Vincula ao item do cardápio com sua ficha técnica
    JOIN public.ficha_tecnica ft
        ON ft.cardapio_id = pi.cardapio_id
    -- Vincula ao insumo do estoque para pegar o custo unitário
    JOIN public.estoque e
        ON e.id = ft.estoque_id
    WHERE
        p.status = 'concluido'
        AND p.user_id = auth.uid()   -- Isolamento por usuário (Multitenancy)
        AND p.created_at >= p_data_inicio
        AND p.created_at <= p_data_fim;

    RETURN v_cmv_total;
END;
$$;
