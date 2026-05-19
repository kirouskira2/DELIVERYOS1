# 🗺️ [PLAYBOOK DE EXECUÇÃO DEFINTIVO] MOTOR PRISMA V4.0
**Fase:** Implementação de Código com Auditoria Contínua
**Regra de Ouro:** Execução Estrita de Artefato Único (Um arquivo por vez).

Este documento rege a esteira de construção. A I.A. codificadora deve executar o projeto do "núcleo estrutural" para a "casca visual" (Backend-First), parando obrigatoriamente nos **Gateways de Auditoria** antes de mudar de fase.

---

## 🏗️ FASE 1: INFRAESTRUTURA E CONFIGURAÇÃO (BOOTSTRAP)
*Objetivo: Preparar o ecossistema. Ler o Documento 4 e 5.*
*   **Sprint 1.1:** Gerar comandos de terminal para inicializar Next.js, instalar Supabase, Tailwind, shadcn/ui e lucide-react.
*   **Sprint 1.2:** Gerar o arquivo `.env.local` (apenas chaves, sem valores reais).
*   **Sprint 1.3:** Configurar utilitários do Supabase (`src/lib/supabase/server.ts` e `client.ts`).
*   **Sprint 1.4:** Configurar tema (Tailwind Config e `globals.css` para Dark Mode/Blue Midnight).

> 🛑 **GATEWAY DE AUDITORIA 1 (Infra):** A I.A. deve validar internamente: "As chaves do Supabase no client.ts estão usando o prefixo `NEXT_PUBLIC_` para evitar vazamento?"
> *Ação:* Solicitar aprovação do Arquiteto Pedro Lucas para ir à Fase 2.

---

## 🗄️ FASE 2: CAMADA DE DADOS E SEGURANÇA (FACTORY 2)
*Objetivo: Construir o alicerce impenetrável. Ler o Documento 2.*
*   **Sprint 2.1:** Gerar script `.sql` de tabelas, relacionamentos e criação de Enums (ex: tipos de usuários).
*   **Sprint 2.2:** Gerar script `.sql` de **Row Level Security (RLS)**.

> 🛑 **GATEWAY DE AUDITORIA 2 (Segurança):** A I.A. deve validar internamente: "Existe alguma tabela sem RLS ativado? O usuário 'aluno' foi isolado corretamente para ler apenas os próprios dados?"
> *Ação:* Solicitar aprovação para ir à Fase 3.

---

## ⚙️ FASE 3: SERVER ACTIONS E CONTRATOS DE API (FACTORY 2)
*Objetivo: Criar a lógica de negócios sem encostar na UI. Ler o Documento 3.*
*   **Sprint 3.1:** Gerar `/actions/auth.ts` (Lógica de Autenticação Supabase SSR).
*   **Sprint 3.2:** Gerar as ações principais de negócio (CRUDs, Check-ins, Dashboards) em `/actions`.
*   **Sprint 3.3:** Gerar integrações externas (`/actions/gemini.ts` ou chamadas para webhooks do n8n).

> 🛑 **GATEWAY DE AUDITORIA 3 (Contrato de Dados):** A I.A. deve validar internamente: "Todas as funções exportadas possuem a diretiva `"use server"` na linha 1? Todas retornam o objeto padrão `{ success, data, error }`?"
> *Ação:* Solicitar aprovação para ir à Fase 4.

---

## 🎨 FASE 4: INTERFACE SERVER-SIDE (FACTORY 1)
*Objetivo: Criar a estrutura visual estática de altíssima performance. Ler o Documento 4.*
*   **Sprint 4.1:** Gerar Root Layout (`layout.tsx`).
*   **Sprint 4.2:** Gerar Layouts aninhados (ex: Sidebar de navegação em `/dashboard/layout.tsx`).
*   **Sprint 4.3:** Gerar as Páginas principais (`page.tsx`). Elas devem consumir os dados das Server Actions (Fase 3) diretamente no servidor, sem useEffect.

> 🛑 **GATEWAY DE AUDITORIA 4 (Performance):** A I.A. deve validar internamente: "Eu coloquei a diretiva `"use client"` em alguma página inteira por engano? O layout está respeitando o Dark Mode nativo?"
> *Ação:* Solicitar aprovação para a Fase Final.

---

## 🖱️ FASE 5: INTERATIVIDADE CLIENT-SIDE (FACTORY 1)
*Objetivo: Hidratar o sistema com botões, modais e formulários.*
*   **Sprint 5.1:** Gerar componentes interativos (`src/components/forms/`, `src/components/ui/`).
*   **Sprint 5.2:** Conectar os componentes visuais às Server Actions usando hooks (`useTransition`, `useFormStatus`).
*   **Sprint 5.3:** Implementar alertas de interface (Toasts) para gerenciar o estado das ações de sucesso ou falha.

---

## 🔄 PROTOCOLO DE GERAÇÃO (A REGRA ABSOLUTA DA I.A.)
Durante a execução de qualquer Sprint acima, você (A I.A. Codificadora) está **proibida** de responder com mais de um arquivo de código.
1. Gere o arquivo exato do Sprint.
2. Diga: *"Sprint X.Y concluído. Gateway de Auditoria aprovado."*
3. Pare e espere meu comando: *"Prossiga."*