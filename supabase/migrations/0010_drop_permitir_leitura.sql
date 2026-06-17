-- Migration 0010: Drop "Permitir leitura pelo backend" policy on pedidos
-- Remove a política residual que permitia que qualquer usuário visualizasse pedidos de outros inquilinos (quebrando o isolamento de dados / multi-tenancy).
-- Agora os usuários autenticados só visualizam e gerenciam seus próprios pedidos, garantindo que a exclusão funcione devidamente apenas para o dono.

DROP POLICY IF EXISTS "Permitir leitura pelo backend" ON public.pedidos;
