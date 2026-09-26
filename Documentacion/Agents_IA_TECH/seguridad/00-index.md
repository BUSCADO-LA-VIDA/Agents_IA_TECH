# Índice de Seguridad — Agents_IA_TECH

**Versión:** 1.0.0  
**Fecha:** 2026-09-25  
**Mantenido por:** security-auditor  

---

## Threat Models

| ID | Archivo | Spec/Feature | Estado |
|----|---------|--------------|--------|
| TM-007 | `007-mcp-token-resolution-threat-model.md` | MCP Token Resolution (ADR-0006) | ✅ Activo |
| **TM-011** | **`011-bootstrap-upgrade-framework-threat-model.md`** | **Bootstrap invokes upgrade_framework (Spec #011)** | **✅ Activo** |

---

## Guías de Seguridad (Security Guidelines)

| Archivo | Descripción | Referencia Threat Model |
|---------|-------------|------------------------|
| `supply-chain-security-guidelines.md` | Guía canónica: allowlist, firmas, containment, fail-open, secrets, build isolation | TM-007, TM-011 |
| `manifest-security.md` | Esquema seguro para `dependencias-manifest.yml` (sin secrets, con integrity, cosign) | TM-011 (I-01, S-04) |
| `proyect_ext-containment.md` | Reglas absolutas de contención para `proyect_ext/` (realpath, no symlinks, git hardening) | TM-011 (T-04, E-02) |
| `audit-logging-standard.md` | Formato JSON Lines inmutable, hash chain, correlación bootstrap↔upgrade_framework | TM-011 (R-01, R-02, R-03) |
| `fail-open-pattern.md` | Patrón canónico fail-open con matriz de operaciones y validaciones | TM-011 (D-01, RF-02) |

---

## Documentos Históricos / Referencia

| Archivo | Descripción |
|---------|-------------|
| `blindaje-git.md` | Protección de repositorio git (hooks, signed commits, branch protection) |
| `cambio-vision.md` | Análisis de cambio de visión arquitectónica |
| `context-mode.md` | Documentación MCP context-mode |
| `ecosistema-documentacion.md` | Visión general del ecosistema documental |
| `flujo-contexto.md` | Flujos de contexto entre agentes |
| `graphify.md` | Documentación graphify |
| `huerfanos.md` | Análisis de documentos huérfanos |
| `kit-gaps.md` | Gaps identificados en el kit |
| `metodologia-ssd.md` | Metodología Spec-Driven Development |
| `plataforma-bootstrap.md` | Documentación plataforma bootstrap |
| `post-plataformado.md` | Post-plataformado Speckit |
| `relocate-cleanup.md` | Limpieza de relocalización |
| `relocate-locks.md` | Locks de relocalización |
| `relocate.md` | Relocalización |
| `solucion-generica.md` | Solución genérica |
| `tokenslayer.md` | Documentación tokenslayer |

---

## Referencias Cruzadas por Spec

### Spec #011 — Bootstrap invokes upgrade_framework

```
Threat Model:     specs/011-bootstrap-invokes-upgrade-framework/threat-model.md
Security Risks:   specs/011-bootstrap-invokes-upgrade-framework/tasks.md (sección Security Risks)
ADR:              arquitectura/adr/adr-0007-bootstrap-delegates-upgrade-framework.md
Guidelines:       seguridad/supply-chain-security-guidelines.md
Manifest Schema:  seguridad/manifest-security.md
Containment:      seguridad/proyect_ext-containment.md
Audit Log:        seguridad/audit-logging-standard.md
Fail-Open:        seguridad/fail-open-pattern.md
```

### Spec #007 — MCP Token Resolution (ADR-0006)

```
Threat Model:     seguridad/007-mcp-token-resolution-threat-model.md
ADR:              arquitectura/adr/adr-0006-mcp-token-resolution.md
```

---

## Constitution Art.V Validation Dashboard

| Spec | Secrets Mgmt | Encryption | AuthZ/AuthN | Audit Logging | Supply Chain | Bloqueadores |
|------|--------------|------------|-------------|---------------|--------------|--------------|
| #007 | ✅ | ✅ | ✅ | ✅ | ✅ | Ninguno |
| #011 | ⚠️ Parcial | ✅ | ⚠️ Parcial | ⚠️ Parcial | ⚠️ Parcial | **5 CRITICAL** (ver TM-011 Sección 7) |

---

## Próximas Revisiones Programadas

| Fecha | Evento | Responsable |
|-------|--------|-------------|
| 2026-10-25 | Revisión mensual threat models | security-auditor |
| 2026-11-25 | Rotación allowlist URLs + revisión dependencias | security-auditor + upgrade_framework |
| 2026-12-25 | Auditoría supply chain completa | security-auditor + arquitectos |

---

*Actualizado automáticamente por security-auditor al generar threat models*