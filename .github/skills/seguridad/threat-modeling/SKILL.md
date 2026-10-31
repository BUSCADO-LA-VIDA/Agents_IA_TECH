---
name: threat-modeling
description: "Use when: analyzing security risks of a design, building a threat model, applying STRIDE, or documenting mitigations for a spec before implementation."
user-invocable: true
---

# Threat Modeling

## When to Activate

- En la fase `speckit-analyze`, antes de aprobar un `plan.md` con impacto de seguridad
- Al diseñar autenticación, autorización, pagos, datos personales o integraciones externas
- Antes de exponer un servicio nuevo a Internet o cambiar su superficie de red
- Al incorporar una dependencia, MCP o servicio de terceros al proyecto
- Cuando el usuario pide "analizar riesgos", "modelo de amenazas" o "qué puede salir mal"

## Core Concepts

### Flujo obligatorio (5 pasos)

```
1. Alcance      → qué componente, límites de confianza y datos que toca
2. Diagrama     → flujo de datos (DFD): actores, procesos, almacenes, cruces de frontera
3. Amenazas     → STRIDE por cada elemento del diagrama
4. Evaluación   → probabilidad x impacto, riesgo inherente vs. residual
5. Mitigación   → control concreto + dueño + verificación
```

Sin los 5 pasos el modelo está incompleto. Un listado de amenazas sin mitigación verificable no es un threat model.

### STRIDE — qué buscar en cada categoría

| Categoría | Amenaza | Ejemplo concreto | Control típico |
|---|---|---|---|
| **S**poofing | Suplantar identidad | Token de sesión robado | MFA, rotación de sesión, TLS mutuo |
| **T**ampering | Alterar datos o código | Modificar un payload en tránsito | Firmas, hashes, checks de integridad |
| **R**epudiation | Negar una acción | Borrar un registro sin rastro | Audit log inmutable, timestamps firmados |
| **I**nformation disclosure | Filtrar información | Stack trace con credenciales en el error | Manejo de errores, cifrado, minimización |
| **D**enial of service | Agotar recursos | Endpoint público sin rate limit | Rate limiting, cuotas, timeouts, backpressure |
| **E**levation of privilege | Ganar permisos indebidos | IDOR al cambiar un `id` en la URL | Autorización server-side por objeto |

### Fronteras de confianza (trust boundaries)

Marcar explícitamente dónde cambia el nivel de confianza. Toda amenaza relevante cruza al menos una:

- Navegador → API pública
- API → base de datos
- Backend → servicio externo / MCP / LLM
- Agente de IA → shell, sistema de archivos, servidor remoto
- Operador humano → entorno de producción

### Registro de riesgos (formato mínimo)

```markdown
| ID | Activo | Amenaza (STRIDE) | Prob. | Impacto | Riesgo | Mitigación | Verificación | Estado |
|----|--------|------------------|-------|---------|--------|------------|--------------|--------|
| T-01 | Token de sesión | I - disclosure | Alta | Alto | Crítico | Cookies HttpOnly + Secure, rotación | Test e2e: cookie sin JS | Abierto |
```

Reglas del registro:

- `Riesgo = Prob. x Impacto` (Baja/Media/Alta/Crítica), sin promedios ni "riesgo general"
- Cada fila tiene **una** mitigación verificable; si no se puede verificar, no está mitigada
- Los riesgos aceptados se registran con `Estado: Aceptado` + decisión y fecha del usuario
- Los riesgos de seguridad abiertos se etiquetan `security-risk:` para que `speckit-analyze` los bloquee

### Integración con el ciclo SSD + Speckit

| Fase | Qué aporta threat-modeling |
|---|---|
| `speckit-specify` | Identifica activos y datos sensibles → requisitos de seguridad en `spec.md` |
| `speckit-plan` | Valida fronteras de confianza de la arquitectura propuesta |
| `speckit-analyze` | Produce el threat model y los riesgos etiquetados `security-risk:` |
| `speckit-tasks` | Convierte cada mitigación en task verificable |
| `speckit-converge` | Confirma que toda mitigación quedó implementada y probada |

El `security-auditor` es el dueño del artefacto; el `pensador` no lo reescribe, lo delega.

## Anti-Patterns

- "Threat model" que solo lista amenazas sin mitigación ni verificación
- Modelar solo la infraestructura y olvidar el código de aplicación y los agentes de IA
- Asumir que la red interna es confiable (rompe el modelo Zero Trust)
- Copiar un threat model de otro proyecto sin rehacer el DFD
- Marcar todo como "riesgo bajo" para poder avanzar
- Diferir la mitigación "para después" sin registrarla como riesgo aceptado
- Confundir escaneo de dependencias (`security-scan`) con modelado de amenazas

## Checklist de salida

- [ ] Alcance y fronteras de confianza escritos
- [ ] DFD con actores, procesos, almacenes y flujos
- [ ] Las 6 categorías STRIDE evaluadas por elemento
- [ ] Registro de riesgos con probabilidad, impacto y riesgo calculado
- [ ] Cada riesgo abierto tiene mitigación + verificación + dueño
- [ ] Riesgos aceptados documentados con decisión del usuario
- [ ] Etiquetas `security-risk:` aplicadas para `speckit-analyze`
- [ ] Artefacto guardado en `Documentacion/<AppName>/seguridad/threat-model-<feature>.md`
