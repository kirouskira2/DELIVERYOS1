-- Migration 0005: Views para Dashboards, Relatórios e Segurança RLS
-- Implementa a lógica do Prisma V4: O banco de dados faz a agregação, não o cliente.

-- 1. View: Dashboard Principal (Métricas do dia)
CREATE OR REPLACE VIEW view_dashboard_diario AS
SELECT 
    COUNT(id) AS total_pedidos,
    COALESCE(SUM(valor_total), 0) AS receita_total,
    COALESCE(SUM(valor_total) / NULLIF(COUNT(id), 0), 0) AS ticket_medio,
    CURRENT_DATE AS data_referencia
FROM pedidos
WHERE DATE(created_at) = CURRENT_DATE;

-- 2. View: Top Sellers (Pratos mais vendidos)
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

-- 3. View: Evolução de Receita (Últimos 30 dias)
CREATE OR REPLACE VIEW view_evolucao_receita AS
SELECT 
    DATE(created_at) AS data,
    SUM(valor_total) AS receita
FROM pedidos
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY data ASC;

-- 4. View: Financeiro CMV vs Receita (Mensal)
CREATE OR REPLACE VIEW view_financeiro_mensal AS
SELECT 
    DATE_TRUNC('month', created_at) AS mes,
    SUM(CASE WHEN tipo = 'RECEITA' THEN valor ELSE 0 END) AS receita,
    SUM(CASE WHEN tipo = 'DESPESA' THEN valor ELSE 0 END) AS despesa_cmv
FROM financeiro
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY mes ASC;

-- 5. Atualização das Políticas de Segurança (RLS)
-- REVOGAR acesso direto para `anon` em tabelas críticas (forçando uso do Backend Dart Frog)
-- Obs: as views criadas acima herdam as permissões das tabelas base.

ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedido_itens ENABLE ROW LEVEL SECURITY;
ALTER TABLE financeiro ENABLE ROW LEVEL SECURITY;
ALTER TABLE estoque ENABLE ROW LEVEL SECURITY;

-- Permitir acesso apenas para o `service_role` (Backend Dart Frog) e usuários autenticados (opcionalmente)
-- Neste projeto, o Dart Frog usará o token autenticado ou service_role.
CREATE POLICY "Permitir leitura pelo backend" ON pedidos
    FOR SELECT TO authenticated, service_role USING (true);
CREATE POLICY "Permitir inserção pelo backend" ON pedidos
    FOR INSERT TO authenticated, service_role WITH CHECK (true);
CREATE POLICY "Permitir update pelo backend" ON pedidos
    FOR UPDATE TO authenticated, service_role USING (true);

-- Aplicando o mesmo para o financeiro
CREATE POLICY "Permitir acesso financeiro pelo backend" ON financeiro
    FOR ALL TO authenticated, service_role USING (true);

-- Grant das Views
GRANT SELECT ON view_dashboard_diario TO authenticated, service_role;
GRANT SELECT ON view_top_sellers TO authenticated, service_role;
GRANT SELECT ON view_evolucao_receita TO authenticated, service_role;
GRANT SELECT ON view_financeiro_mensal TO authenticated, service_role;
