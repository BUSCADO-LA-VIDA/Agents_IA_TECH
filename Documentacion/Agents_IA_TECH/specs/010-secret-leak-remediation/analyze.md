# Analyze: Remediación de fuga de secreto

## Consistencia de artefactos
- spec.md define FR-001 a FR-006, plan.md cubre 5 fases, tasks.md desglosa 15 tareas. Coherente.

## ADRs
ADR-001: Uso de git filter-repo para remediación de secretos
- Decisión: reescribir historial en lugar de solo borrar archivo.
- Justificación: gitleaks escanea historial completo.
- Consecuencias: requiere force push y coordinación.

ADR-002: Allowlist en gitleaks
- Decisión: crear .gitleaks.toml con exclusiones para archivos locales.
- Justificación: evitar falsos positivos en .env.mcp y .bootstrap-state.json.

## Threat Model STRIDE
- **Spoofing**: API key filtrada permite suplantación → mitigado rotando clave.
- **Information Disclosure**: historial contiene secreto → mitigado con filter-repo.
- **Tampering**: reescritura de historial → mitigado con --force-with-lease y backup.

## Riesgos etiquetados
security-risk: reescritura de historial puede desincronizar colaboradores.
security-risk: API key aún activa hasta rotación.

## Guardrails
- No versionar archivos con rutas locales.
- No commitear archivos temporales.
- Ejecutar gitleaks pre-commit.
