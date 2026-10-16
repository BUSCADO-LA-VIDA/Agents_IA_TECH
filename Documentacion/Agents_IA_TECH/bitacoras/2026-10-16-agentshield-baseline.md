# Bitacora 2026-10-16 — AgentShield: baseline + gate (opcion a)

## Diagnostico
- Validate Skills rojo por flake transitorio de checkout (SHA v7.0.1 verificado valido; job vecino OK). Sin bug propio.
- AgentShield rojo por regla nueva del scanner (npx latest) contra `permission.bash: allow` deliberado del dueno (2026-10-09). Reproducido en local: unico hallazgo del repo commiteado.

## Implementado
- `.agentshield-baseline.json` commiteado (sin secretos reales verificados).
- Workflow pineado a 1.6.0 + `--baseline/--gate`. Exit codes mapeados empiricamente: 0=limpio, 2=gate-pass con baseline, 3=regresion. El step acepta 0 y 2.
- Riesgo aceptado documentado en el workflow (bash:allow deliberado del flujo sin-preguntas).

## Verificacion local
- Gate sobre el repo: PASSED, exit 2. Fixture: baseline limpia + hallazgo plantado -> gate FAILED, exit 3.

## Fix 2: bash -e mataba el step antes del gate
GitHub corre run: con bash -e: npx saliendo 2 terminaba el step sin evaluar nada. Se agrego set +e al inicio del bloque. El gate real nunca habia corrido en CI.
