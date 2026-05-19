# 🚀 AI-Powered SaaS Generation Platform Guide

**Versão:** 3.0 (Gemini-Powered)
**Última Atualização:** 2025-05-24
**Localização:** Raiz do Projeto (`/SAAS-FRAMEWORK-GUIDE.md`)
**Finalidade:** Descrever a arquitetura técnica e os padrões da plataforma de geração de SaaS. Este documento serve como a "fonte da verdade" para o desenvolvimento, automação via `saas-cli` e para os prompts enviados ao Google Gemini.

---

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Setup Inicial](#-setup-inicial-sprint-0)
- [Arquitetura Multi-Tenant](#-arquitetura-multi-tenant)
- [Sistema de Permissões](#-sistema-de-permissões)
- [Módulos de Funcionalidades](#-módulos-de-funcionalidades)
- [Integração com IA (Gemini-Powered)](#-integração-com-ia-gemini-powered)
- [CLI de Desenvolvimento (AI-Enhanced)](#-cli-de-desenvolvimento-ai-enhanced)
- [Resiliência e Escalabilidade](#-resiliência-e-escalabilidade)
- [Monitoramento e Observabilidade](#-monitoramento-e-observabilidade)
- [Estratégia de Testes](#-estratégia-de-testes)
- [Estrutura de Pastas](#-estrutura-de-pastas)
- [Processo de Desenvolvimento e DevOps](#-processo-de-desenvolvimento-e-devops)

---

## ✅ Visão Geral

Esta plataforma fornece uma base de nível empresarial para a geração e construção de produtos SaaS.

- **Frontend:** Next.js + React + TypeScript + Tailwind CSS + shadcn/ui
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Realtime, Edge Functions)
- **IA (Core):** Google Gemini Pro como motor de geração de código e funcionalidades
- **Pagamentos:** Stripe, Lemon Squeezy (abstraído)
- **Arquitetura:** Multi-tenant, modular, PWA-ready, orientada a eventos
- **Automação:** `saas-cli` com geração de código contextual via Gemini
- **Escalabilidade:** Cache distribuído (Redis), Filas de Processamento (BullMQ)

### Princípios da Plataforma

1.  **AI-First:** A IA não é um complemento, mas a principal ferramenta para geração, refatoração e automação.
2.  **Modularidade Dinâmica:** Funcionalidades são geradas e configuradas sob demanda.
3.  **Escalabilidade por Padrão:** A arquitetura já nasce pronta para alta demanda.
4.  **Segurança Holística:** Segurança implementada em todas as camadas, de RLS a WAF.
5.  **Developer Experience Superior:** Automação inteligente que libera o desenvolvedor para focar na lógica de negócio.

---

## 🚀 Setup Inicial (Sprint 0)

### 1. Dependências do Projeto

```bash
# Criar projeto Next.js
npx create-next-app@latest . --typescript --tailwind --eslint --app

# Instalar dependências essenciais
npm install @supabase/supabase-js @supabase/auth-helpers-nextjs zod react-hook-form @hookform/resolvers
npm install @radix-ui/react-* lucide-react date-fns
npm install @google/generative-ai # Gemini API SDK

# Dependências de Escalabilidade
npm install ioredis bullmq

# Dev dependencies
npm install -D @types/node eslint-config-prettier prettier vitest @testing-library/react playwright
2. Configuração de Ambiente
Bash

# .env.local (nunca versionado)
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key

# Chaves de API
GEMINI_API_KEY=your_google_gemini_api_key # Principal
STRIPE_SECRET_KEY=your_stripe_secret
STRIPE_WEBHOOK_SECRET=your_webhook_secret

# Infraestrutura
REDIS_URL=redis://user:password@host:port
3. Configuração do Supabase (Schema Base)
SQL

-- supabase/migrations/001_initial_schema.sql

-- Organizações (Tenants)
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  settings JSONB DEFAULT '{}', -- Contém theme, feature_flags, etc.
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Membros da organização
CREATE TABLE organization_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  UNIQUE(organization_id, user_id)
);

-- Logs de auditoria avançados
CREATE TABLE audit_logs (
  id BIGSERIAL PRIMARY KEY,
  organization_id UUID REFERENCES organizations(id) ON DELETE SET NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  payload JSONB,
  context JSONB, -- Contém IP, user_agent, session_id, etc.
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS em todas as tabelas
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Política de acesso para organizações
CREATE POLICY "Users can access their own organizations"
ON organizations FOR SELECT USING (
  id IN (
    SELECT organization_id FROM organization_members WHERE user_id = auth.uid()
  )
);
🏢 Arquitetura Multi-Tenant
A estratégia de isolamento é baseada em Row Level Security (RLS), onde cada requisição ao banco de dados é automaticamente filtrada pelo organization_id do usuário autenticado. Isso garante que um tenant nunca possa acessar dados de outro.

🔐 Sistema de Permissões
O sistema de papéis e permissões (owner, admin, member) é a base da autorização. O hook useAuthorization abstrai a complexidade de verificar se um usuário pode ou não realizar uma determinada ação.

TypeScript

// src/hooks/useAuthorization.ts
// ... (código do useAuthorization, que já está bem estruturado)
🧩 Módulos de Funcionalidades
Os módulos são gerados dinamicamente pelo saas-cli com base nas especificações do config.json ou nos parâmetros fornecidos.

Módulo	Descrição	Status
Authentication	Login, OAuth, 2FA, Magic Links.	Core (Sempre incluído)
Organizations	Gestão de tenants e membros.	Core (Sempre incluído)
Dashboard	Visão geral com KPIs dinâmicos.	Gerado por IA
Billing	Integração com Stripe/Lemon Squeezy.	Opcional
AI Features	Chat, insights, automações.	Opcional (Gemini)
Reports	Geração de relatórios (PDF/CSV).	Opcional (Usa Fila)

Exportar para as Planilhas
🤖 Integração com IA (Gemini-Powered)
A camada de abstração de IA foi refinada para colocar o Gemini como o provedor principal e usar seu SDK oficial.

TypeScript

// src/services/ai/geminiProvider.ts
import { GoogleGenerativeAI, HarmCategory, HarmBlockThreshold } from "@google/generative-ai";

// Interface comum para todos os provedores
export interface AIProvider {
  generateText(prompt: string, systemPrompt?: string): Promise<string>;
}

export class GeminiProvider implements AIProvider {
  private client: GoogleGenerativeAI;

  constructor(apiKey: string) {
    this.client = new GoogleGenerativeAI(apiKey);
  }

  async generateText(prompt: string, systemPrompt?: string): Promise<string> {
    const model = this.client.getGenerativeModel({
      model: "gemini-1.5-pro-latest", // Usando o modelo mais recente
      systemInstruction: systemPrompt || "You are a helpful assistant integrated into a SaaS application.",
    });

    const result = await model.generateContent(prompt);
    const response = await result.response;
    return response.text();
  }
}
TypeScript

// src/services/ai/aiService.ts
import { GeminiProvider, AIProvider } from './geminiProvider';

class AIService {
  private provider: AIProvider;

  constructor(apiKey: string) {
    // Gemini é o padrão
    this.provider = new GeminiProvider(apiKey);
  }

  async generateInsights(data: any[]): Promise<string> {
    const dataString = JSON.stringify(data, null, 2);
    const prompt = `Analyze this JSON data and provide 3-5 actionable business insights:\n\n${dataString}`;
    const systemPrompt = "You are a world-class data analyst. Your insights should be clear, concise, and directly related to business growth or operational efficiency.";
    return this.provider.generateText(prompt, systemPrompt);
  }
}

export const aiService = new AIService(process.env.GEMINI_API_KEY!);
⚙️ CLI de Desenvolvimento (AI-Enhanced)
O saas-cli é o coração da automação, agora usando o Gemini para gerar código contextual.

Bash

# scripts/cli/commands/generateModule.js
const { aiService } = require('../../../src/services/ai/aiService');

async function handleGenerateModule(options) {
  const { name, type } = options;
  
  // 1. Coletar contexto (schema do DB, módulos existentes, etc.)
  const context = await getProjectContext();

  // 2. Criar um prompt detalhado para o Gemini
  const prompt = `
    Generate a new SaaS feature module named "${name}" of type "${type}".
    The current project context is: ${JSON.stringify(context)}.
    The generated code must follow all patterns and conventions from the framework guide,
    including services, React components with shadcn/ui, hooks, and Vitest tests.
    Return the code as a JSON object where keys are file paths and values are file contents.
  `;
  
  // 3. Chamar o Gemini para gerar o código
  const generatedCodeJSON = await aiService.generateText(prompt, "You are a senior full-stack developer specializing in Next.js and Supabase.");
  
  // 4. Salvar os arquivos no disco
  saveFiles(JSON.parse(generatedCodeJSON));
  
  console.log(`✅ Module "${name}" generated successfully by Gemini!`);
}
Novos Comandos:

npx saas-cli ai:refactor --feature=billing: Usa o Gemini para analisar e refatorar o código de um módulo existente.
npx saas-cli ai:docs --feature=billing: Gera ou atualiza a documentação de um módulo.
🛡️ Resiliência e Escalabilidade
Cache Distribuído (Redis)
O cache em memória foi substituído por uma estratégia de dois níveis para máxima performance.

TypeScript

// src/lib/cache.ts
import Redis from 'ioredis';

class DistributedCacheService {
  private redis: Redis;
  private localCache = new Map<string, { data: any; expires: number }>(); // L1 Cache

  constructor() {
    this.redis = new Redis(process.env.REDIS_URL!);
  }

  async get<T>(key: string): Promise<T | null> {
    // L1: Cache em memória
    const local = this.localCache.get(key);
    if (local && local.expires > Date.now()) {
      return local.data as T;
    }

    // L2: Redis
    const distributed = await this.redis.get(key);
    if (distributed) {
      const data = JSON.parse(distributed);
      this.localCache.set(key, { data, expires: Date.now() + 60 * 1000 }); // Cache local por 1 min
      return data as T;
    }

    return null;
  }
  
  async set<T>(key: string, data: T, ttlSeconds = 300): Promise<void> {
    await this.redis.set(key, JSON.stringify(data), 'EX', ttlSeconds);
    this.localCache.set(key, { data, expires: Date.now() + 60 * 1000 });
  }
}

export const cache = new DistributedCacheService();
Filas de Processamento (BullMQ)
Para tarefas demoradas, usamos filas para não bloquear a thread principal.

TypeScript

// src/lib/queue.ts
import { Queue, Worker } from 'bullmq';
import { aiService } from '../services/ai/aiService';

const connection = { host: 'localhost', port: 6379 }; // Configurar a partir do process.env.REDIS_URL

export const aiQueue = new Queue('ai-jobs', { connection });

// Worker que processa os jobs
new Worker('ai-jobs', async job => {
  if (job.name === 'generateReport') {
    const { data } = job.data;
    await aiService.generateInsights(data); // Exemplo de tarefa longa
  }
}, { connection });
Resiliência (Circuit Breaker)
Para lidar com falhas em serviços externos (como a API de IA).

TypeScript

// src/lib/circuitBreaker.ts
import CircuitBreaker from 'opossum';

const options = {
  timeout: 3000, // Se a função demorar mais que 3s, falha
  errorThresholdPercentage: 50, // Se 50% das requisições falharem, abre o circuito
  resetTimeout: 30000 // Tenta fechar o circuito a cada 30s
};

// Envolve uma chamada de função em um circuit breaker
export function withCircuitBreaker<T extends any[], R>(
  fn: (...args: T) => Promise<R>
): (...args: T) => Promise<R> {
  const breaker = new CircuitBreaker(fn, options);
  breaker.fallback(() => Promise.reject(new Error('Service is currently unavailable.')));
  return (...args: T) => breaker.fire(...args);
}

// Exemplo de uso no aiService
// const generateWithBreaker = withCircuitBreaker(aiService.generateInsights);
🧠 Monitoramento e Observabilidade
A plataforma integra logs estruturados, monitoramento de performance (APM) e um health check detalhado.

Logs: O Logger agora salva logs estruturados com contexto completo na tabela audit_logs.
APM: Integração com Sentry ou similar para rastreamento de erros e performance.
Health Check: O endpoint /api/health verifica a conectividade com o banco de dados, Redis e APIs externas.
🧪 Estratégia de Testes
A estratégia de testes é abrangente, cobrindo desde testes unitários até E2E. O saas-cli pode gerar testes básicos para novos módulos usando o Gemini.

Unitários: Vitest para utilitários e lógica pura.
Componentes: React Testing Library para componentes de UI.
Integração: Testes de fluxo de usuário com mocks da API.
E2E: Playwright para simular a jornada completa do usuário no navegador.
📁 Estrutura de Pastas
A estrutura de pastas foi otimizada para refletir a arquitetura modular e a separação de responsabilidades. (A estrutura fornecida no documento anterior é excelente e permanece como padrão).

🔄 Processo de Desenvolvimento e DevOps
Git Workflow
O fluxo de trabalho baseado em feature-branch com Conventional Commits continua sendo o padrão.

Deploy (Blue-Green)
A pipeline de CI/CD foi aprimorada para uma estratégia Blue-Green no Vercel para deployments de produção sem downtime.

YAML

# .github/workflows/deploy.yml
# ... (jobs de teste)

  deploy-production:
    if: github.ref == 'refs/heads/main'
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Blue Environment
        id: deploy_blue
        run: echo "alias=$(vercel --prod --token ${{ secrets.VERCEL_TOKEN }})" >> $GITHUB_OUTPUT
      
      - name: Run Health Checks on Blue
        run: npm run test:health -- --url ${{ steps.deploy_blue.outputs.alias }}

      - name: Promote Blue to Production
        run: vercel alias set ${{ steps.deploy_blue.outputs.alias }} your-production-domain.com --token ${{ secrets.VERCEL_TOKEN }}
