# Framework de Decisão Arquitetural (ADR Generator)

## 1. O Objeto de Decisão (Output)
O Auditor Contextual retorna um JSON que define o modo de operação da fábrica:
```json
{
  "decision_id": "uuid",
  "selected_target": "V4_GOVERNANCE", // ou V3_SERVICE ou HYBRID
  "confidence_score": 0.95,
  "reasoning": "O briefing menciona compliance financeiro."
}
2. Heurísticas de Classificação
⚡ Sinais para Target V3.1 (Service Logic)
Palavras-chave: "MVP", "Protótipo", "Rápido", "Landing Page".

Cenário: Ferramentas de marketing, scripts pessoais.

Risco: Baixo.

🛡️ Sinais para Target V4 (Governance Logic)
Palavras-chave: "Compliance", "Auditoria", "Regulação", "Aprovação", "Hierarquia".

Cenário: Sistemas financeiros, RH, Saúde, ERPs.

Risco: Alto.

🔄 Sinais para Target Híbrido (V4.1 - Regra 80/20)
Cenário: Sistema complexo com módulos estáticos.

Ação: Núcleo V4 (Agentes) + Módulos V3.1 (Código Rápido).

Regra: Se a regra é volátil (preço), use Agente. Se é estática (login), use Código.