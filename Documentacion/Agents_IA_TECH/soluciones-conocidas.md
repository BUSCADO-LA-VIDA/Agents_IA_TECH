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