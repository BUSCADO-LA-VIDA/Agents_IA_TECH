# 📚 Soluciones Conocidas - Agents_IA_TECH

> **Repositorio de problemas recurrentes ya resueltos.**
> El agente `solucionador` lo consulta **siempre primero** antes de diagnosticar desde cero.
>
> Formato de cada entrada:
> ```markdown
> ### <YYYY-MM-DD> <Título corto>
> - **Síntomas**: cómo reconocer el problema
> - **Servidor**: IP o dominio
> - **Solución**: pasos exactos
> - **Archivos locales afectados**: rutas si aplica
> - **Tags**: `apache`, `radius`, `docker`, etc.
> ```

---

## VS Code / Copilot

### <2026-07-25> Error BYOK: "No utility model is configured for copilot-utility-small"

- **Síntomas**: Al usar un modelo BYOK (Bring Your Own Key) como agente principal en GitHub Copilot, aparece el error: "No utility model is configured for 'copilot-utility-small' while the selected main agent model is BYOK".
- **Causa**: BYOK requiere un modelo utility pequeño configurado explícitamente para tareas auxiliares. Si no se configura, falla.
- **Tags**: `vscode`, `copilot`, `byok`, `config`

### Solución 1: Desactivar BYOK

- **Settings → `github.copilot.chat.agent.byok.enabled` → `false`**
- Luego asegurate de tener un modelo principal no-BYOK seleccionado (ej: `DeepSeek V4 Flash`, `GPT-4o`, etc.)
- En `settings.json`:
  ```json
  "github.copilot.chat.agent.byok.enabled": false
  ```

### Solución 2: Configurar un modelo utility (si querés mantener BYOK)

- Settings → `github.copilot.chat.agent.utilityModel` → asignar un modelo como `gpt-4o-mini` o `claude-3-5-haiku`

### Solución 3: Volver al modelo anterior

- Settings → `github.copilot.chat.agent.model` → seleccionar el modelo que usabas antes (no-BYOK)

---

## OpenWiki / CI

### <2026-08-06> OpenWiki falla: "400 validation error" / "OPENROUTER_API_KEY is required"

- **Síntomas**:
  - En CI: `OPENROUTER_API_KEY is required for non-interactive runs` → exit code 1
  - En local: `400 1 validation error for Message content.0 ... ValidatorIterator` (pydantic)
- **Causa**: desalineación del **proveedor de IA**. OpenWiki genera la doc con un modelo de IA; el workflow usaba `OPENWIKI_PROVIDER: openrouter` + modelo `z-ai/glm-5.2` (que es de **NVIDIA**, no de OpenRouter), y el secret `OPENROUTER_API_KEY` no existía. En local faltaba `OPENWIKI_PROVIDER` → default incorrecto.
- **Solución** (alinear al proveedor real del proyecto = **NVIDIA**):
  - En el workflow `openwiki-update.yml`:
    ```yaml
    OPENWIKI_PROVIDER: nvidia
    NVIDIA_API_KEY: ${{ secrets.NVIDIA_API_KEY }}
    OPENWIKI_MODEL_ID: nvidia/nemotron-3-super-120b-a12b
    ```
  - Requiere definir el secret `NVIDIA_API_KEY` en **Settings → Secrets and variables → Actions** del repo.
  - En local: exportar `OPENWIKI_PROVIDER=nvidia` y `OPENWIKI_MODEL_ID=nvidia/nemotron-3-super-120b-a12b` (la `NVIDIA_API_KEY` ya vive en el shell).
- **Archivos locales afectados**: `.github/workflows/openwiki-update.yml`, `opencode.json`
- **Tags**: `openwiki`, `ci`, `nvidia`, `proveedor`, `github-actions`

### <2026-08-06> Security Scan falla: "missing gitleaks license"

- **Síntomas**: workflow `security-scan.yml` falla con `missing gitleaks license. Go grab one at gitleaks.io and store it as a GitHub Secret named GITLEAKS_LICENSE`.
- **Causa**: la action oficial `gitleaks/gitleaks-action@v2` se volvió un producto con licencia (breaking change reciente). La acción oficial ya no es gratuita en CI.
- **Solución**: no usar la action con licencia; instalar y ejecutar el **binario CLI open-source de gitleaks**:
  ```yaml
  - name: Install gitleaks (open-source CLI)
    run: |
      curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/install.sh | sh
      ./bin/gitleaks version
  - name: Run gitleaks
    run: ./bin/gitleaks detect --source . --redact --verbose
  ```
