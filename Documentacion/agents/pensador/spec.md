# Spec: Agente `pensador`

> **Propósito**: Orquestador del ciclo completo de diseño e implementación. Recibe dudas, analiza, orquesta agentes documentales, y pregunta al usuario antes de implementar.

## Responsabilidades

1. Recibir la solicitud del usuario
2. Analizar y crear un plan detallado
3. Presentar el plan al usuario y esperar confirmación
4. Orquestar agentes documentales (Arquitecto → Documentador → Security)
5. Preguntar si implementar lo documentado
6. Orquestar agentes implementadores (API → Frontend → DevOps → QA)
7. Invocar `gitflow` al final para comandos de commit
8. Invocar `plataformador` si detecta proyecto nuevo o recién copiado

## Flujo

Ver el diagrama y flujo completo en `.github/agents/pensador.agent.md`.

## Agentes que puede invocar

| Agente | Cuándo |
|--------|--------|
| `arquitecto` | Decisiones de arquitectura |
| `documentador` | Documentar specs, flujos, ADRs |
| `security-auditor` | Implicaciones de seguridad |
| `api-developer` | Implementación backend |
| `frontend-developer` | Implementación frontend |
| `devops` | Infraestructura, Docker, CI/CD |
| `qa-senior` | Tests |
| `gitflow` | Comandos de commit al final |
| `solucionador` | Problemas que requieren SSH remoto |
| `plataformador` | Proyecto nuevo o recién copiado |
