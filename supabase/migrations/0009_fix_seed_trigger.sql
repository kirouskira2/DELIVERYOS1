-- Migration 0009: Fix seed trigger for new users
-- Corrige a trigger de sementes (seed) ao criar novo usuário para evitar que retorne multiplas linhas na atribuição da variável de ID de cliente.

CREATE OR REPLACE FUNCTION public.seed_new_user_data()
RETURNS TRIGGER AS $$
DECLARE
    v_cliente_id UUID;
    v_forn_id UUID;
    v_est1 UUID;
    v_est2 UUID;
    v_card1 UUID;
    v_card2 UUID;
    v_ped1 UUID;
    v_ped2 UUID;
BEGIN
    -- 1. Insert Clientes B2B (Inseridos individualmente para obter o ID de Tech Corp em v_cliente_id)
    INSERT INTO public.clientes (user_id, nome_empresa, cnpj, contrato_ativo)
    VALUES (NEW.id, 'Tech Corp (Demo)', '11.111.111/0001-11', true)
    RETURNING id INTO v_cliente_id;

    INSERT INTO public.clientes (user_id, nome_empresa, cnpj, contrato_ativo)
    VALUES (NEW.id, 'Escola ABC (Demo)', '22.222.222/0001-22', true);
    
    -- 2. Insert Fornecedores
    INSERT INTO public.fornecedores (user_id, nome, categoria)
    VALUES (NEW.id, 'Distribuidora de Alimentos SA (Demo)', 'Geral')
    RETURNING id INTO v_forn_id;
    
    -- 3. Insert Estoque
    INSERT INTO public.estoque (user_id, nome_item, unidade_medida, quantidade_atual, quantidade_minima, fornecedor_id, custo_unitario)
    VALUES (NEW.id, 'Arroz 5kg', 'Pacote', 50, 10, v_forn_id, 20.00) RETURNING id INTO v_est1;

    INSERT INTO public.estoque (user_id, nome_item, unidade_medida, quantidade_atual, quantidade_minima, fornecedor_id, custo_unitario)
    VALUES (NEW.id, 'Feijão 1kg', 'Pacote', 30, 5, v_forn_id, 8.00) RETURNING id INTO v_est2;
        
    -- 4. Insert Cardapio
    INSERT INTO public.cardapio (user_id, nome, preco_venda, custo_producao, categoria, disponivel)
    VALUES (NEW.id, 'Prato Feito', 25.00, 8.00, 'Refeições', true) RETURNING id INTO v_card1;

    INSERT INTO public.cardapio (user_id, nome, preco_venda, custo_producao, categoria, disponivel)
    VALUES (NEW.id, 'Marmita Média', 20.00, 6.00, 'Refeições', true) RETURNING id INTO v_card2;
        
    -- 5. Ficha Tecnica
    INSERT INTO public.ficha_tecnica (user_id, cardapio_id, estoque_id, quantidade_necessaria)
    VALUES 
        (NEW.id, v_card1, v_est1, 0.2),
        (NEW.id, v_card1, v_est2, 0.1),
        (NEW.id, v_card2, v_est1, 0.15);

    -- 6. Insert Pedidos (Historico para os gráficos)
    INSERT INTO public.pedidos (user_id, cliente_id, status, tipo, valor_total, created_at)
    VALUES (NEW.id, v_cliente_id, 'concluido', 'balcao', 50.00, NOW() - INTERVAL '2 days') RETURNING id INTO v_ped1;
    
    INSERT INTO public.pedido_itens (pedido_id, cardapio_id, quantidade, preco_unitario)
    VALUES (v_ped1, v_card1, 2, 25.00);
    
    INSERT INTO public.pedidos (user_id, cliente_id, status, tipo, valor_total, created_at)
    VALUES (NEW.id, NULL, 'concluido', 'delivery', 20.00, NOW() - INTERVAL '5 days') RETURNING id INTO v_ped2;
    
    INSERT INTO public.pedido_itens (pedido_id, cardapio_id, quantidade, preco_unitario)
    VALUES (v_ped2, v_card2, 1, 20.00);
    
    -- 7. Insert Financeiro (Receitas e Despesas para fechar CMV e Margem)
    INSERT INTO public.financeiro (user_id, tipo, descricao, valor, data_transacao, pedido_id, created_at)
    VALUES 
        (NEW.id, 'RECEITA', 'Venda Pedido 1', 50.00, CURRENT_DATE - 2, v_ped1, NOW() - INTERVAL '2 days'),
        (NEW.id, 'RECEITA', 'Venda Pedido 2', 20.00, CURRENT_DATE - 5, v_ped2, NOW() - INTERVAL '5 days'),
        (NEW.id, 'DESPESA', 'Compra de Insumos', 150.00, CURRENT_DATE - 10, NULL, NOW() - INTERVAL '10 days'),
        (NEW.id, 'DESPESA', 'Aluguel', 2000.00, CURRENT_DATE - 15, NULL, NOW() - INTERVAL '15 days');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
