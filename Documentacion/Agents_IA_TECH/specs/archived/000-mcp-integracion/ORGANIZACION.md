# Organización de Integraciones MCP

## Estructura

```
000-mcp-integracion/
├─ 000-mcp-integracion-estandar.md
├─ 000-mcp-context7-integracion/
│  ├─ spec.md
│  ├─ plan.md
│  └─ ...
├─ 000-mcp-github-integracion/
├─ 000-mcp-testsprite-integracion/
├─ 000-mcp-playwright-integracion/
├─ 000-mcp-semgrep-integracion/
├─ 000-mcp-pieces-integracion/
├─ 000-mcp-perplexity-integracion/
└─ 000-mcp-sentry-integracion/
```

## Convención de nombres

- Carpeta contenedora: `000-mcp-integracion`
- Cada MCP: `000-mcp-<NOMBRE>-integracion`
- Estándar: `000-mcp-integracion-estandar.md`

## Flujo obligatorio por MCP

1. Instalación
2. Integración en opencode.json / .env.mcp / mcp.json
3. Consumo por agentes
4. Uso integrado en flujo SSD

Todas las specs deben referenciar el estándar y `007-mcp-token-resolution`.

## Fecha de creación
2026-09-28
