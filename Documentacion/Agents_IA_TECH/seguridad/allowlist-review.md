# Proceso de Revisión Trimestral de Allowlist (T064)

## Objetivo
Mantener la allowlist de owners de GitHub confiables actualizada, segura y alineada con riesgos de supply chain.

## Frecuencia
Trimestral (cada 3 meses). Próxima revisión: 2027-01-04.

## Responsables
- Security Auditor
- DevOps Lead
- Arquitecto de Plataforma

## Procedimiento

1. **Inventario**
   - Exportar lista actual de `$TrustedOwners` desde `upgrade_framework.ps1`.
   - Recopilar dependencias activas en manifests de proyectos consumidores.

2. **Evaluación de riesgo**
   - Verificar reputación de owners, historial de compromisos firmados, presencia de 2FA, y políticas de seguridad.
   - Revisar incidentes de supply chain en últimos 90 días.

3. **Decisiones**
   - Añadir owners nuevos solo con justificación documentada.
   - Retirar owners inactivos o con riesgo elevado.
   - Registrar cambios en `Documentacion/Agents_IA_TECH/seguridad/allowlist-changelog.md`.

4. **Aprobación**
   - Pull Request con cambios debe ser revisado por al menos 2 responsables.
   - Validar que tests de allowlist (`Test-TrustedGithubUrl`) pasan.

5. **Comunicación**
   - Notificar a equipos de desarrollo sobre cambios.
   - Actualizar `upgrade_framework.sha256` tras cambios.

## Criterios de inclusión
- Owner con historial >1 año sin incidentes.
- Repositorios con firmas GPG en commits.
- Cumple con políticas de seguridad del kit.

## Registro
Cada revisión debe dejar acta con fecha, participantes, decisiones y hash de allowlist.

## Fail-open
Si la revisión no se completa en plazo, la allowlist anterior permanece vigente y se registra advertencia en audit log.
