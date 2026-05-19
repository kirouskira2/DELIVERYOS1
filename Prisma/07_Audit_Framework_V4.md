1. 🧠 Análise de Contexto
Objetivo do Documento: O 07_Audit_Framework_V4.md é a "Constituição" do Prisma. É o conjunto de leis que o agente TRM deve obedecer durante seu loop de auto-correção (z -> y).

Fontes Primárias (Memória):

Governança: As "5 Regras de Ouro" (especialmente Risco Contextual e Proteção de Dados).


Lógica SAP: A proibição absoluta de hard-coding de regras de negócio . O código deve falhar se tiver um if (valor > 1000).

Design-First: A exigência de fidelidade visual ao protótipo Stitch e uso de MCPs.

Infraestrutura: Verificação de segurança (chaves de API, portas expostas).

2. 📝 Rascunho Mental (Auto-Crítica V4)
Seção 1: Arquitetura de Negócio (O Diferencial V4). Esta é a seção mais importante. Preciso criar uma regra binária: "Tem regra hard-coded? FALHA. Usa Agente de Política? PASSA."

Seção 2: Qualidade de Código. TypeScript estrito, sem any. Comentários explicativos (não apenas "o que", mas "por que").

Seção 3: Visual. Comparação com o prototype.html. Uso correto das bibliotecas Tremor/Magic UI.

Refinamento: Adicionar uma seção de "Segurança de Dados" para garantir que o agente não está vazando PI para logs ou APIs externas.

3. 💎 Geração Final: 07_Audit_Framework_V4.md
Markdown

# Framework de Auditoria e Qualidade Prisma V4

Este documento é a "Lei Suprema" do Prisma. O `Agente Cognitivo TRM` **DEVE** usar este checklist em cada ciclo de auto-correção. Se qualquer item crítico falhar, o código deve ser rejeitado e refinado.

---

## 1. Auditoria de Arquitetura de Negócio (Crítico V4)
*Esta seção garante que estamos construindo uma Plataforma de Agentes (BPA), não um monolito legado.*

- [ ] **Proibição de Hard-Coding:** O código contém valores de negócio fixos (ex: taxas, limites, prazos)?
    * *Falha:* `if (order.total > 500)`
    * *Passa:* `const policy = await policyAgent.consult(order)`
- [ ] **Abstração de Agente:** A lógica de decisão complexa está encapsulada em um serviço de "Agente de Política" separado?
- [ ] **Fonte de Verdade Externa:** O agente consulta uma base de conhecimento (RAG do Cliente) ou configuração dinâmica antes de tomar uma decisão?

## 2. Auditoria de Segurança e Governança (5 Regras de Ouro)
- [ ] **Proteção de Credenciais:** Existe alguma chave de API, token ou senha hard-coded? (Deve usar variáveis de ambiente `process.env`).
- [ ] **Sanitização de Input:** Os dados que entram nos Agentes (especialmente para o RAG) são sanitizados para prevenir *Prompt Injection*?
- [ ] **Segurança de RLS:** (Para Backend) As políticas de Row Level Security do Supabase estão definidas para garantir que usuários só acessem seus próprios dados?

## 3. Auditoria de Frontend (Design-First & MCPs)
- [ ] **Fidelidade Visual:** O componente React corresponde visualmente à estrutura do `prototype.html` (Stitch)?
- [ ] **Uso de MCPs:** O código utiliza os componentes premium do registro `03_MCP_Component_Registry.md`?
    * *Verificação:* Gráficos usam **Tremor**? Animações de Hero usam **Magic UI**?
- [ ] **Responsividade:** O layout funciona corretamente em Mobile e Desktop (classes Tailwind `md:`, `lg:`)?

## 4. Qualidade de Código e Manutenibilidade
- [ ] **Tipagem Estrita:** O código TypeScript está livre de `any` implícito? As interfaces estão definidas?
- [ ] **Documentação de Intenção:** O código possui comentários (JSDoc) explicando o *porquê* das decisões arquiteturais (ex: "Delega para o Agente Financeiro para permitir ajuste de regras pelo cliente")?
- [ ] **Modularidade:** O código segue o princípio de responsabilidade única? (Componentes de UI separados de Lógica de Agente).

---

## Protocolo de Falha
Se **qualquer** item das seções 1 ou 2 falhar, o Agente TRM deve imediatamente descartar o rascunho e iniciar uma nova iteração de raciocínio (`z`), focando especificamente na correção da violação.
4. ✅ Checklist de Validação
Regra Anti-Hard-Code: A proibição de lógica de negócio fixa está explícita e com exemplos de falha/sucesso? SIM.

Alinhamento de Infra: A verificação de RLS e variáveis de ambiente protege a infraestrutura definida no 02? SIM.

Design Check: A auditoria visual exige o uso dos MCPs definidos no 03? SIM.