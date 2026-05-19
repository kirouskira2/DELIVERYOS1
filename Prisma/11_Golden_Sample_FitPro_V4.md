3. 💎 Geração Final: 11_Golden_Sample_FitPro_V4.md
Este documento deve ser salvo na pasta /docs. Ele servirá como o modelo mental para o Trae entender o que é "código certo" e "código errado" na V4.

Markdown

# Exemplo de Ouro: Arquitetura V4 no FitPro Manager

Este documento serve como o "Gabarito Prático" e a "Fonte da Verdade Arquitetural" para o Agente Cognitivo TRM. Ele demonstra como transformar uma regra de negócio rígida em um Agente de Política flexível.

**CONTEXTO DO EXEMPLO:**
O "FitPro Manager" precisa automatizar a progressão de carga dos alunos.
* *Cenário:* O aluno termina um treino e avalia o exercício como "Fácil".
* *Objetivo:* O sistema deve decidir se aumenta o peso para o próximo treino.

---

## 1. O ERRO (Abordagem V2 - Legado)
*Esta abordagem é PROIBIDA na V4. O código abaixo falharia na Auto-Auditoria.*

**Arquivo:** `src/controllers/WorkoutController.ts`

```typescript
// ❌ ERRO: Regra de negócio Hard-Coded
export async function finishWorkout(workoutId: string, feedback: string) {
  const workout = await db.getWorkout(workoutId);

  // O desenvolvedor "chumbou" a regra no código.
  // Se o Personal quiser mudar para "Muito Fácil" ou aumentar 2kg,
  // ele precisa contratar o desenvolvedor de novo.
  if (feedback === 'Fácil' && workout.lastWeight < 50) {
      const newWeight = workout.lastWeight + 2; // Aumento fixo de 2kg
      await db.updateNextWorkout(workout.studentId, { weight: newWeight });
  }
}
2. O ACERTO (Abordagem V4 - Agentes de Política)
Esta é a abordagem OBRIGATÓRIA. A lógica é delegada a um agente que lê regras dinâmicas.

A. A Regra de Negócio (Run-Time)
O Personal Trainer escreve isso em um arquivo de texto/PDF e faz upload no Dashboard.

Arquivo (RAG do Cliente): metodologia_hipertrofia.txt

"Para alunos de nível Intermediário: Se o aluno reportar que o exercício foi 'Fácil' ou 'Muito Fácil' por duas sessões consecutivas, aplique a sobrecarga progressiva. Aumente a carga em 5% (arredondando para cima). Nunca aumente a carga se o aluno relatou dor articular."

B. O Agente de Política (Microsserviço)
O Prisma gera este código.

Arquivo: supabase/functions/policy-agent-workout/index.ts

TypeScript

// ✅ ACERTO: Agente de Política Abstrato
import { serve } from "[https://deno.land/std@0.168.0/http/server.ts](https://deno.land/std@0.168.0/http/server.ts)"
import { GoogleFileSearch } from "../_shared/google-rag"; // Nossa lib interna

serve(async (req) => {
  const { context } = await req.json(); // Dados do treino atual + histórico

  // 1. Consulta o RAG do Cliente (O documento de texto)
  const rules = await GoogleFileSearch.query({
    query: "Regra para aumento de carga e sobrecarga progressiva",
    fileIds: context.knowledgeBaseIds
  });

  // 2. O LLM decide com base no texto recuperado
  const decision = await LLM.generate({
    system: "Você é um Treinador Especialista. Aplique as regras do contexto estritamente.",
    prompt: `
      Contexto do Aluno: ${JSON.stringify(context.studentData)}
      Feedback Atual: ${context.currentFeedback}
      Regras do Personal: ${rules.text}

      Decisão (JSON):
      { "action": "INCREASE_WEIGHT" | "MAINTAIN" | "DECREASE", "value": number, "reason": string }
    `
  });

  return new Response(JSON.stringify(decision));
});
C. A Integração (Código Principal)
O código da aplicação apenas orquestra.

Arquivo: src/app/api/workouts/finish/route.ts

TypeScript

// ✅ ACERTO: Orquestração Limpa
export async function POST(req: Request) {
  const { workoutData } = await req.json();

  // O código não sabe a regra. Ele pergunta ao Agente.
  const policyResponse = await fetch(`${process.env.SUPABASE_URL}/functions/v1/policy-agent-workout`, {
      body: JSON.stringify({ context: workoutData })
  });

  const { action, value, reason } = await policyResponse.json();

  // Executa a decisão do agente
  if (action === 'INCREASE_WEIGHT') {
    await db.updateNextWorkout({ weight: value });
    // Loga a decisão para o Personal ver no Dashboard
    await AgentLogger.log(`Agente ajustou carga para ${value}kg. Motivo: ${reason}`);
  }
}
3. A Interface Visual (Design-First)
No Centro de Controle de Agentes (Dashboard), o Personal Trainer veria:

Card de Atividade: "O Agente de Treino ajustou o Supino de João para 42kg."

Botão de Ação: "Ver Motivo" -> Clicar abre: "Baseado na regra do seu documento 'metodologia_hipertrofia.txt': aumento de 5% após feedback 'Fácil'."

Área de Upload: "Arraste aqui novos PDFs para ensinar novas regras ao seu agente."


---

### **4. ✅ Checklist de Validação**

1.  **Contraste Claro:** O documento mostra explicitamente o "antes" (hard-code) e o "depois" (agente)? **SIM.**
2.  **Integração RAG:** O código do Agente demonstra a consulta ao `GoogleFileSearch` (Pilar 2)? **SIM.** [cite: 316-320, 960, 969]
3.  **Fidelidade SAP:** A estrutura reflete a ideia de "Agentes Especializados" orquestrados? **SIM.** [cite: 923-924, 957-962]

---

O "Gabarito de Ouro" está pronto. Este exemplo é a bússola que impedirá o Trae de se perder.

**Falta apenas o último arquivo: `99_Prisma_V4_Master_Prompt.txt` (O Gatilho Final).