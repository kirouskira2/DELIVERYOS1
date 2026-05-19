🧠 Análise de Contexto
Objetivo do Documento: O 00_Prisma_Concepts_DeepDive.md é o tradutor universal. Ele deve pegar a teoria acadêmica e estratégica (que o Trae/NotebookLM não "sabem" aplicar sozinhos) e transformá-la em diretrizes de engenharia.

Fontes Primárias (Memória):

Teoria TRM: Paper Less is More (2510.04871v1.pdf). Foco na recursividade (Step n: Update z, Step n+1: Update y) e na "Deep Supervision"  como base para o nosso loop de auditoria.



Estratégia SAP: Arquivos v4.txt e v4_.txt. Foco na distinção Build-Time vs. Run-Time e no conceito de Agentes de Política  que substituem lógica hard-coded.






Visual: O uso do HTML extraído (1.md / prototype.html)  e do Google Stitch como "Fonte da Verdade".

Governança: As "5 Regras de Ouro" (Proteção de Dados, Visibilidade) aplicadas via infraestrutura (Gemma Local).

2. 📝 Rascunho Mental (Auto-Crítica V4)
Tópico 1: TRM. Não posso apenas resumir o paper. Tenho que explicar que o z (variável latente de raciocínio do paper)  no Prisma é o "Chain-of-Thought" textual que o agente gera, e que a "Loss Function" é o nosso Audit_Framework.md.

Check V4: O loop não é infinito. Ele precisa de um critério de parada (score de auditoria).

Tópico 2: SAP/Agentes. Preciso ser muito claro: O Prisma (Pilar 1) constrói a Plataforma (Pilar 2). O "Agente de Política" não é o Prisma; é o microsserviço que o Prisma gera para o cliente.

Check V4: Garantir que a regra "Zero Hard-Code" esteja explícita. Regra de negócio = Documento de Texto + Agente RAG .

Tópico 3: Infra e Design. Conectar o Gemma Local à regra de "Proteção de Dados". Conectar o Stitch à regra de "Fidelidade Visual".

3. 💎 Geração Final: 00_Prisma_Concepts_DeepDive.md
Markdown

# Prisma AI V4: Definições Conceituais e Lógica Profunda

Este documento é a "Pedra de Roseta" do Prisma AI. Ele traduz conceitos teóricos complexos em diretrizes de engenharia práticas para o Agente Cognitivo.

---

## 1. A Filosofia TRM (Tiny Recursive Model) Aplicada
[cite_start]**Origem Teórica:** Baseada no paper *"Less is More: Recursive Reasoning with Tiny Networks"* (arXiv:2510.04871v1) [cite: 26-27].
[cite_start]**O Conceito:** Modelos menores podem superar modelos gigantes se utilizarem um processo de raciocínio recursivo (`z`) para refinar suas respostas (`y`) iterativamente [cite: 33-34, 55-59].

### Tradução para a Arquitetura Prisma (O "Motor"):
No Prisma, não treinamos uma rede neural do zero. Nós **simulamos** a arquitetura TRM através do fluxo do nosso Agente Cognitivo:

* **Input ($x$):** A tarefa do manifesto + O contexto do RAG (Docs) + O HTML do Stitch.
* **Raciocínio Latente ($z$):** O "Chain-of-Thought" (Cadeia de Pensamento) do agente. Ele deve explicitar seu plano antes de codar.
* **Previsão ($y$):** O código gerado (o rascunho).
* **Deep Supervision (O Loop de Auditoria):**
    * [cite_start]No paper, a "Deep Supervision" treina o modelo em cada passo intermediário[cite: 72, 152].
    * No Prisma, usamos o **`Audit_Framework.md`** como nossa "Função de Perda".
    * **O Algoritmo de Execução:**
        1.  Gerar $y_0$ e $z_0$.
        2.  **Auto-Auditar:** Comparar $y_0$ com as regras de auditoria.
        3.  **Refinar:** Se houver erro, atualizar o raciocínio ($z_1$) e gerar novo código ($y_1$).
        4.  Repetir até $y_n$ passar na auditoria ou atingir o limite de iterações ($N_{sup}$)[cite: 54, 154].

---

## 2. A Lógica SAP (Arquitetura Híbrida de Produto)
**Origem Estratégica:** Baseada na arquitetura de orquestração de agentes da SAP BTP e Joule Studio [cite: 601-606].

### O Paradigma "Build-Time" vs. "Run-Time":
* **Pilar 1 (Build-Time - O Mestre Artesão):** É o Prisma AI. O sistema que *constrói* o software. Ele usa o TRM para garantir qualidade de código.
* **Pilar 2 (Run-Time - A Equipe Executiva):** É o *produto* que entregamos ao cliente. É uma plataforma de automação de negócios (BPA) [cite: 5, 618-619].

### O Padrão "Agente de Política" (Zero Hard-Code):
A maior inovação do V4 é a eliminação de regras de negócio "hard-coded" (ex: `if (valor > 500)`).
* [cite_start]**Problema:** Regras codificadas geram dívida técnica e dependência de desenvolvedores [cite: 608, 644-645].
* **Solução V4:**
    1.  [cite_start]**Memória de Regras (RAG do Cliente):** O cliente define regras em linguagem natural (PDF/TXT)[cite: 13, 647].
    2.  [cite_start]**Agente de Política:** O Prisma gera um microsserviço que *lê* esse documento em tempo de execução para tomar decisões[cite: 17, 612].
    3.  **Fluxo:** O sistema principal pergunta ao Agente: "Posso aprovar este pedido?". [cite_start]O Agente consulta o documento e responde "Sim/Não" [cite: 648-649].

---

## 3. Governança e Segurança (As 5 Regras de Ouro)
**Origem:** Melhores práticas de governança de IA corporativa.

### Implementação Técnica:
1.  **Proteção de Dados (Regra de Ouro #3):**
    * Nossa PI (Prompts, Frameworks) é sensível.
    * **Solução:** Utilizamos **Embedding Gemma (2b)** rodando localmente via Docker. NENHUM dado de arquitetura sai da nossa infraestrutura para ser vetorizado em APIs públicas.
2.  **Visibilidade (Regra de Ouro #1):**
    * O "Centro de Controle" (Dashboard) gerado para o cliente deve oferecer logs completos de *por que* um Agente de Política tomou uma decisão.

---

## 4. Design-First (Stitch + MCPs)
**Conceito:** A IA não deve "alucinar" o layout. Ela deve "refatorar" uma visão concreta.

### O Fluxo Visual:
1.  **Prompt Visual:** O Arquiteto gera um prompt detalhado para o Google Stitch.
2.  **Fonte da Verdade ($x_{visual}$):** O Stitch gera o HTML/CSS bruto.
3.  [cite_start]**Refatoração TRM:** O Agente Cognitivo usa o HTML como guia visual, mas substitui a implementação por componentes do **Catálogo MCP** (Tremor para dados, Magic UI para efeitos) [cite: 8-9], garantindo que o código final seja React/Next.js profissional, não apenas HTML estático.
4. ✅ Checklist de Validação
Conexão TRM: O documento explica claramente como a "Deep Supervision" do paper se traduz no "Loop de Auto-Auditoria" do Prisma? SIM.

Lógica SAP: A distinção entre quem constrói (Prisma) e o que é construído (Agentes de Política) está explícita e baseada nos arquivos v4? SIM.

Infraestrutura: A justificativa para o uso do Gemma Local (Segurança/Proteção de Dados) está alinhada com as regras de governança? SIM.