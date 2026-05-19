-- =========================================================================
-- SPRINT 2.2: KERNEL PRISMA V4.0 - ROW LEVEL SECURITY (RLS) E SEGURANÇA
-- Proteção total do banco de dados (Multitenancy por user_id)
-- =========================================================================

-- 1. Habilitar RLS em todas as tabelas geradas no Sprint 2.1
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fornecedores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.estoque ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cardapio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ficha_tecnica ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedido_itens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financeiro ENABLE ROW LEVEL SECURITY;

-- 2. Criação das Políticas de Acesso (Policies)
-- Regra Geral: Um usuário autenticado (auth.uid()) só pode visualizar, inserir, atualizar e deletar os dados onde o user_id for igual ao seu próprio UID.

-- PROFILES
CREATE POLICY "Users can manage their own profiles" 
ON public.profiles FOR ALL TO authenticated 
USING (auth.uid() = id) 
WITH CHECK (auth.uid() = id);

-- CLIENTES
CREATE POLICY "Users can manage their own clientes" 
ON public.clientes FOR ALL TO authenticated 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- FORNECEDORES
CREATE POLICY "Users can manage their own fornecedores" 
ON public.fornecedores FOR ALL TO authenticated 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- ESTOQUE (Insumos)
CREATE POLICY "Users can manage their own estoque" 
ON public.estoque FOR ALL TO authenticated 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- CARDÁPIO (Produtos Finais)
CREATE POLICY "Users can manage their own cardapio" 
ON public.cardapio FOR ALL TO authenticated 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- FICHA TÉCNICA
CREATE POLICY "Users can manage their own ficha_tecnica" 
ON public.ficha_tecnica FOR ALL TO authenticated 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- PEDIDOS
CREATE POLICY "Users can manage their own pedidos" 
ON public.pedidos FOR ALL TO authenticated 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- ITENS DO PEDIDO
-- O acesso aos itens do pedido é garantido verificando se o usuário é dono do pedido associado.
CREATE POLICY "Users can manage items for their own orders" 
ON public.pedido_itens FOR ALL TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM public.pedidos 
        WHERE pedidos.id = pedido_itens.pedido_id 
        AND pedidos.user_id = auth.uid()
    )
) 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.pedidos 
        WHERE pedidos.id = pedido_itens.pedido_id 
        AND pedidos.user_id = auth.uid()
    )
);

-- FINANCEIRO
CREATE POLICY "Users can manage their own financeiro" 
ON public.financeiro FOR ALL TO authenticated 
USING (auth.uid() = user_id) 
WITH CHECK (auth.uid() = user_id);

-- 3. Criação da Função RPC para Baixa de Estoque Transacional
-- Esta função é segura (SECURITY DEFINER) e roda sob a permissão do criador para deduzir o estoque sem requisições duplas do Client.
CREATE OR REPLACE FUNCTION processar_baixa_estoque_pedido(p_pedido_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    item RECORD;
BEGIN
    -- Obter o dono do pedido
    SELECT user_id INTO v_user_id FROM public.pedidos WHERE id = p_pedido_id;

    -- Garantir que quem chamou é o dono do pedido
    IF v_user_id != auth.uid() THEN
        RAISE EXCEPTION 'Acesso Negado';
    END IF;

    -- Iterar sobre todos os itens do pedido e buscar suas fichas técnicas
    FOR item IN 
        SELECT 
            ft.estoque_id, 
            (pi.quantidade * ft.quantidade_necessaria) as total_descontar
        FROM public.pedido_itens pi
        JOIN public.ficha_tecnica ft ON pi.cardapio_id = ft.cardapio_id
        WHERE pi.pedido_id = p_pedido_id
    LOOP
        -- Atualizar a quantidade no estoque do dono do item
        UPDATE public.estoque
        SET quantidade_atual = quantidade_atual - item.total_descontar,
            updated_at = NOW()
        WHERE id = item.estoque_id 
        AND user_id = v_user_id;
    END LOOP;
    
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Falha ao processar baixa de estoque: %', SQLERRM;
END;
$$;
