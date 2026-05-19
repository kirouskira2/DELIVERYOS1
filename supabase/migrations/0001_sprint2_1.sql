-- =========================================================================
-- SPRINT 2.1: KERNEL PRISMA V4.0 - TABELAS, RELACIONAMENTOS E ENUMS
-- Baseado no legado do Delivery OS, otimizado para o novo ecossistema Next.js
-- =========================================================================

-- 1. Habilitar extensões
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Criação de Enums (Domínios de Dados)
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('admin', 'caixa', 'cozinha');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE status_pedido AS ENUM ('novo', 'preparando', 'pronto', 'concluido', 'cancelado');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE tipo_pedido AS ENUM ('mesa', 'balcao', 'delivery');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE tipo_financeiro AS ENUM ('RECEITA', 'DESPESA');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. Tabelas Base (Com suporte a múltiplos perfis e isolamento)

-- Tabela de Perfis estendendo auth.users
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    role user_role DEFAULT 'admin',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de Clientes
CREATE TABLE IF NOT EXISTS public.clientes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
    nome_empresa VARCHAR(255) NOT NULL,
    cnpj VARCHAR(20),
    contato_nome VARCHAR(100),
    email VARCHAR(255),
    telefone VARCHAR(20),
    endereco TEXT,
    contrato_ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de Fornecedores
CREATE TABLE IF NOT EXISTS public.fornecedores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
    nome VARCHAR(255) NOT NULL,
    categoria VARCHAR(100),
    contato VARCHAR(100),
    telefone VARCHAR(20),
    dias_entrega VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de Estoque (Insumos)
CREATE TABLE IF NOT EXISTS public.estoque (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
    nome_item VARCHAR(255) NOT NULL,
    categoria VARCHAR(100),
    unidade_medida VARCHAR(20),
    quantidade_atual DECIMAL(10, 3) DEFAULT 0,
    quantidade_minima DECIMAL(10, 3) DEFAULT 0,
    custo_unitario DECIMAL(10, 2) DEFAULT 0,
    fornecedor_id UUID REFERENCES public.fornecedores(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de Cardápio (Produtos Finais)
CREATE TABLE IF NOT EXISTS public.cardapio (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
    nome VARCHAR(255) NOT NULL,
    descricao TEXT,
    categoria VARCHAR(100),
    preco_venda DECIMAL(10, 2) NOT NULL,
    custo_producao DECIMAL(10, 2) DEFAULT 0,
    disponivel BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de Ficha Técnica (Relacionamento Cardápio <-> Estoque)
CREATE TABLE IF NOT EXISTS public.ficha_tecnica (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
    cardapio_id UUID NOT NULL REFERENCES public.cardapio(id) ON DELETE CASCADE,
    estoque_id UUID NOT NULL REFERENCES public.estoque(id) ON DELETE CASCADE,
    quantidade_necessaria DECIMAL(10, 3) NOT NULL CHECK (quantidade_necessaria > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(cardapio_id, estoque_id)
);

-- Tabela de Pedidos
CREATE TABLE IF NOT EXISTS public.pedidos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
    cliente_id UUID REFERENCES public.clientes(id) ON DELETE RESTRICT,
    status status_pedido DEFAULT 'novo',
    tipo tipo_pedido DEFAULT 'balcao',
    valor_total DECIMAL(10, 2) DEFAULT 0,
    observacoes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de Itens do Pedido
CREATE TABLE IF NOT EXISTS public.pedido_itens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pedido_id UUID NOT NULL REFERENCES public.pedidos(id) ON DELETE CASCADE,
    cardapio_id UUID NOT NULL REFERENCES public.cardapio(id) ON DELETE RESTRICT,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabela de Financeiro
CREATE TABLE IF NOT EXISTS public.financeiro (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
    tipo tipo_financeiro NOT NULL,
    categoria VARCHAR(100),
    descricao VARCHAR(255) NOT NULL,
    valor DECIMAL(10, 2) NOT NULL,
    data_transacao DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(50) DEFAULT 'pago',
    pedido_id UUID REFERENCES public.pedidos(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Função Automática de Updated At
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para Updated At
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_clientes_updated_at BEFORE UPDATE ON clientes FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_fornecedores_updated_at BEFORE UPDATE ON fornecedores FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_estoque_updated_at BEFORE UPDATE ON estoque FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_cardapio_updated_at BEFORE UPDATE ON cardapio FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_pedidos_updated_at BEFORE UPDATE ON pedidos FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