- **Archivos locales afectados**: `.github/workflows/security-scan.yml`
- **Tags**: `gitleaks`, `ci`, `seguridad`, `secrets`, `license`

### <2026-08-06> Spellcheck falla: codespell marca todo el repo español como typos

- **Síntomas**: workflow `spellcheck.yml` falla con muchos errores tipo `README.md#L6 profesional ==> professional` aunque el texto está correcto.
- **Causa**: `codespell` es un corrector de **inglés**, pero este repo es **intencionalmente en español** (ver `Documentacion/Agents_IA_TECH/idioma.md`). Marca todos los docs en español como typos.
- **Solución**: restringir el spellcheck solo a archivos de **config en inglés técnico** (`.github/workflows/*.yml`, `.opencode/*.json`, `opencode.json`) y excluir la documentación en español en el `skip`:
  ```yaml
  on:
    push/PR paths:
      - '.github/workflows/**.yml'
      - '.opencode/**.json'
      - 'opencode.json'
  # skip: Documentacion,README.md,openwiki,AGENTS.md,CLAUDE.md,.github/agents,... etc.
  ```
- **Archivos locales afectados**: `.github/workflows/spellcheck.yml`
- **Tags**: `codespell`, `ci`, `ortografía`, `español`, `spellcheck`

---

## Git / Sync

### <2026-08-30> sync-agents.ps1 no respeta estructura por app

- **Síntomas**: Script sincronizaba `Documentacion/` genérica en lugar de respetar `Documentacion/<AppName>/` por app.
- **Causa**: Script legacy no actualizado a nueva arquitectura.
- **Solución**: Actualizado `sync-agents.ps1` para sincronizar SOLO kit transversal (`.github/`, `.opencode/`, `.doc_agents/`, `.specify/memory/constitution.md`, `AGENTS.md`, `opencode.json`, `README.md`, `sync-agents.ps1`). NUNCA toca `Documentacion/<AppName>/`.
- **Archivos locales afectados**: `sync-agents.ps1`, `.doc_agents/sync-agents-template.ps1`
- **Tags**: `sync`, `powershell`, `estructura`, `kit-transversal`

### <2026-11-02> El sync del kit sobrescribe `AGENTS.md` y no corrige `default_agent`

- **Síntomas**:
  - Tras un sync con `scripts/sync-kit-agents.ps1`, el `AGENTS.md` del proyecto pierde todo su
    contenido propio y queda idéntico al del maestro. Se detecta porque desaparecen secciones
    locales (reglas del proyecto, comandos propios).
  - `opencode.json` del destino queda con `"default_agent": "build"` aunque el sync termine en
    verde (`RESULT:opencode:ok`, `ERRORs: 0`). OpenCode cae entonces al agente `build` con un
    warning: es el **fallback silencioso** que la spec 034 §19.3 clasifica como fallo de
    configuración.
  - El backup tomado a mano antes del sync desaparece de `.kit-backup/` al terminar la corrida.
- **Causa** (tres defectos independientes del motor por capas):
  1. `scripts/sync/kit-files/sync-kit-files.ps1` trataba `AGENTS.md` con `Copy-Item -Force`,
     igual que `README.md`. Pero `AGENTS.md` es un archivo **compartido** (reglas del kit +
     contenido del proyecto), no exclusivo del kit.
  2. Ninguna capa aplicaba `default_agent`, `$schema` ni `instructions`. `lift-opencode.ps1`
     solo fusiona el bloque `mcp`. Por eso el sync podía terminar sin errores y dejar la config
     rota.
  3. `sync-kit-agents.ps1` poda `.kit-backup/` conservando solo las 2 carpetas más recientes
     (`Select-Object -Skip 2` sobre orden descendente). Los backups creados durante la corrida
     tienen timestamp posterior, así que el backup del operador siempre es candidato a poda.
