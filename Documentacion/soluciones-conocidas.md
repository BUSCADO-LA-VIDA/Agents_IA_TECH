# 📚 Soluciones Conocidas

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

*(Aún no hay soluciones registradas. El `solucionador` las agrega aquí cuando resuelve un problema nuevo.)*
