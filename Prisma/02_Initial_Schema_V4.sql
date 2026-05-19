-- ARQUIVO: docs/02_Initial_Schema_V4.sql
-- DESCRIÇÃO: Schema completo do banco de dados Prisma AI (V4 Hybrid Architecture)
-- Inclui suporte para Gerador de SaaS (V3), Plataforma de Governança (V4) e Analytics.
-- VERSÃO: 4.1 (Enterprise Edition - Otimizada)

-- ============================================================================
-- 1. HABILITAR EXTENSÕES
-- ============================================================================
create extension if not exists vector; -- Para RAG interno e futuro uso
create extension if not exists "uuid-ossp"; -- Para geração de UUIDs

-- ============================================================================
-- 2. TIPOS ENUM (Definições do Domínio)
-- ============================================================================
create type project_status as enum ('draft', 'submitted', 'processing', 'completed', 'error');
create type artifact_type as enum ('plano_implementacao', 'script_sql', 'openapi_spec', 'gherkin_scenarios', 'relatorio_validacao');
create type subscription_plan as enum ('free', 'pro', 'enterprise');
create type agent_status as enum ('active', 'training', 'paused', 'error');
create type audit_decision as enum ('approved', 'rejected', 'escalated');

-- ============================================================================
-- 3. TABELAS CORE
-- ============================================================================

