# Tasks 026 - Agente developer único

## Tareas de diseño y validación
- T-01 Crear research.md con validación de skills y context7
- T-02 Generar data-model.md del agente developer y mapeo skills
- T-03 Definir contracts de paridad harnesses .github ↔ .opencode
- T-04 Crear quickstart.md de validación de invocación skill + context7

## Tareas de implementación
- T-05 Actualizar agente developer.agent.md y developer.md con skills especializadas y sección Rol Scrum
- T-06 Actualizar Constitución Art.VII whitelist Implementador a agente developer único
- T-07 Eliminar agentes obsoletos api-developer.agent.md, frontend-developer.agent.md, devops.agent.md, qa-senior.agent.md de .github/agents/ y .opencode/agents/
- T-08 Actualizar Documentación/Agents_IA_TECH/00-indice.md con estado de Spec 026
- T-09 Ejecutar sync-kit-agents.ps1 -RootPath Generator_IA_Projects -Force para propagar eliminación
- T-10 Validar paridad harnesses y ausencia de agentes obsoletos en destino
- T-11 QA-senior verifica compliance Constitución y sincronía harnesses
- T-12 Cerrar spec 026 en pendientes-implementacion.md

## Dependencias
- T-01 → T-02 → T-03 → T-04
- T-05 depende de T-04
- T-06 depende de T-05
- T-07 depende de T-06
- T-08 → T-09 → T-10 → T-11 → T-12
