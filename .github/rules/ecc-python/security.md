<!-- KIT ECC-integrado b92f181b 2026-10-16: copiado de proyect_ext/ECC/rules/ (cache, no se sincroniza). Viaja en git. -->
<!-- KIT: en este repo `security-reviewer` = `security-auditor` (agente propio). Ver bitacora 2026-10-16-ecc-rules. -->
---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Python Security

> This file extends [common/security.md](../common/security.md) with Python specific content.

## Secret Management

```python
import os
from dotenv import load_dotenv

load_dotenv()

api_key = os.environ["OPENAI_API_KEY"]  # Raises KeyError if missing
```

## Security Scanning

- Use **bandit** for static security analysis:
  ```bash
  bandit -r src/
  ```

## Reference

See skill: `django-security` for Django-specific security guidelines (if applicable).

