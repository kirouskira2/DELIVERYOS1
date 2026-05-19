# Plano de Implementação - Supabase Integration

## 1. Validação de Conexão e Ambiente
- [x] Verificar URL do projeto Supabase via MCP.
- [x] Listar tabelas existentes para confirmar migrações anteriores.
- [x] Verificar usuários existentes no `auth.users`.

## 2. Gestão de Perfis e Permissões
- [x] Criar/Atualizar perfis na tabela `public.profiles` para todos os usuários do `auth.users`.
- [x] Definir o usuário `pedro.lucas96@hotmail.com` como **Administrador**.
- [x] Definir os demais usuários como **Caixa**.

## 3. Correções de Esquema e Views
- [x] Ajustar a `ForeignKey` de `pedidos.cliente_id` para `ON DELETE SET NULL` (permite excluir empresas B2B).
- [x] Criar a view `view_melhores_clientes_b2b` para relatórios de LTV.
- [x] Garantir `GRANT SELECT` nas novas views para os roles `authenticated` e `service_role`.

## 4. Popular Dados (Seed)
- [x] Inserir Clientes B2B de exemplo.
- [x] Inserir Fornecedores de exemplo.
- [x] Inserir Itens de Estoque (Arroz, Feijão).
- [x] Inserir Itens de Cardápio (Prato Feito, Marmita).
- [x] Inserir Pedidos e Itens de Pedido com datas retroativas para testar gráficos.
- [x] Inserir lançamentos Financeiros (Receitas e Despesas) para testar fluxo de caixa.

## 5. Verificação de Segurança (RLS)
- [x] Confirmar que RLS está habilitado em todas as tabelas.
- [x] Validar que as políticas permitem acesso baseado no `user_id`.
- [x] Validar que o backend (Dart Frog) possui acesso via `service_role` ou token autenticado.

## 6. Próximos Passos
- [ ] Testar a exclusão de um cliente B2B no Preview.
- [ ] Verificar se os gráficos de Dashboard e Relatórios exibem os dados inseridos.
- [ ] Validar exportação de PDF com os dados reais.
