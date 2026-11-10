# Analyze 044 — Consistencia de artefactos y hallazgos

**Spec**: `spec.md` · **Plan**: `plan.md` · **Tasks**: `tasks.md`

**Fecha**: 2026-11-09 · **Ejecutor**: `arquitecto` + `security-auditor` (analisis no destructivo)

---

## 1. Cobertura requisito -> tarea -> criterio

| Requisito | Tareas | AC | Estado |
|---|---|---|---|
| RF-01 universo `git ls-files` | T003, T005, T006 | AC-1, AC-2, AC-3 | Cubierto |
| RF-02 patrones por fragmentos | T004 | AC-1 | Cubierto |
| RF-03 bootstrap sobre todo el proyecto | T008 | AC-7, AC-8 | Cubierto |
| RF-04 audit log fuera de versionado | T010, T012 | AC-5 | Cubierto |
| RF-05 eliminar artefactos `.specify` | T011 | AC-4 | Cubierto |
| RF-06 `opencode.json` portable | T013, T014, T017 | AC-6 | Cubierto |
| RF-07 `.mcp.json` portable | T015 | AC-6 | Cubierto |
| RF-08 script con default del kit | T018 | AC-1 | Cubierto |
| RF-09 fixture redactado | T019 | AC-1 | Cubierto |
| RF-10 redaccion documental | T020, T021, T022 | AC-1, AC-4 | Cubierto |
| RF-11 CI | T024 | AC-10 | Cubierto |
| RF-12 bootstrap informa `0/N` | T008 | AC-7 | Cubierto |

**Cobertura: 12/12 requisitos (100%), 10/10 criterios (100%).**

## 2. Hallazgos

| ID | Severidad | Hallazgo | Resolucion |
|---|---|---|---|
| A1 | **HIGH** | La lista de patrones del spec (2 clases de ruta del autor + `D:` + 2 prefijos POSIX) **no cubre** rutas absolutas reales presentes hoy: `<letra>:/Program Files/...` y `<letra>:/Python314/...` en `opencode.json` y `.mcp.json`. Con la lista del spec, portabilizar solo las entradas ya listadas dejaria el kit igual de no portable | Plan §4.2 amplia la lista con las cuatro raices reales de la maquina del autor (raiz de proyectos, perfil de usuario, interprete Python, runtime Node), conserva `D:` completo como unidad ajena y mantiene los prefijos POSIX. Se descarto prohibir toda letra de unidad: los ejemplos genericos de las skills no filtran el layout y obligarian a reescribir documentacion legitima sin ganancia de seguridad |
| A2 | MEDIUM | El spec dice "cero exclusiones" y el plan excluye binarios por contenido (R2) | Justificado: un binario no es documentacion ni configuracion; la exclusion es **por contenido**, no por ubicacion. No abre la puerta a excluir directorios |
| A3 | MEDIUM | `.bootstrap-audit.log` tiene cadena de hashes: si alguien "limpiara" el archivo para pasar el test, destruiria la evidencia | El plan prohibe reescribirlo y lo saca del indice git (D3). El archivo nunca se toca |
| A4 | MEDIUM | `opencode.json` con tokens + `enabled:false` degrada MCPs hasta que corra el bootstrap; el usuario podria percibirlo como regresion | Degradacion **explicita y visible**, con WARN del bootstrap y rollback documentado. Alternativa (dejar literales) viola R4/R5 |
| A5 | LOW | El spec 039 queda con AC superados; riesgo de que alguien lo lea como "ya resuelto" | Se anota la supersesion en el propio 039 y en la entrada del indice |
| A6 | LOW | Terminologia: "hardcoded", "absolutas", "fijas" | Se unifica en "ruta absoluta literal" en los artefactos de la 044; los historicos se respetan |
| A7 | LOW | T020 (redaccion de 24 archivos) puede introducir cambios semanticos inadvertidos | T022 exige revision hunk por hunk y `--stat`; solo lineas con rutas |
| A8 | LOW | El fallback sin git podria recorrer arboles enormes en un proyecto real | Solo se activa cuando no hay repo git; el bootstrap trabaja normalmente sobre repos versionados |

## 3. Consistencia entre artefactos

| Verificacion | Resultado |
|---|---|
| Toda tarea del plan (§12) existe en tasks.md | Si, T001..T028 cubren T01..T15 |
| Todo RF del spec aparece en el plan | Si, §5, §6, §8, §9 y §10 |
| Todo AC es verificable con un comando | Si, plan §11 |
| El plan introduce rutas literales | No: usa tokens y fragmentos (§4.2, §9) |
| Las decisiones D1-D6 del spec se reflejan en el plan | Si: D1 §4, D2 §5, D3 §7, D4 §7, D5 §9, D6 §4.5 |
| Hay tareas sin agente asignado | No |
| Hay tareas sin verificacion | No |

## 4. Threat model resumido (STRIDE)

| Categoria | Amenaza | Riesgo | Mitigacion en esta spec |
|---|---|---|---|
| Information disclosure | El repo publicado revela nombre de usuario del SO y layout del disco del autor | **Alto** | Redaccion (RF-10), configs portables (RF-06/RF-07), audit log fuera de versionado (RF-04) |
| Tampering | Reescribir el audit log para "limpiar" rutas rompe la cadena de hashes | Alto | Prohibido por D3; solo `git rm --cached` |
| Elevation of privilege / supply chain | Rutas absolutas a binarios del autor permiten suplantacion si el consumidor hereda una ruta escribible | Medio | Tokens resueltos localmente desde `.env.mcp` (no versionado) |
| Denial of service (config) | MCP con comando inexistente en destino: arnes arranca roto | Medio | `enabled:false` + WARN accionable |
| Repudiation | "El test estaba verde" sin universo real | **Alto** | Universo `git ls-files` + auto-inclusion (R1, R3) |
| Spoofing de cobertura | Excluir un directorio para pasar el test | Alto | No hay allowlist; el test se autovalida |

**Riesgos `security-risk:` derivados**: SR-044-01 (fuga de layout del FS), SR-044-02 (falso verde de portabilidad), SR-044-03 (dependencia de rutas escribibles del autor), SR-044-04 (degradacion silenciosa de MCP).

## 5. Veredicto

**PASS con 1 accion obligatoria**: aplicar A1 (patrones generalizados a cualquier letra de unidad) durante la implementacion. Sin A1, el paquete seria internamente consistente pero funcionalmente insuficiente: declararia portabilidad y dejaria rutas absolutas vivas en las dos configuraciones de arnes.
