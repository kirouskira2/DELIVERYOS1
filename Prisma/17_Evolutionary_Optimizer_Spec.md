# Especificação do Otimizador Evolutivo (Feed-Forward)

## 1. Conceito
Transformar o Prisma de um sistema reativo (corrige erros) em um sistema proativo (busca melhoria).

## 2. Arquitetura de Testes A/B
O Orquestrador implementa um `ExperimentNode`.
* **Regra dos 5%:** Em 5% das tarefas de risco médio, o sistema executa dois prompts em paralelo:
    * **A (Controle):** Prompt atual.
    * **B (Desafiante):** Prompt experimental (ex: nova técnica de Chain-of-Thought).

## 3. Critérios de Vitória
O sistema compara os resultados automaticamente:
* **Qualidade:** (Peso 50%) Score do Auditor.
* **Eficiência:** (Peso 30%) Número de iterações TRM.
* **Custo:** (Peso 20%) Consumo de tokens.

## 4. Promoção Automática
Se a Variante B vencer consistentemente, o **Branchlet** cria um Pull Request atualizando a biblioteca de prompts `12_Prompt_Engineering_Library.md` com a nova melhor prática.