- **Solución**:
  1. Nueva función compartida `Merge-KitBlockFile` en `scripts/sync/lib/common.ps1`: complementa
     `AGENTS.md` por bloque delimitado `<!-- KIT-BLOCK:START <id> -->` / `END`, conservando todo
     lo demás. Soporta múltiples bloques, preserva BOM y CRLF, es idempotente y **fail-closed**
     ante marcadores corruptos (START sin END, duplicados, desordenados → no escribe).
     Estados: `sin-cambios` | `ok` | `creado` | `omitido-item`.
  2. En `sync-kit-files.ps1`, `AGENTS.md` pasa de `Invoke-KitSingleFile` a `Merge-KitBlockFile`.
     `README.md` y `.specify/memory/constitution.md` siguen siendo 100 % del kit (clean+replace),
     y `scripts/` conserva clean+replace con backup previo.
  3. En `scripts/sync/mcp/lift-opencode.ps1`, añadir las claves gestionadas con las reglas de
     `Merge-OpenCodeConfig` (spec 034 §19.3): `default_agent` ausente → escribir; `== 'build'` →
     corregir con WARN; agente del kit con `mode: primary` → respetar la elección del proyecto;
     desconocido → corregir; `-Force` → forzar. Igual para `$schema` e `instructions`.
  4. Tests de regresión en `tests/kit-sync-merge.ps1` (escenarios 8-10): ejecutan la capa
     `kit-files` real sobre fixtures temporales y verifican que el contenido propio sobrevive,
     que `README.md` sí se reemplaza, que `scripts/` mantiene clean+replace, la idempotencia y
     que `lift-opencode` aplica `default_agent` conservando `model` y `mcp.graphify`.
- **Verificación**:
  - `pwsh -NoProfile -File tests/kit-sync-merge.ps1` → **45 asserts PASS, 0 FAIL, 10 escenarios**,
    exit 0. Parseo sintáctico limpio de los 4 archivos.
  - Sync real con `-Only "kit-files,agents-github,agents-opencode,agents-vscode,mcp-lift-opencode,mcp-lift-vscode"`:
    dry-run y real con exit 0 y `ERRORs: 0`.
  - Divergencia maestro→destino **0** en skills (89+89), rules (16), prompts (6), agents (14+13),
    commands (6), workflows (5) y `copilot-instructions.md`.
  - `AGENTS.md` del destino: 1 START / 1 END, conserva `# AGENTS.md`, `REGLAS CRÍTICAS`,
    `Core facts`, `## Commands`. `opencode.json`: `default_agent: pensador`.
- **Comando de aplicación** (una sola pasada, desde el maestro):
  ```powershell
  pwsh -File $KitPath\scripts\sync-kit-agents.ps1 `
    -RootPath <destino> -KitPath $KitPath `
    -Only "kit-files,agents-github,agents-opencode,agents-vscode,mcp-lift-opencode,mcp-lift-vscode"
  ```
  Si el destino necesita además skills/rules/prompts/workflows/tests (defectos D2 y D4 abiertos),
  completar con `pwsh -File scripts/sync-kit.ps1 -RootPath <destino> -KitPath <maestro> -OrphanAction Conservar` **sin `-Force`**.
- **Rollback**: `AGENTS.md.bak-<timestamp>` y `opencode.json.bak-<timestamp>` junto al archivo;
  backup completo en `.kit-backup-manual/<timestamp>/` (fuera de `.kit-backup/` para que la poda
  no lo alcance).
- **Archivos locales afectados**: `scripts/sync/lib/common.ps1`,
  `scripts/sync/kit-files/sync-kit-files.ps1`, `scripts/sync/mcp/lift-opencode.ps1`,
  `tests/kit-sync-merge.ps1`
- **Tags**: `sync`, `kit-transversal`, `agents-md`, `opencode`, `default-agent`, `powershell`, `merge-por-bloque`
- **Deuda relacionada** (no corregida aquí): D1 poda de `.kit-backup`; D2 no existe capa `skills`;
  D3 `Test-AuditLogIntegrity` falso negativo; D4 `tests/` solo viaja por el motor deprecado;
  D5 doble entrada `graphify` en `opencode.json`.