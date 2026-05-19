# Registro de Ferramentas e Componentes (MCPs) do Prisma V4

Este documento atua como o "Catálogo de Peças" oficial. O Agente Cognitivo TRM **DEVE** consultar este registro ao refatorar o HTML bruto do Stitch.

**Diretriz Mestra:** Nunca recrie estilos complexos ou visualizações de dados do zero (CSS puro). Se um componente visual premium já existe neste registro, a sua tarefa é **importá-lo e configurá-lo**.

---

## 1. MCP de Visualização de Dados & Dashboards (The "Brain")
**Biblioteca Padrão:** **Tremor UI** (v3.x ou superior)
**Uso Obrigatório:** Em qualquer tela administrativa, de analytics ou financeira (ex: FitPro Dashboard, Relatórios).

| Elemento Visual no Protótipo (HTML) | Componente Tremor Recomendado | Notas de Implementação |
| :--- | :--- | :--- |
| Gráfico de Barras / Colunas | `<BarChart />` | Usar para comparações (ex: "Receita vs Despesas"). Configurar cores para `['emerald', 'red']` se for financeiro. |
| Gráfico de Pizza / Rosca | `<DonutChart />` | Usar para composições (ex: "Distribuição de Planos"). |
| Cartão de KPI (Número Grande) | `<Metric />` dentro de `<Card />` | Usar para métricas principais ("Receita Total", "Total de Alunos"). |
| Texto de Apoio ao KPI | `<Text />` | Para legendas ou subtítulos dentro dos Cards. |
| Tabela de Dados Simples | `<Table />` | Para listagens rápidas de dashboard. |
| Seletor de Período | `<DateRangePicker />` | Obrigatório em telas de relatórios. |

---

## 2. MCP de Design "Wow Factor" & Marketing (The "Soul")
**Bibliotecas Padrão:** **Magic UI** & **Aceternity UI**
**Uso Obrigatório:** Na Landing Page e áreas de destaque do produto para criar percepção de alto valor (efeito "Uau").

### Seção Hero e Apresentação
* **Fundo/Background:**
    * *Opção Técnica:* `AnimatedGridPattern` (Magic UI) - Para produtos SaaS B2B/DevTools.
    * *Opção Estética:* `AuroraBackground` (Aceternity) - Para produtos modernos e criativos.
* **Títulos (H1):** `WordPullUp` ou `GradualSpacing` (Magic UI) para animação suave de entrada de texto.
* **Botões CTA (Call to Action):** `ShimmerButton` (Magic UI) - O botão com brilho animado para conversão máxima.

### Seção de Prova Social (Logos de Clientes)
* **Componente:** `<Marquee />` (Magic UI).
* **Uso:** Substituir qualquer lista estática de logos (`<ul>`) por este componente de rolagem infinita.

### Efeitos Especiais em Cards
* **Destaque:** `BorderBeam` (Magic UI).
* **Uso:** Adicionar uma borda brilhante animada que percorre o container de "Planos de Preço" (Pricing) ou "Feature Principal".

---

## 3. MCP de Estrutura e Funcionalidade Base (The "Body")
**Biblioteca Padrão:** **shadcn/ui** (Baseada em Radix UI + Tailwind)
**Uso Obrigatório:** Para todo o esqueleto da aplicação, formulários complexos e interações padrão.

* **Layout:** `Sheet` (para Sidebar Mobile), `NavigationMenu` (Header).
* **Formulários:** `Form` (react-hook-form + zod), `Input`, `Select`, `Switch`, `Checkbox`.
* **Feedback:** `Toast` (Notificações), `Alert`, `Dialog` (Modais de confirmação).
* **Ações:** `Button` (Variantes: default, outline, ghost), `DropdownMenu` (Menus de ação).
* **Dados Complexos:** `DataTable` (TanStack Table) para tabelas com paginação, filtro e ordenação (ex: Lista de Alunos).

---

## 4. Regras de Composição (Como o Agente deve montar)

1.  **Hierarquia de Escolha:**
    * É um dado estatístico? -> **Tremor**.
    * É uma animação de marketing/landing page? -> **Magic UI**.
    * É um elemento funcional (botão, input, modal)? -> **shadcn/ui**.

2.  **Customização de Tema:**
    * Todos os componentes devem respeitar as variáveis de cor CSS (`--primary`, `--background`, `--foreground`) definidas no `globals.css` do projeto. Isso garante que o tema visual (Dark/Light) do Stitch seja preservado e aplicado aos componentes importados.

3.  **Instalação Automática:**
    * O Agente deve identificar quais componentes são necessários e incluir os comandos de instalação no plano de execução (ex: `npx shadcn-ui@latest add button input`).