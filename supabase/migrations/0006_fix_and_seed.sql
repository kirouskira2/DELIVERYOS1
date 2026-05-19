-- Fix ForeignKey for pedidos.cliente_id to allow deletion of clients (B2B)
ALTER TABLE public.pedidos DROP CONSTRAINT IF EXISTS pedidos_cliente_id_fkey;
ALTER TABLE public.pedidos ADD CONSTRAINT pedidos_cliente_id_fkey 
  FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON DELETE SET NULL;

-- View para Melhores Clientes B2B
CREATE OR REPLACE VIEW view_melhores_clientes_b2b AS
SELECT 
    c.nome_empresa AS nome,
    SUM(p.valor_total) AS total_gasto
FROM clientes c
JOIN pedidos p ON p.cliente_id = c.id
WHERE p.status = 'concluido'
GROUP BY c.id, c.nome_empresa
ORDER BY total_gasto DESC
LIMIT 5;

GRANT SELECT ON view_melhores_clientes_b2b TO authenticated, service_role;

-- ----------------------------------------------------
-- SEED DATA (Mock data for real usage reflection)
-- ----------------------------------------------------
DO $$ 
DECLARE
    v_user_id UUID;
    v_cliente_id UUID;
    v_forn_id UUID;
    v_est1 UUID;
    v_est2 UUID;
    v_card1 UUID;
    v_card2 UUID;
    v_ped1 UUID;
    v_ped2 UUID;
BEGIN
    -- Get the first user (admin)
    SELECT id INTO v_user_id FROM auth.users LIMIT 1;
    
    IF v_user_id IS NOT NULL THEN
        -- Insert Clientes B2B
        INSERT INTO public.clientes (user_id, nome_empresa, cnpj, contrato_ativo)
        VALUES 
            (v_user_id, 'Tech Corp', '11.111.111/0001-11', true),
            (v_user_id, 'Escola ABC', '22.222.222/0001-22', true),
            (v_user_id, 'Empresa XPTO', '33.333.333/0001-33', false)
        RETURNING id INTO v_cliente_id;
        
        -- Insert Fornecedores
        INSERT INTO public.fornecedores (user_id, nome, categoria)
        VALUES (v_user_id, 'Distribuidora de Alimentos SA', 'Geral')
        RETURNING id INTO v_forn_id;
        
        -- Insert Estoque
        INSERT INTO public.estoque (user_id, nome_item, unidade_medida, quantidade_atual, fornecedor_id, custo_unitario)
        VALUES 
            (v_user_id, 'Arroz 5kg', 'Pacote', 50, v_forn_id, 20.00) RETURNING id INTO v_est1;
        INSERT INTO public.estoque (user_id, nome_item, unidade_medida, quantidade_atual, fornecedor_id, custo_unitario)
        VALUES 
            (v_user_id, 'Feijão 1kg', 'Pacote', 30, v_forn_id, 8.00) RETURNING id INTO v_est2;
            
        -- Insert Cardapio
        INSERT INTO public.cardapio (user_id, nome, preco_venda, custo_producao, categoria)
        VALUES 
            (v_user_id, 'Prato Feito', 25.00, 8.00, 'Refeições') RETURNING id INTO v_card1;
        INSERT INTO public.cardapio (user_id, nome, preco_venda, custo_producao, categoria)
        VALUES 
            (v_user_id, 'Marmita Média', 20.00, 6.00, 'Refeições') RETURNING id INTO v_card2;
            
        -- Insert Pedidos (Historico dos ultimos 3 meses para gráficos)
        -- Pedido 1
        INSERT INTO public.pedidos (user_id, cliente_id, status, tipo, valor_total, created_at)
        VALUES (v_user_id, v_cliente_id, 'concluido', 'balcao', 50.00, NOW() - INTERVAL '2 days') RETURNING id INTO v_ped1;
        
        INSERT INTO public.pedido_itens (pedido_id, cardapio_id, quantidade, preco_unitario)
        VALUES (v_ped1, v_card1, 2, 25.00);
        
        -- Pedido 2
        INSERT INTO public.pedidos (user_id, cliente_id, status, tipo, valor_total, created_at)
        VALUES (v_user_id, NULL, 'concluido', 'delivery', 20.00, NOW() - INTERVAL '5 days') RETURNING id INTO v_ped2;
        
        INSERT INTO public.pedido_itens (pedido_id, cardapio_id, quantidade, preco_unitario)
        VALUES (v_ped2, v_card2, 1, 20.00);
        
        -- Insert Financeiro (Receitas e Despesas)
        INSERT INTO public.financeiro (user_id, tipo, descricao, valor, data_transacao, pedido_id, created_at)
        VALUES 
            (v_user_id, 'RECEITA', 'Venda Pedido 1', 50.00, CURRENT_DATE - 2, v_ped1, NOW() - INTERVAL '2 days'),
            (v_user_id, 'RECEITA', 'Venda Pedido 2', 20.00, CURRENT_DATE - 5, v_ped2, NOW() - INTERVAL '5 days'),
            (v_user_id, 'DESPESA', 'Compra de Insumos', 150.00, CURRENT_DATE - 10, NULL, NOW() - INTERVAL '10 days'),
            (v_user_id, 'DESPESA', 'Aluguel', 2000.00, CURRENT_DATE - 15, NULL, NOW() - INTERVAL '15 days');
    END IF;
END $$;