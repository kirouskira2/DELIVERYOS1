1. 🧠 Análise de Contexto
Objetivo do Documento: O 10_Stitch_Prompting_Protocol.md é o manual de "Engenharia de Prompt Visual". Ele instrui o Arquiteto IA (ou o usuário) sobre como falar com o Google Stitch para obter um HTML que seja fácil de refatorar.

Fontes Primárias (Memória):

Google Stitch: Ferramenta que gera UI a partir de texto.

Fluxo Design-First: O HTML gerado aqui não é o produto final, é o blueprint que o Agente TRM vai "copiar e melhorar" com MCPs.

Extrator: A experiência com o skip-design-extractor nos mostrou que ter um HTML limpo com classes utilitárias (Tailwind) facilita muito a vida do agente de refatoração.

2. 📝 Rascunho Mental (Auto-Crítica V4)
Estrutura do Prompt: O prompt para o Stitch não pode ser vago ("Crie um site bonito"). Ele precisa ser estrutural ("Crie um dashboard com sidebar à esquerda, header fixo e grid de 4 cards").

Diretriz Técnica: Preciso exigir Tailwind CSS e HTML Semântico. Se o Stitch gerar CSS inline bagunçado, o Agente TRM vai sofrer para refatorar.

Refinamento V4: O protocolo deve explicitamente pedir para não gerar lógica complexa (JS), pois isso é responsabilidade do Agente de Política (Backend), não do protótipo visual.

3. 💎 Geração Final: 10_Stitch_Prompting_Protocol.md
Markdown

# Protocolo de Geração de Prompt para Google Stitch (V4)

Este documento define o padrão ouro para gerar prompts visuais no Google Stitch. O objetivo é produzir um arquivo HTML/CSS (`prototype.html`) que sirva como a "Fonte da Verdade Visual" perfeita para a refatoração pelo Agente TRM.

---

## 1. Anatomia de um Prompt Stitch Perfeito

Ao solicitar uma interface ao Stitch, o `Arquiteto IA` deve construir o prompt seguindo esta estrutura de 4 camadas:

### Camada 1: Contexto e Estilo
> "Atue como um Designer de UI Sênior. Crie uma interface para [NOME_DO_APP], uma plataforma de [DESCRIÇÃO_CURTA].
> **Estilo Visual:** [Minimalista / Analytics-Driven / SaaS B2B / Moderno].
> **Paleta de Cores:** Fundo [Claro/Escuro], Cor Primária [Azul/Roxo/Verde], com alto contraste para legibilidade."

### Camada 2: Estrutura de Layout (O Esqueleto)
> "A página deve ter a seguinte estrutura fixa:
> 1. **Sidebar (Esquerda):** Fixa, com navegação para [Lista de Módulos].
> 2. **Header (Topo):** Com busca global, notificações e avatar do usuário.
> 3. **Main Content (Centro):** Uma área de conteúdo com padding generoso."

### Camada 3: Componentes Específicos (O Conteúdo)
> "Dentro da área principal, inclua:
> * **Seção de KPIs:** Um grid de 4 cartões no topo mostrando métricas chaves (ex: Receita Total).
> * **Seção de Gráficos:** Dois containers grandes lado a lado (placeholders para gráficos de Vendas e Usuários).
> * **Seção de Dados:** Uma tabela detalhada com colunas para [Colunas] e um botão de ação 'Novo Item'."

### Camada 4: Restrições Técnicas (Crítico para Refatoração)
> "**Regras Técnicas Obrigatórias:**
> * Use exclusivamente **HTML5 semântico** e **Tailwind CSS** para estilização.
> * Não use CSS customizado em tags `<style>`. Use classes utilitárias do Tailwind.
> * Não adicione lógica JavaScript complexa. Apenas o visual estático.
> * Use ícones SVG simples inline (estilo Lucide/Heroicons)."

---

## 2. Exemplo Prático (Caso FitPro Manager)

**Prompt Gerado:**
"Crie um dashboard administrativo para o 'FitPro Manager', um SaaS para personal trainers. Estilo 'Clean & Professional', modo claro com acentos em Azul Royal.
**Estrutura:** Sidebar lateral com links (Alunos, Treinos, Financeiro). Header com breadcrumbs e perfil.
**Conteúdo:**
1. Topo: 4 Cards de KPI (Alunos Ativos, Receita Mensal, Aulas Hoje).
2. Meio: Um grid com dois painéis para gráficos (Evolução de Alunos, Distribuição de Treinos).
3. Base: Uma tabela de 'Últimas Transações' com status colorido (Pago=Verde, Pendente=Amarelo).
**Técnico:** Use apenas Tailwind CSS. Fonte Inter ou Sans-serif moderna. Ícones SVG."

---

## 3. Como Usar o Output (O Fluxo V4)

1.  **Geração:** Copie o HTML gerado pelo Stitch.
2.  **Armazenamento:** Salve como `prototype.html` na raiz do projeto.
3.  **Ação do Agente TRM:**
    * O agente lê este HTML para entender o *layout*.
    * Ele ignora os SVGs e divs genéricos.
    * Ele consulta o `03_MCP_Component_Registry.md` e substitui:
        * Os "Cards de KPI" do HTML -> Componente `<Metric>` do **Tremor**.
        * A "Tabela" do HTML -> Componente `<DataTable>` do **Shadcn**.
4. ✅ Checklist de Validação
Foco na Refatoração: O protocolo exige Tailwind CSS, facilitando a conversão para React? SIM.

Separação de Lógica: Instrui explicitamente para não incluir JS complexo (que será feito pelos Agentes de Política)? SIM.

Conexão MCP: O exemplo mostra como os elementos visuais (Cards, Tabelas) se mapeiam para o registro de ferramentas? SIM.