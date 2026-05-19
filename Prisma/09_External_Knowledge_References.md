1. 🧠 Análise de Contexto
Objetivo do Documento: O 09_External_Knowledge_References.md é a bibliografia do projeto. Ele garante que o Agente TRM e o NotebookLM saibam a origem dos conceitos. Se o agente tiver dúvida sobre "O que é Branchlet?", ele consulta este arquivo.

Fontes Primárias (Memória):


Teoria: Paper TRM , Lógica SAP , Software 2.0.



Ferramentas: Branchlet, LangGraph, Google Stitch, Skip Extractor.

Infra: Gemma Local, Google File Search API.

Governança: 5 Regras de Ouro.

2. 📝 Rascunho Mental (Auto-Crítica V4)
Tópico 1: Agentes. Citar o paper TRM como a base do raciocínio. Citar a SAP como a base do produto (BPA).

Tópico 2: Ferramentas. Incluir o link do Branchlet (GitHub) e do Stitch.

Tópico 3: Design. Listar os MCPs (Tremor, Magic UI) e a extensão do Chrome que usamos.

Refinamento: Adicionar uma breve explicação de por que usamos cada um, para dar contexto ao agente.

3. 💎 Geração Final: 09_External_Knowledge_References.md
Markdown

# Referências de Conhecimento Externo e Inspiração (Prisma V4)

Este documento lista as fontes primárias, ferramentas e conceitos que fundamentam a arquitetura do Prisma AI. O `Agente Cognitivo TRM` deve utilizar estas referências para alinhar seu raciocínio e decisões técnicas.

---

## 1. Filosofia de Agentes e Raciocínio (O "Cérebro")

### **TRM (Tiny Recursive Model)**
* [cite_start]**Fonte:** Paper *"Less is More: Recursive Reasoning with Tiny Networks"* (arXiv:2510.04871v1) .
* **Conceito Chave:** Modelos menores podem superar modelos gigantes se utilizarem um processo recursivo de refinamento (`gerar -> criticar -> refinar`).
* **Aplicação no Prisma:** Fundamenta o nosso "Loop de Auto-Auditoria" e a decisão de usar um único agente inteligente em vez de uma cadeia linear.

### **Arquitetura de Agentes Autônomos (Estratégia SAP)**
* [cite_start]**Fonte:** Documentação SAP BTP / Joule Studio [cite: 309-339].
* **Conceito Chave:** Distinção entre **Build-Time** (Fábrica de Agentes) e **Run-Time** (Execução de Processos). Uso de "Agentes de Política" para ler regras de negócio em vez de hard-coding.
* **Aplicação no Prisma:** Define o *produto* que entregamos: uma Plataforma de Automação de Negócios (BPA).

### **Deep Agents & Subagentes**
* **Fonte:** Pesquisa LangChain (`langchain-ai/deepagents`) e vídeos sobre Claude Code.
* **Conceito Chave:** Treinamento de agentes via Reinforcement Learning e delegação de subtarefas para especialistas.

---

## 2. Ferramentas e Bibliotecas de Orquestração

### **LangGraph**
* **Função:** Framework de orquestração cíclica em Python.
* **Aplicação:** O "chassi" do nosso orquestrador, permitindo loops e memória de estado persistente.

### **Branchlet**
* **Fonte:** GitHub `raghavpillai/branchlet`.
* **Função:** Biblioteca para gerenciamento de lógica condicional e criação de worktrees (sandboxes).
* **Aplicação:** Usado para gerenciar as transições condicionais complexas dentro do grafo e para isolar experimentos de código.

---

## 3. Infraestrutura de Memória e RAG

### **Google Embedding Gemma (Local)**
* **Fonte:** Google Developers Blog (Introducing Embedding Gemma).
* **Função:** Modelo de embedding state-of-the-art e open-source.
* **Aplicação:** Rodado localmente via Docker para vetorizar a PI do Prisma (`/docs`) sem custo de API e com total privacidade de dados (Regra de Ouro #3).

### **Google File Search API (RAG-as-a-Service)**
* **Fonte:** Documentação Gemini API.
* **Função:** RAG gerenciado pelo Google.
* **Aplicação:** Usado *exclusivamente* no produto do cliente (Pilar 2) para permitir que "Agentes de Política" consultem documentos de regras sem que tenhamos que gerenciar a infraestrutura vetorial deles.

---

## 4. Ferramentas de Design e Prototipagem (Design-First)

### **Google Stitch**
* **Fonte:** Google Developers Blog.
* **Função:** Geração de protótipos HTML/CSS de alta fidelidade a partir de prompts de texto.
* **Aplicação:** Cria a "Fonte da Verdade Visual" (`prototype.html`) que o agente refatora.

### **Skip Design Extractor**
* **Fonte:** Extensão do Chrome.
* **Aplicação:** Usado para extrair HTML de referências visuais reais (ex: Magic UI, Agente Sky) para servir de base para o Stitch ou refatoração direta.

### **Catálogo de MCPs (Componentes Premium)**
* **Tremor UI:** (Dashboards e Dados) - Padrão para áreas administrativas.
* **Magic UI & Aceternity UI:** (Marketing e Efeitos) - Padrão para Landing Pages e "Wow Factor".
* **shadcn/ui:** (Estrutura) - Padrão para componentes funcionais básicos.

---

## 5. Governança e Fundamentos Teóricos

### **5 Regras de Ouro para IA**
* **Fonte:** Vídeo de referência sobre Governança de IA.
* **Conceito Chave:** Visibilidade, Avaliação de Risco Contextual, Proteção de Dados, Controle de Acesso, Monitoramento Contínuo.
* **Aplicação:** Define as políticas de segurança no `08_Security_Governance_Policy.md`.

### **Software 2.0 (Andrej Karpathy)**
* **Conceito Chave:** O programador deixa de escrever código imperativo e passa a ser o "professor" que cura o dataset (RAG) e avalia o resultado (Auditoria).

### **Engenharia de Software Clássica**
* **Regra 10 de Myers:** O custo de correção de bugs aumenta exponencialmente com o tempo. Justificativa econômica para a auto-auditoria imediata do TRM.
* **10 Heurísticas de Nielsen:** Princípios de usabilidade que o `Agente de Design` deve verificar.
4. ✅ Checklist de Validação
Cobertura Completa: Inclui TRM, SAP, Branchlet, Gemma, Stitch e MCPs? SIM.

Links de Origem: As referências apontam para as fontes corretas (Papers, GitHub, Google Blogs)? SIM.

Contexto de Uso: Explica por que e onde cada ferramenta é usada no Prisma V4? SIM.