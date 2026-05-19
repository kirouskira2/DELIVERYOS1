 🧠 Análise de Contexto
Objetivo do Documento: O 02_Infrastructure_Stack_Spec.md deve ser o manual de "hardware" e "cabeamento". Ele não fala de código abstrato, mas de containers, portas e serviços.

Fontes Primárias (Memória):


Segurança: A decisão de usar Gemma Local para evitar vazamento de PI (Regra de Ouro #3) .

RAG: A escolha do Flowise como interface visual e pgvector como banco.

Orquestração: A necessidade de um ambiente Python robusto para o LangGraph.


Ferramentas: O uso do Branchlet para gestão de versões/experimentos .

2. 📝 Rascunho Mental (Auto-Crítica V4)
Tópico 1: O Ambiente de Desenvolvimento (A Fábrica). Preciso especificar o docker-compose.yml.

Critique: Não basta dizer "use Docker". Tenho que listar os serviços: orchestrator, vector_db, embedding_service, rag_manager.

Tópico 2: O Serviço de Embedding. É crucial especificar como o Gemma roda. Vou sugerir o uso do Ollama ou vLLM dentro do Docker, pois é a forma mais padrão e eficiente de servir modelos abertos localmente hoje.

Tópico 3: O Ambiente do Produto (O que entregamos). Distinguir claramente a infra do Prisma (Docker local/nuvem própria) da infra do Cliente (Vercel + Supabase).

3. 💎 Geração Final: 02_Infrastructure_Stack_Spec.md
Markdown

# Especificação de Infraestrutura Técnica Prisma V4

Este documento define a arquitetura de sistemas ("o chão de fábrica") necessária para executar o Prisma AI com segurança, performance e custo zero de API para processos internos.

---

## 1. Arquitetura de Containers (Docker Compose)
O núcleo do Prisma V4 roda sobre uma orquestração de serviços isolados. Esta arquitetura garante que nossa PI (Propriedade Intelectual) permaneça soberana e não dependa de nuvens externas.

### Serviços do `docker-compose.yml`:

#### A. `prisma-orchestrator` (O Cérebro)
* **Imagem:** Python 3.11 (Custom build).
* **Função:** Executa o **LangGraph**. É onde vivem o `Agente Cognitivo TRM` e os fluxos de trabalho.
* **Dependências:** `langgraph`, `langchain`, `pydantic`.
* **Conexões:** Fala com o `embedding-service` e o `rag-manager`.

#### B. `embedding-service` (A Proteção de Dados)
* **Imagem:** Ollama (ou vLLM para produção).
* **Modelo Carregado:** `google/gemma-2b` (ou 7b dependendo da GPU).
* **Exposição:** API REST interna (ex: porta 11434).
* **Justificativa V4:** Garante que vetorização de documentos sensíveis (`/docs`) aconteça localmente, sem enviar dados para OpenAI/Anthropic.

#### C. `vector-db` (A Memória)
* **Imagem:** `ankane/pgvector` (PostgreSQL com extensão vetorial pré-instalada).
* **Função:** Armazena os embeddings da nossa base de conhecimento e os logs de execução dos agentes.
* **Persistência:** Volume Docker local para dados.

#### D. `rag-manager` (A Interface de Conhecimento)
* **Imagem:** FlowiseAI (`flowise`).
* **Função:** Interface visual para construir, testar e manter os pipelines de RAG.
* **Fluxo:** O Flowise conecta-se ao `embedding-service` (para vetorizar) e ao `vector-db` (para armazenar). O `prisma-orchestrator` chama o Flowise via API para obter contexto.

---

## 2. Stack de Desenvolvimento e Ferramentas

### Gestão de Código e Experimentos
* **Branchlet:** Ferramenta CLI obrigatória para criar *worktrees* isolados.
    * *Uso:* Cada nova feature ou refatoração do Prisma deve ser feita em uma `branchlet` separada para não poluir o núcleo estável.

### Prototipagem Visual
* **Google Stitch:** Ferramenta externa utilizada na fase de "Concepção".
    * *Fluxo:* Prompt -> Stitch -> HTML -> `/src/prototypes/`.

---

## 3. Stack do Produto Final (O que entregamos ao Cliente)
Diferente da infraestrutura interna (que é Docker/Python), o produto final gerado pelo Prisma segue a arquitetura **Serverless/Edge** para escalabilidade do cliente.

* **Frontend:** Next.js 14+ (App Router), hospedado na **Vercel**.
* **Backend & Banco de Dados:** **Supabase**.
    * *Auth:* Gerenciamento de usuários.
    * *Database:* PostgreSQL para dados transacionais.
    * *Edge Functions:* Onde residem os **"Agentes de Política"** (lógica V4).
* **RAG do Cliente (Run-Time):**
    * Para o cliente final, **NÃO** usamos a stack local complexa.
    * Usamos a integração com **Google File Search API** (Gemini API) pela facilidade de manutenção e custo-benefício para o usuário final.

---

## 4. Diagrama de Fluxo de Dados (Segurança)

1.  **Dados Internos (PI do Prisma):**
    * `Docs` -> `Gemma Local` -> `pgvector Local`. (Trafego 100% interno).
2.  **Dados do Cliente (Regras de Negócio):**
    * `PDF do Cliente` -> `Upload via Dashboard` -> `Google File Search API`. (Dados do cliente geridos por provedor de nuvem seguro).
4. ✅ Checklist de Validação
Soberania de Dados: O documento especifica claramente que o embedding-service é local (Ollama/Gemma), garantindo que nossa PI não saia da infraestrutura? SIM.

Separação de Ambientes: A distinção entre a stack do "Motor" (Docker/Python) e a stack do "Produto" (Vercel/Supabase) está clara? SIM.

Alinhamento V4: A inclusão do Branchlet e a menção aos Agentes de Política (como Edge Functions) conectam com a estratégia híbrida? SIM.