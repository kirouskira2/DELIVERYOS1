-- 1. Travar o search_path das funções de Data (Corrige Function Search Path Mutable)
DO $$ BEGIN
  ALTER FUNCTION public.update_updated_at() SET search_path = public;
EXCEPTION WHEN undefined_function THEN NULL; END $$;

DO $$ BEGIN
  ALTER FUNCTION public.atualiza_updated_at() SET search_path = public;
EXCEPTION WHEN undefined_function THEN NULL; END $$;

DO $$ BEGIN
  ALTER FUNCTION public.update_updated_at_column() SET search_path = public;
EXCEPTION WHEN undefined_function THEN NULL; END $$;

-- 2. Revogar privilégios do GraphQL para evitar a exposição do schema (Corrige pg_graphql_anon_table_exposed e authenticated)
-- Como não usamos o GraphQL, desativamos o acesso ao schema graphql por completo para as conexões cliente.
-- Isso satisfaz os linters de segurança sem quebrar as chamadas da API REST (PostgREST).
REVOKE ALL ON SCHEMA graphql FROM anon, authenticated;

-- 3. Revogar acesso de leitura pública (anon) das tabelas de negócio (Reforço de segurança)
-- Usuários não autenticados (anon) não devem ter privilégio de SELECT nestas tabelas.
REVOKE SELECT ON TABLE public.cardapio FROM anon;
REVOKE SELECT ON TABLE public.clientes FROM anon;
REVOKE SELECT ON TABLE public.estoque FROM anon;
REVOKE SELECT ON TABLE public.financeiro FROM anon;
REVOKE SELECT ON TABLE public.fornecedores FROM anon;
REVOKE SELECT ON TABLE public.pedido_itens FROM anon;
REVOKE SELECT ON TABLE public.pedidos FROM anon;
REVOKE SELECT ON TABLE public.profiles FROM anon;

-- 4. Deletar a tabela 'contacts' antiga que está furando o RLS (Corrige rls_policy_always_true)
DROP TABLE IF EXISTS public.contacts CASCADE;
