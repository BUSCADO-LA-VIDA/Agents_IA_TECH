---
name: kubernetes-patterns
description: "Use when: deploying to Kubernetes, writing K8s manifests, or orchestrating containers at scale."
user-invocable: true
---

# Kubernetes Patterns

## When to Activate

- When deploying containerized apps to K8s
- When writing Kubernetes manifests (Deployments, Services, Ingress)
- When setting up CI/CD for Kubernetes

## Core Concepts

### Key Resources

| Resource | Purpose |
|----------|---------|
| Deployment | Stateless app instances |
| StatefulSet | Stateful apps (DBs) |
| Service | Internal networking |
| Ingress | External HTTP/S access |
| ConfigMap | Non-sensitive config |
| Secret | Sensitive data |
| PersistentVolumeClaim | Storage |

### Minimal Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
        - name: app
          image: my-app:1.0
          ports:
            - containerPort: 8080
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
```

## Best Practices

- Use kustomize or Helm for environment separation
- Set resource requests and limits
- Use readiness + liveness probes
- Never store secrets in plain text — use SealedSecrets or External Secrets Operator
- Use network policies for pod isolation
- Prefer docker-compose for local dev, K8s only for prod
