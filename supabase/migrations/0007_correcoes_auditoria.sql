-- Migration 0007: Correções Críticas de Auditoria (View & RPC)

-- 1. Recriação da View de Top Sellers com a chave estrangeira correta (cardapio_id)
CREATE OR REPLACE VIEW view_top_sellers AS
SELECT 
    c.nome,
    COUNT(pi.id) AS quantidade_pedida,
    SUM(pi.quantidade) AS total_itens
FROM pedido_itens pi
JOIN cardapio c ON pi.cardapio_id = c.id
GROUP BY c.nome
ORDER BY quantidade_pedida DESC
LIMIT 10;

-- 2. Limpeza prévia para evitar conflito de assinatura
DROP FUNCTION IF EXISTS public.get_low_stock_items();

-- 3. Criação da RPC get_low_stock_items para Alertas de Estoque Mínimo no nível do Tenant logado
CREATE OR REPLACE FUNCTION public.get_low_stock_items()
RETURNS TABLE (
    id UUID,
    nome_item VARCHAR,
    unidade_medida VARCHAR,
    quantidade_atual DECIMAL,
    quantidade_minima DECIMAL,
    custo_unitario DECIMAL,
    categoria VARCHAR,
    fornecedor_id UUID,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id, 
        e.nome_item, 
        e.unidade_medida, 
        e.quantidade_atual, 
        e.quantidade_minima, 
        e.custo_unitario, 
        e.categoria, 
        e.fornecedor_id,
        e.created_at, 
        e.updated_at
    FROM public.estoque e
    WHERE e.user_id = auth.uid()
      AND e.quantidade_atual <= e.quantidade_minima;
END;
$$;

-- Permissões de Execução para a nova RPC
GRANT EXECUTE ON FUNCTION public.get_low_stock_items() TO authenticated, service_role;
