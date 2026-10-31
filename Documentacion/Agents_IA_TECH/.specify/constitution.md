# Art. X — Expansión del Implementador por Tipo de Proyecto (enmienda 2.1.0)

**Contexto:** Art. X original declaraba una excepción para el proyecto kit por falta de `src/<App>/`. Esta enmienda reemplaza la excepción por una regla de resolución contextual.

### A. Expansión en el proyecto kit
En un proyecto con `proyecto_tipo = kit`:
- El agente `developer` MUST poder escribir en todo el workspace del repositorio.
- Esto incluye: `src/`, `tests/`, `scripts/`, `.github/`, `.opencode/`, `.doc_agents/`, `Documentacion/`, `README.md` y cualquier otro path del repositorio raíz.
- **Esta expansión es una consecuencia del tipo de proyecto**, no una excepción del tier declarado. El tier `Implementador` sigue estando declarado en el frontmatter del agente, pero su whitelist efectiva se resuelve contra `(tier, proyecto_tipo)` según la tabla FR-04.

### B. Acotamiento en proyectos consumidor
En un proyecto con `proyecto_tipo = consumidor`:
- El agente `developer` MUST limitarse a `src/<App>/`, `tests/` y los scripts de su aplicación.
- MUST NOT escribir en `.github/`, `.opencode/`, `.doc_agents/`, `scripts/` del kit ni `Documentacion/<OtraApp>/`.
- **Fail-closed:** ante imposibilidad de determinar el tipo de proyecto, el sistema MUST persistir `consumidor` y emitir WARN (FR-03).

### C. Regla de resolución
- **Fórmula:** `whitelist_efectiva = tier_base ∩ modificador_capa(proyecto_tipo)`, con intersección restrictiva (fail-closed).
- **Manda el tier** (tiene rango constitucional en Art. VII y está declarado en los 13 frontmatters).
- **La capa actúa como modificador restrictivo:** nunca amplía la whitelist.
- **Fuera de ambigüedad:** si el marcador no puede determinarse, el sistema MUST persistir `consumidor` y MUST emitir WARN visible con la razón (FR-03).

### D. Paridad entre harnesses
- El Art. X se aplica idénticamente en `.github/agents/` y `.opencode/agents/`.
- Cualquier cambio en el Art. X MUST tener su equivalente en ambos harnesses en la misma ronda (FR-10).

**Estado anterior (replace this text):**
```
Art. X: excepción proyecto kit sin `src/`
```
**Nuevo texto (a partir de aquí):**