-- Tabela de Usuários (Espelho do Auth do Supabase)
create table public.users (
  id uuid references auth.users not null primary key,
  email text not null unique,
  subscription_plan subscription_plan default 'free',
  created_at timestamptz default now(),
  
  constraint email_format 
    check (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);
comment on table public.users is 'Usuários da plataforma (sincronizado com Supabase Auth)';

-- Tabela de Configuração de Projetos (O "Briefing")
create table public.project_configurations (
  id uuid default gen_random_uuid() primary key,
  owner_user_id uuid references public.users(id) on delete cascade not null,
  project_name text not null,
  project_context jsonb not null, -- { industry, targetAudience, problemStatement }
  entities_definition jsonb,      -- Definição do modelo de dados do cliente
  features_definition jsonb,      -- Funcionalidades e critérios Gherkin
  roles_definition jsonb,         -- Papéis e permissões
  adaptive_answers jsonb,         -- Respostas sobre compliance/segurança (Define o Target)
  status project_status default 'draft',
  target_architecture text default 'V3.1', -- 'V3.1' (SaaS) ou 'V4' (BPA)
  deleted_at timestamptz,         -- Para soft delete
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  
  constraint project_name_not_empty 
    check (length(trim(project_name)) > 0)
);
comment on table public.project_configurations is 'Configurações de projetos (briefing do cliente)';
comment on column public.project_configurations.target_architecture is 'V3.1 para SaaS, V4 para BPA/Governança';

-- Tabela de Artefatos Gerados (O "Produto" da Fábrica)
create table public.generated_artifacts (
  id uuid default gen_random_uuid() primary key,
  project_config_id uuid references public.project_configurations(id) on delete cascade not null,
  artifact_type artifact_type not null,
  content text not null, -- O conteúdo do arquivo (SQL, MD, JSON)
  version text default '1.0',
  created_at timestamptz default now(),
  
  constraint version_format 
    check (version ~ '^\d+\.\d+(\.\d+)?$')
);
comment on table public.generated_artifacts is 'Artefatos gerados pela fábrica de software';

-- ============================================================================
-- 4. TABELAS DE GOVERNANÇA V4
-- ============================================================================

-- Tabela de Agentes de Política (Microsserviços gerenciados)
create table public.policy_agents (
  id uuid default gen_random_uuid() primary key,
  project_config_id uuid references public.project_configurations(id) on delete cascade not null,
  name text not null, -- ex: "Agente de Aprovação Financeira"
  description text,
  status agent_status default 'active',
  system_prompt text, -- O prompt base que define a persona do agente
  knowledge_base_id text, -- ID da base de conhecimento no Google File Search API
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
comment on table public.policy_agents is 'Agentes de política para governança V4';

-- Tabela de Logs de Auditoria (Audit Trail - O valor central da V4)
create table public.audit_logs (
  id uuid default gen_random_uuid() primary key,
  policy_agent_id uuid references public.policy_agents(id) on delete cascade not null,
  triggered_by_user_id uuid references public.users(id), -- Quem iniciou a ação
  input_context jsonb not null, -- O dado que foi avaliado
  decision audit_decision not null,
  reasoning_text text, -- A explicação da IA
  citation_metadata jsonb, -- { file_name: "regras.pdf", page: 5, snippet: "..." }
  latency_ms integer,
  tokens_used integer,
  created_at timestamptz default now(),
  
  constraint latency_positive 
    check (latency_ms is null or latency_ms >= 0),
  constraint tokens_positive 
    check (tokens_used is null or tokens_used >= 0)
);
comment on table public.audit_logs is 'Logs de auditoria com rastreamento completo';
comment on column public.audit_logs.citation_metadata is 'Metadados de citação (arquivo, página, snippet)';

-- ============================================================================
-- 5. TABELA DE MÉTRICAS DE USO (Billing e Monitoring)
-- ============================================================================

create table public.usage_metrics (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users(id) on delete cascade not null,
  project_config_id uuid references public.project_configurations(id) on delete set null,
  operation_type text not null, -- 'generation', 'audit', 'query'
  tokens_consumed integer not null default 0,
  cost_usd numeric(10,4),
  metadata jsonb, -- Dados adicionais (modelo usado, endpoint, etc)
  created_at timestamptz default now()
);
comment on table public.usage_metrics is 'Métricas de uso para billing e monitoring';

-- ============================================================================
-- 6. ÍNDICES PARA PERFORMANCE
-- ============================================================================

-- Índices em users
create index idx_users_subscription on public.users(subscription_plan);

-- Índices em project_configurations
create index idx_project_configs_owner on public.project_configurations(owner_user_id);
create index idx_project_configs_status on public.project_configurations(status);
create index idx_project_configs_target_arch on public.project_configurations(target_architecture);
create index idx_project_configs_deleted on public.project_configurations(deleted_at) 
  where deleted_at is null; -- Índice parcial para consultas ativas

-- [NOVO] Índice GIN para Triagem Arquitetural Rápida (V4)
create index idx_project_adaptive_answers on public.project_configurations using gin(adaptive_answers);

-- Índices em generated_artifacts
create index idx_artifacts_project on public.generated_artifacts(project_config_id);
create index idx_artifacts_type on public.generated_artifacts(artifact_type);
create index idx_artifacts_created on public.generated_artifacts(created_at desc);

-- Índices em policy_agents
create index idx_policy_agents_project on public.policy_agents(project_config_id);
create index idx_policy_agents_status on public.policy_agents(status);

-- Índices em audit_logs
create index idx_audit_logs_agent on public.audit_logs(policy_agent_id);
create index idx_audit_logs_created on public.audit_logs(created_at desc);
create index idx_audit_logs_decision on public.audit_logs(decision);
create index idx_audit_logs_user on public.audit_logs(triggered_by_user_id);
create index idx_audit_logs_citations on public.audit_logs using gin(citation_metadata);

-- Índices em usage_metrics
create index idx_usage_metrics_user on public.usage_metrics(user_id);
create index idx_usage_metrics_created on public.usage_metrics(created_at desc);
create index idx_usage_metrics_operation on public.usage_metrics(operation_type);

-- ============================================================================
-- 7. TRIGGERS AUTOMÁTICOS
-- ============================================================================

-- Função para atualizar updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Trigger em project_configurations
create trigger set_updated_at_project_configs
  before update on public.project_configurations
  for each row execute function update_updated_at_column();

-- Trigger em policy_agents
create trigger set_updated_at_policy_agents
  before update on public.policy_agents
  for each row execute function update_updated_at_column();

-- ============================================================================
-- 8. SEGURANÇA (RLS - Row Level Security)
-- ============================================================================

alter table public.users enable row level security;
alter table public.project_configurations enable row level security;
alter table public.generated_artifacts enable row level security;
alter table public.policy_agents enable row level security;
alter table public.audit_logs enable row level security;
alter table public.usage_metrics enable row level security;

-- Políticas para users
create policy "Users can view own profile" on public.users
  for select using (auth.uid() = id);

-- Políticas para project_configurations
create policy "Users can view own projects" on public.project_configurations
  for select using (auth.uid() = owner_user_id);

create policy "Users can insert own projects" on public.project_configurations
  for insert with check (auth.uid() = owner_user_id);

create policy "Users can update own projects" on public.project_configurations
  for update using (auth.uid() = owner_user_id);

create policy "Users can delete own projects" on public.project_configurations
  for delete using (auth.uid() = owner_user_id);

-- Políticas para generated_artifacts
create policy "Users can view artifacts of own projects" on public.generated_artifacts
  for select using (
    exists (
      select 1 from public.project_configurations p 
      where p.id = generated_artifacts.project_config_id 
      and p.owner_user_id = auth.uid()
    )
  );

create policy "Users can insert artifacts of own projects" on public.generated_artifacts
  for insert with check (
    exists (
      select 1 from public.project_configurations p 
      where p.id = generated_artifacts.project_config_id 
      and p.owner_user_id = auth.uid()
    )
  );

create policy "Users can update artifacts of own projects" on public.generated_artifacts
  for update using (
    exists (
      select 1 from public.project_configurations p 
      where p.id = generated_artifacts.project_config_id 
      and p.owner_user_id = auth.uid()
    )
  );

create policy "Users can delete artifacts of own projects" on public.generated_artifacts
  for delete using (
    exists (
      select 1 from public.project_configurations p 
      where p.id = generated_artifacts.project_config_id 
      and p.owner_user_id = auth.uid()
    )
  );

-- Políticas para policy_agents
create policy "Users can view own agents" on public.policy_agents
  for select using (
    exists (
      select 1 from public.project_configurations p 
      where p.id = policy_agents.project_config_id 
      and p.owner_user_id = auth.uid()
    )
  );

create policy "Users can insert own agents" on public.policy_agents
  for insert with check (
    exists (
      select 1 from public.project_configurations p 
      where p.id = policy_agents.project_config_id 
      and p.owner_user_id = auth.uid()
    )
  );

create policy "Users can update own agents" on public.policy_agents
  for update using (
    exists (
      select 1 from public.project_configurations p 
      where p.id = policy_agents.project_config_id 
      and p.owner_user_id = auth.uid()
    )
  );

create policy "Users can delete own agents" on public.policy_agents
  for delete using (
    exists (
      select 1 from public.project_configurations p 
      where p.id = policy_agents.project_config_id 
      and p.owner_user_id = auth.uid()
    )
  );

-- Políticas para audit_logs
create policy "Users can view audit logs of own agents" on public.audit_logs
  for select using (
    exists (
      select 1 from public.policy_agents a
      join public.project_configurations p on p.id = a.project_config_id
      where a.id = audit_logs.policy_agent_id 
      and p.owner_user_id = auth.uid()
    )
  );

-- Políticas para usage_metrics
create policy "Users can view own usage" on public.usage_metrics
  for select using (auth.uid() = user_id);

-- ============================================================================
-- 9. VIEWS ÚTEIS (Analytics e Dashboards)
-- ============================================================================

-- View: Projetos ativos com contagem de artefatos
create or replace view public.v_active_projects as
select 
  pc.id,
  pc.project_name,
  pc.status,
  pc.target_architecture,
  pc.created_at,
  pc.updated_at,
  count(distinct ga.id) as total_artifacts,
  count(distinct pa.id) as total_agents
from public.project_configurations pc
left join public.generated_artifacts ga on ga.project_config_id = pc.id
left join public.policy_agents pa on pa.project_config_id = pc.id
where pc.deleted_at is null
group by pc.id, pc.project_name, pc.status, pc.target_architecture, pc.created_at, pc.updated_at;

-- View: Métricas de auditoria por agente
create or replace view public.v_agent_audit_summary as
select 
  pa.id as agent_id,
  pa.name as agent_name,
  pa.project_config_id,
  count(al.id) as total_audits,
  count(case when al.decision = 'approved' then 1 end) as approved_count,
  count(case when al.decision = 'rejected' then 1 end) as rejected_count,
  count(case when al.decision = 'escalated' then 1 end) as escalated_count,
  avg(al.latency_ms) as avg_latency_ms,
  sum(al.tokens_used) as total_tokens_used
from public.policy_agents pa
left join public.audit_logs al on al.policy_agent_id = pa.id
group by pa.id, pa.name, pa.project_config_id;

-- View: Resumo de uso por usuário
create or replace view public.v_user_usage_summary as
select 
  u.id as user_id,
  u.email,
  u.subscription_plan,
  count(distinct pc.id) as total_projects,
  count(distinct ga.id) as total_artifacts,
  sum(um.tokens_consumed) as total_tokens,
  sum(um.cost_usd) as total_cost_usd
from public.users u
left join public.project_configurations pc on pc.owner_user_id = u.id
left join public.generated_artifacts ga on ga.project_config_id = pc.id
left join public.usage_metrics um on um.user_id = u.id
group by u.id, u.email, u.subscription_plan;

-- ============================================================================
-- 10. FUNÇÕES AUXILIARES
-- ============================================================================

-- Função: Soft delete de projetos
create or replace function soft_delete_project(project_id uuid)
returns void as $$
begin
  update public.project_configurations
  set deleted_at = now()
  where id = project_id
  and owner_user_id = auth.uid();
end;
$$ language plpgsql security definer;

-- Função: Restaurar projeto deletado
create or replace function restore_project(project_id uuid)
returns void as $$
begin
  update public.project_configurations
  set deleted_at = null
  where id = project_id
  and owner_user_id = auth.uid();
end;
$$ language plpgsql security definer;

-- Função: Calcular custo total do usuário no mês
create or replace function get_user_monthly_cost(
  user_uuid uuid, 
  month_date date default current_date
)
returns numeric as $$
declare
  total_cost numeric;
begin
  select coalesce(sum(cost_usd), 0)
  into total_cost
  from public.usage_metrics
  where user_id = user_uuid
  and created_at >= date_trunc('month', month_date)
  and created_at < date_trunc('month', month_date) + interval '1 month';
  
  return total_cost;
end;
$$ language plpgsql security definer;

-- Função: Obter estatísticas de auditoria de um projeto
create or replace function get_project_audit_stats(project_id uuid)
returns table (
  total_audits bigint,
  approved_count bigint,
  rejected_count bigint,
  escalated_count bigint,
  avg_latency numeric
) as $$
begin
  return query
  select 
    count(al.id) as total_audits,
    count(case when al.decision = 'approved' then 1 end) as approved_count,
    count(case when al.decision = 'rejected' then 1 end) as rejected_count,
    count(case when al.decision = 'escalated' then 1 end) as escalated_count,
    avg(al.latency_ms) as avg_latency
  from public.audit_logs al
  join public.policy_agents pa on pa.id = al.policy_agent_id
  where pa.project_config_id = project_id;
end;
$$ language plpgsql security definer;

-- ============================================================================
-- FIM DO SCHEMA
-- ============================================================================