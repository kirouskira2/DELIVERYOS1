-- Migration 0008: Security Audit Fixes & Best Practices

-- ==============================================================================
-- 1. SECURITY DEFINER VIEWS
-- Corrigindo views para operarem com os privilégios de quem as consulta (Invoker)
-- ==============================================================================
ALTER VIEW public.view_financeiro_mensal SET (security_invoker = true);
ALTER VIEW public.view_top_sellers SET (security_invoker = true);
ALTER VIEW public.view_melhores_clientes_b2b SET (security_invoker = true);
ALTER VIEW public.view_evolucao_receita SET (security_invoker = true);
ALTER VIEW public.view_dashboard_diario SET (security_invoker = true);


-- ==============================================================================
-- 2. FUNCTION SEARCH PATH & PUBLIC EXECUTION
-- Setando search_path explicitamente e bloqueando a role 'anon' de executá-las
-- ==============================================================================
ALTER FUNCTION public.processar_baixa_estoque_pedido(uuid) SET search_path = public;
REVOKE EXECUTE ON FUNCTION public.processar_baixa_estoque_pedido(uuid) FROM PUBLIC;

ALTER FUNCTION public.calcular_cmv_periodo(timestamp with time zone, timestamp with time zone) SET search_path = public;
REVOKE EXECUTE ON FUNCTION public.calcular_cmv_periodo(timestamp with time zone, timestamp with time zone) FROM PUBLIC;

ALTER FUNCTION public.get_low_stock_items() SET search_path = public;
REVOKE EXECUTE ON FUNCTION public.get_low_stock_items() FROM PUBLIC;


-- ==============================================================================
-- 3. PERMISSIVE RLS POLICIES
-- Excluindo políticas que usam USING (true) e abriam brechas para o backend.
-- O backend (Dart Frog) deve usar a chave Service Role que já bypassa RLS.
-- ==============================================================================
DROP POLICY IF EXISTS "Permitir acesso financeiro pelo backend" ON public.financeiro;
DROP POLICY IF EXISTS "Permitir inserção pelo backend" ON public.pedidos;
DROP POLICY IF EXISTS "Permitir update pelo backend" ON public.pedidos;


-- ==============================================================================
-- 4. PUBLIC ANON DATA EXPOSURE
-- Revogando acesso de leitura público (anon) a dados que deveriam ser restritos
-- ==============================================================================
REVOKE SELECT ON public.ficha_tecnica FROM anon;
REVOKE SELECT ON public.view_dashboard_diario FROM anon;
REVOKE SELECT ON public.view_evolucao_receita FROM anon;
REVOKE SELECT ON public.view_financeiro_mensal FROM anon;
REVOKE SELECT ON public.view_melhores_clientes_b2b FROM anon;
REVOKE SELECT ON public.view_top_sellers FROM anon;
