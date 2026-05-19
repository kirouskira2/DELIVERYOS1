# Plano de Implementação de Prompts V4 (Guia de Execução TRM)

Este documento contém os **Prompts de Raciocínio** específicos que o `Agente Cognitivo TRM` deve utilizar para executar cada `taskId` do `04_ProjectManifest_Template_V4.json`.

**DIRETRIZ MESTRA:**
Para cada tarefa, inicie seu loop de raciocínio (`z`) com o prompt indicado. Não pule etapas de auto-auditoria.

---

## Fase 1: Fundação e Infraestrutura

### Para `taskId: infra_setup_build_time`
**Prompt de Raciocínio:**
"Sua missão é configurar o 'Chão de Fábrica' local.
1.  Crie um `docker-compose.yml`.
2.  Defina o serviço `embedding-service` com `ollama/ollama` (modelo `gemma:2b`).
3.  Defina o `vector-db` (pgvector) e `flowise` na mesma rede `prisma-net`.
4.  **Auto-Auditoria:** Verifique se o Gemma está isolado e não exposto à internet pública."

### Para `taskId: infra_setup_run_time`
**Prompt de Raciocínio:**
"Configure a infraestrutura de produção no Supabase.
1.  Gere o SQL para habilitar a extensão `vector`.
2.  Crie um bucket privado `prisma-rules` no Storage.
3.  Crie os segredos para a **Google File Search API** (Gemini). Esta será a memória dos Agentes de Política."

---

## Fase 2: Agentes de Política (Backend V4)

### Para `taskId: agent_core_service`
**Prompt de Raciocínio:**
"Crie a classe base `AbstractPolicyAgent` em TypeScript (Edge Function).
1.  **Input:** `context` (JSON) e `knowledgeBaseId` (String).
2.  **Ação:** Consultar a Google File Search API com o contexto.
3.  **Prompt Interno:** Instrua o LLM a atuar como 'Juiz Imparcial', citando o trecho do documento recuperado.
4.  **Output:** `{ decision: 'APPROVED'|'REJECTED', reason: string, citation: string }`.
5.  **Auto-Auditoria:** Garanta que não há lógica de `if/else` nesta classe. Ela é apenas um orquestrador."

### Para `taskId: implement_project_policy_agent`
**Prompt de Raciocínio:**
"Implemente o 'Agente de Criação de Projetos'.
1.  **Objetivo:** Validar se um projeto pode ser criado baseada no plano do usuário.
2.  **Fonte da Verdade:** O arquivo `regras_planos.txt` (simulado/upload).
3.  **Lógica:** Em vez de checar `user.plan == 'free'`, consulte o agente: 'O usuário do plano Free pode criar mais um projeto?'.
4.  **Auto-Auditoria:** Se você escrever `const MAX_PROJECTS = 3`, você falhou. O número 3 deve vir do documento."

### Para `taskId: implement_security_agent`
**Prompt de Raciocínio:**
"Implemente o 'Agente de Política de Segurança'.
1.  **Objetivo:** Analisar inputs antes de processar.
2.  **Regra:** Consultar a base de conhecimento de segurança para detectar padrões de Prompt Injection.
3.  **Ação:** Se o agente retornar 'RISCO ALTO', bloquear a operação."

---

## Fase 3: Interface e Experiência (Design-First)

### Para `taskId: ui_setup_and_prototype`
**Prompt de Raciocínio:**
"Inicialize o Next.js. Pegue o conteúdo de `landingpage.txt` e salve como `src/prototypes/landing.html`. Pegue `dashboard.txt` e salve como `src/prototypes/dashboard.html`. Estes arquivos são sua referência visual absoluta."

### Para `taskId: ui_refactor_landing`
**Prompt de Raciocínio:**
"Refatore o `src/prototypes/landing.html` para `src/app/page.tsx`.
1.  **Analise:** Identifique a seção Hero, Marquee e Pricing.
2.  **Upgrade MCP:** Consulte `03_MCP_Component_Registry.md`.
    * Substitua o fundo por `AnimatedGridPattern` (Magic UI).
    * Substitua a lista de logos por `<Marquee>` (Magic UI).
    * Substitua os botões por `ShimmerButton`.
3.  **Conteúdo:** Mantenha os textos sobre 'Prisma AI' definidos no `01_Strategic_Analysis`."

### Para `taskId: ui_refactor_dashboard`
**Prompt de Raciocínio:**
"Refatore o `src/prototypes/dashboard.html` para o layout do sistema.
1.  **Mapeamento (FitPro -> Prisma):**
    * Card 'Total Revenue' -> Card **'Projetos Ativos'** (Tremor Metric).
    * Gráfico 'Revenue' -> Gráfico **'Consumo de Tokens'** (Tremor AreaChart).
    * Tabela 'Transactions' -> Tabela **'Logs de Auditoria'** (Shadcn DataTable).
2.  **Conexão:** Use `useQuery` para buscar os dados da tabela `public.projects` e `public.factory_audit_logs`."

### Para `taskId: ui_agent_control_center`
**Prompt de Raciocínio:**
"Crie a página `/agents`.
1.  Implemente uma área de upload para o bucket `prisma-rules`.
2.  Crie uma visualização de lista para os Agentes de Política ativos.
3.  Adicione um 'Playground' onde o admin pode testar: 'Se eu enviar este projeto X, ele passa?' e ver a resposta do Agente em tempo real."