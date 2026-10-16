---
name: quarkus-security
description: "Use when: implementing security in Quarkus, JWT auth, OAuth2, or securing reactive endpoints."
user-invocable: true
---

# Quarkus Security

## When to Activate

- Configuring Quarkus Security
- Implementing JWT in Quarkus
- Securing reactive REST endpoints

## Core Concepts

### Security Config

```properties
# application.properties
quarkus.http.cors=true

# JWT
quarkus.smallrye-jwt.enabled=true
mp.jwt.verify.publickey.location=publickey.pem
mp.jwt.verify.issuer=https://auth.project.com
```

### Secured Endpoint

```java
@Path("/api/v1/admin")
@RolesAllowed("admin")
public class AdminResource {
    @GET
    @Path("/dashboard")
    @RolesAllowed("admin")
    public Uni<Dashboard> dashboard() {
        return service.getDashboard();
    }
}
```

## Best Practices

- Use SmallRye JWT for token-based auth
- Use @RolesAllowed for method security
- Never expose stack traces in error responses
- Validate all inputs with Bean Validation

## Profundidad ECC
Detalle tecnico completo (20 KB aprox): `../../../../proyect_ext/ECC/skills/quarkus-security/SKILL.md`.
Esta ficha es la fachada SSD del kit; ante duda tecnica, leer la fuente ECC (no se sincroniza: `proyect_ext/` nunca sale del KIT).
