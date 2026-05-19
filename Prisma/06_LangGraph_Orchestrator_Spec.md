06_LangGraph_Orchestrator_Spec.md

Markdown

# Especificação Técnica do Orquestrador LangGraph (V4.1)

Este documento define a arquitetura do "Micro-Orquestrador" em Python. Ele é o motor que executa o ciclo de raciocínio TRM para construir o Prisma AI.

## 1. Definição de Estado (AgentState)
O objeto de estado deve carregar o contexto do projeto (baseado no `jsonformulario.txt`) e as métricas de controle financeiro/qualidade.

```python
from typing import TypedDict, List, Dict, Any

class AgentState(TypedDict):
    # --- Contexto do Projeto (Input) ---
    job_id: str                  # UUID do job vindo do n8n
    project_context: Dict        # Dados do 'jsonformulario.txt' (briefing, entities)
    current_task: Dict           # A tarefa ativa do 'ProjectManifest'
    
    # --- Controle de Arquitetura (V4) ---
    compilation_target: str      # 'V3.1', 'V4' ou 'HYBRID' (Definido na Triagem)
    risk_level: str              # 'LOW', 'MEDIUM', 'HIGH'
    
    # --- Controle de Recursos (Otimização) ---
    token_budget: float          # Limite de gasto para a tarefa
    current_cost: float          # Custo acumulado
    
    # --- Memória de Trabalho TRM (Loop Recursivo) ---
    code_draft: str              # O código gerado (y)
    reasoning_trace: str         # O racional passo-a-passo (z)
    audit_feedback: str          # O retorno do Auditor (crítica)
    quality_score: float         # Nota 0.0 a 10.0
    iteration_count: int         # Contador de tentativas (Max: 5)
    
    # --- Ferramentas ---
    rag_context: str             # Snippets recuperados do Flowise/Gemma
    visual_context: str          # O HTML do 'dashboard.txt' ou 'landingpage.txt'
2. Topologia do Grafo (Nodes)
A. Node: Contextual_Auditor (Triagem Inicial)
Função: Analisa o project_context e define o compilation_target.

Regra: Se adaptiveAnswers contiver "compliance" ou "audit-trail", define Target = V4.

B. Node: TRM_Worker (O Construtor)
Função: Gera o código.

Inputs: current_task + rag_context + visual_context.

Ação:

Consulta 03_MCP_Component_Registry para mapear o HTML visual.

Gera o código (ex: page.tsx ou policy_agent.ts).

Registra o reasoning_trace.

C. Node: Auditor (A Consciência)
Função: Valida o code_draft.

Inputs: Código gerado + 07_Audit_Framework_V4.md.

Output: Atualiza quality_score e audit_feedback.

3. Lógica Condicional (Edges com Branchlet)
As transições usam branchlet para decisão declarativa:

Python

@branchlet.route
def route_after_audit(state: AgentState):
    # Sucesso: Qualidade alta
    if state['quality_score'] >= 9.5:
        return "finalize_task"
    
    # Refinamento: Qualidade baixa, mas dentro do limite
    if state['quality_score'] < 9.5 and state['iteration_count'] < 5:
        return "retry_refinement" # Volta para TRM_Worker
    
    # Falha Crítica: Limite excedido -> Humano
    return "escalate_to_human"
4. Contrato de API (Integração Externa)
Entrada: POST /run-task (Recebe o JSON do formulário).

Saída: Webhook para o n8n com o status e link para o artefato gerado.


---

### 🛡️ Documento 7: A Lei da Qualidade
Este é o checklist que o Agente (definido acima) vai usar para se julgar. Ele foi adaptado para garantir que o Prisma AI (o produto que estamos construindo) siga suas próprias regras de "Zero Hard-Code".

**Nome do Arquivo:** `07_Audit_Framework_V4.md`

```markdown
# Framework de Auditoria e Qualidade Prisma V4.1

Este documento é a "Constituição" para a auto-auditoria do Agente TRM.
**Regra:** O código só passa se cumprir 100% dos itens aplicáveis.

## 1. Auditoria de Arquitetura V4 (Agentes & Políticas)
*Crítico para o Backend do Prisma.*
- [ ] **Zero Hard-Coding:** O código contém regras de negócio fixas (ex: `const MAX_PROJECTS = 5`)?
    * **Falha:** Regra chumbada.
    * **Passa:** O código consulta um `PolicyAgent` ou configuração dinâmica.
- [ ] **Uso de Agentes de Política:** As decisões de permissão (ex: "Usuário pode criar projeto?") são delegadas a um serviço isolado?
- [ ] **Integração RAG:** O serviço está configurado para ler regras do bucket `prisma-rules` ou Google File Search?

## 2. Auditoria de Frontend (Design-First)
*Crítico para a refatoração de `landingpage.txt` e `dashboard.txt`.*
- [ ] **Fidelidade Visual:** O componente React refatorado respeita a estrutura e classes do arquivo `.txt` original?
- [ ] **Uso de MCPs:**
    * O HTML genérico de gráficos foi substituído por componentes **Tremor**?
    * As seções de marketing usam componentes **Magic UI** ou **Aceternity**?
- [ ] **Dados Reais:** Os componentes visuais recebem dados via `props` (preparados para API) em vez de textos estáticos?

## 3. Qualidade de Código e Segurança
- [ ] **Validação Zod:** Todos os inputs (do formulário ou API) são validados com schemas Zod estritos?
- [ ] **Tipagem TypeScript:** Não existe uso de `any`. Interfaces `ProjectConfig` e `AuditLog` estão sendo usadas?
- [ ] **Proteção de Dados:** Nenhuma chave de API ou dado sensível é logado ou exposto no client-side?

---
**Protocolo de Reprovação:**
Se houver falha:
1.  Identifique a regra violada.
2.  Gere um novo `reasoning_trace` explicando a correção.
3.  Reescreva o código.