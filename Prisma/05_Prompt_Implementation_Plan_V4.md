.

1. 🧠 Análise de Contexto
Objetivo do Documento: O 05_Prompt_Implementation_Plan_V4.md é o elo entre o "O Quê" (Manifesto) e o "Quem" (Agente). Ele traduz tarefas abstratas em prompts de raciocínio específicos.

Fontes Primárias (Memória):


Manifesto V4 (04_ProjectManifest): Preciso cobrir as tarefas de infraestrutura, agentes de política e frontend .


Lógica SAP (v4.txt): O prompt para o backend deve proibir explicitamente o hard-coding e exigir a criação de serviços que consultam o RAG do cliente .





Visual (Stitch + MCPs): O prompt para o frontend deve instruir o agente a olhar o HTML do Stitch, identificar o padrão e substituí-lo pelo componente MCP equivalente .


2. 📝 Rascunho Mental (Auto-Crítica V4)
Tarefa de Infra: Não posso apenas dizer "crie o docker". Tenho que especificar que o serviço de embedding é o Gemma local e que ele deve estar na mesma rede do Flowise.

Tarefa de Backend: Esta é a crítica. Se o prompt for "Implemente a regra de desconto", o agente vai escrever um if. O prompt deve ser: "Crie um Agente de Política que lê a regra de desconto de um documento".

Tarefa de Frontend: O prompt deve forçar a fidelidade visual ao Stitch, mas a implementação técnica com Tremor/Magic UI.

Refinamento: Adicionar uma instrução de "Auto-Auditoria" em cada prompt para reforçar o loop TRM.

3. 💎 Geração Final: 05_Prompt_Implementation_Plan_V4.md
Markdown

# Plano de Implementação de Prompts V4 (Guia de Execução TRM)

Este documento contém os **Prompts de Raciocínio** específicos que o `Agente Cognitivo TRM` deve utilizar para executar cada `taskId` do `ProjectManifest`.

**DIRETRIZ MESTRA DE EXECUÇÃO:**
Para cada tarefa abaixo, inicie seu loop de raciocínio (`z`) com o prompt indicado. Não pule etapas de auto-auditoria.

---

## Fase 1: Fundação e Infraestrutura

### Para `taskId: infra_setup_build_time`
**Prompt de Raciocínio:**
"Sua missão é configurar o 'Chão de Fábrica' do Prisma.
1.  Crie um arquivo `docker-compose.yml` robusto.
2.  Defina o serviço `embedding-service` usando a imagem `ollama/ollama` e configure-o para baixar e servir o modelo `gemma:2b` na inicialização. Isso é crítico para a Regra de Ouro #3 (Proteção de Dados).
3.  Defina o serviço `vector-db` com a imagem `pgvector/pgvector`.
4.  Defina o serviço `flowise` e garanta que ele tenha conectividade de rede com o `embedding-service` e o `vector-db`.
5.  **Auto-Auditoria:** Verifique se alguma porta sensível está exposta publicamente sem necessidade."

### Para `taskId: setup_customer_rag`
**Prompt de Raciocínio:**
"Agora configure a infraestrutura 'Run-Time' para o cliente.
1.  Habilite a integração com a **Google File Search API** (Gemini API).
2.  Crie uma classe utilitária `CustomerKnowledgeBase` no backend (Supabase Edge Functions) que abstraia o upload de arquivos e a consulta semântica.
3.  Esta classe será usada por todos os Agentes de Política. Ela deve receber uma query e retornar o trecho de texto mais relevante das regras do cliente."

---

## Fase 2: Agentes de Negócio (Lógica SAP)

### Para `taskId: create_policy_agent_service`
**Prompt de Raciocínio:**
"Você deve criar a arquitetura base para os 'Agentes de Política'.
1.  Implemente uma Edge Function genérica `AbstractPolicyAgent`.
2.  **Lógica Obrigatória:**
    * Input: Contexto da decisão (ex: dados do pedido).
    * Ação 1: Consultar a `CustomerKnowledgeBase` com o contexto.
    * Ação 2: Enviar o contexto + regras recuperadas para o LLM (Gemini Flash) com um System Prompt instruindo-o a atuar como um juiz imparcial.
    * Output: JSON `{ decision: 'APPROVED' | 'REJECTED', reason: string, confidence: number }`.
3.  **Auto-Auditoria:** Garanta que NENHUMA regra de negócio esteja escrita no código desta função base."

### Para `taskId: implement_specific_agents` (Ex: Financeiro)
**Prompt de Raciocínio:**
"Implemente o 'Agente de Aprovação Financeira' estendendo o serviço base.
1.  Defina o System Prompt específico: 'Você é um auditor financeiro. Analise o pedido contra as regras de despesa recuperadas do documento de política.'
2.  Não escreva `if (value > 1000)`. O agente deve ler isso do documento.
3.  Teste mentalmente: Se o cliente mudar a regra de 1000 para 2000 no documento, seu código precisa mudar? Se a resposta for 'não', você passou."

---

## Fase 3: Interface e Experiência (Design-First)

### Para `taskId: refactor_ui_stitch_to_nextjs`
**Prompt de Raciocínio:**
"Atue como um Engenheiro de Frontend Sênior.
1.  Analise o arquivo `prototype.html` (gerado pelo Stitch). Entenda a hierarquia visual, o espaçamento e as cores.
2.  **Mapeamento MCP:** Consulte o `03_MCP_Component_Registry.md`.
    * Onde houver gráficos -> Importe **Tremor** `<BarChart>` ou `<DonutChart>`.
    * Onde houver listas de logos -> Importe **Magic UI** `<Marquee>`.
    * Onde houver tabelas -> Importe **Shadcn** `<DataTable>`.
3.  Refatore o HTML para componentes React (Next.js App Router), substituindo as tags nativas pelos componentes premium selecionados.
4.  **Auto-Auditoria:** O resultado visual é fiel ao Stitch? A implementação é responsiva?"

### Para `taskId: connect_agent_dashboard`
**Prompt de Raciocínio:**
"Construa o 'Centro de Controle de Agentes'.
1.  Use o **Tremor UI** para criar um dashboard que mostre não apenas dados, mas a *saúde* dos agentes.
2.  Crie uma área de upload onde o cliente possa enviar seus PDFs de regras (`regras_financeiras.pdf`, `guia_atendimento.pdf`).
3.  Exiba um log de auditoria em tempo real: 'O Agente Financeiro aprovou o Pedido #123 baseado na regra da pág. 4 do PDF'."
4. ✅ Checklist de Validação
Segurança de Infra: O prompt de infraestrutura reforça o uso de Gemma Local para proteção de dados? SIM. 


Zero Hard-Code: Os prompts de backend instruem explicitamente a criação de Agentes de Política e proíbem regras no código? SIM. 



Fidelidade e Qualidade UI: O prompt de frontend conecta explicitamente o protótipo Stitch ao catálogo de MCPs? SIM.