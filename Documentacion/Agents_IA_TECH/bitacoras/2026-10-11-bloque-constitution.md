# Bitacora 2026-10-11 — Bloque constitution 3 niveles (002-T032..T035)

## Regla vigente (del usuario)
| Nivel | Path | Propiedad | Versiona |
|-------|------|-----------|----------|
| 1. Original KIT | `.specify/memory/constitution.md` | Del KIT, `sync-kit.ps1` lo replica a todos los proyectos | Si |
| 2. Por APP | `Documentacion/<App>/.specify/constitution.md` | Propio de cada APP, se conserva aqui | Si |
| 3. Runtime agente | `src/<App>/.specify/constitution.md` | Copia del script desde nivel 2 | No — se ignora en el `.gitignore` dentro de `src/<App>` |

## T032 — Sincronizar (parcial: niveles 1-2 hechos, hook del script pendiente)
- Sembrado `Documentacion/Agents_IA_TECH/.specify/constitution.md` desde la raiz.
- SHA256 origen = destino (`89CFE451...A84A55B5`), 194 lineas. Identicos.
- Pendiente (tier Plataforma/`plataformador`): hook en `plataformador-bootstrap.ps1` que copie nivel 2 -> nivel 3 cuando exista `src/<App>/`. Editar `scripts/` excede mi whitelist documental (Art-VII), por eso no lo implemento yo: queda especificado aqui como delegacion.
- Estado en backlog: `[ ]` (no se marca [x] sin el hook).

## T033 — Verificar 3 ubicaciones
- L1 raiz KIT: EXISTE (194 lineas).
- L2 Documentacion/APP: EXISTE (sembrado hoy, hash igual al original).
- L3 src/APP: N/A — no hay `src/` en el kit (sin apps desplegadas).
- Estado en backlog: `[ ]` hasta que el hook exista y haya src que verificar. La evidencia de L1+L2 queda registrada aqui.

## T034 — Gitignore
- Raiz `.gitignore` NO ignora `constitution.md`: correcto (el original del KIT se versiona).
- Regla para futuros `src/<App>/.gitignore`: ignorar `.specify/constitution.md` (nivel 3 es copia runtime; el original se conserva en Documentacion).
- Sin `src/` no hay archivo que editar hoy; la regla queda especificada aqui.
- Estado en backlog: `[ ]` (se cierra cuando exista src y se aplique la regla).

## T035 — Documentar ruta en AGENTS.md
- `AGENTS.md` L98 solo dice "`.specify/` por proyecto" sin la ruta de 3 niveles.
- Texto propuesto para AGENTS.md (no aplicado: excede mi whitelist, requiere decision del usuario o ejecucion por tier habilitado):
  > `.specify` en 3 niveles: (1) raiz del KIT `.specify/memory/constitution.md` = original versionado que `sync-kit.ps1` replica; (2) `Documentacion/<App>/.specify/constitution.md` = propio de cada APP y versionado; (3) `src/<App>/.specify/constitution.md` = copia runtime del script, ignorada en el `.gitignore` de `src/<App>`. No se pierde porque se conserva en Documentacion.
- Estado en backlog: `[ ]`.

## Conclusion honesta
No marco ninguna de las 4 como [x]: el seed L1->L2 esta hecho y verificado, pero el hook del script, la verificacion L3 con src real, la edicion de gitignore en src y la edicion de AGENTS.md siguen pendientes. Marcarlas cerradas seria repetir el error de las falsas marcadas que ya corregi (002-T032/T034).
