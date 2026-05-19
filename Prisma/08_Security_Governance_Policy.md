# Política de Segurança e Governança

## 1. Proteção de Dados
* **Regra:** Documentos da pasta `/docs` (PI do Prisma) NUNCA devem ser enviados para APIs públicas de LLM. A vetorização deve ser feita localmente via Docker/Gemma.

## 2. Controle de Acesso
* **Regra:** O Agente TRM só pode escrever na pasta `/src`. Acesso a arquivos de sistema (`.env`) é proibido.

## 3. Visibilidade
* **Regra:** Toda decisão de arquitetura deve ser logada na tabela `factory_audit_logs`.