---
name: mle-workflow
description: "Use when: managing ML engineering workflows, MLOps, model deployment, or ML pipeline orchestration."
user-invocable: true
---

# MLE Workflow

## When to Activate

- Setting up ML pipelines
- Deploying ML models to production
- Managing experiments and model versions
- Monitoring model performance

## Core Concepts

### ML Pipeline

```
Data Ingestion → Validation → Preprocessing → Training → Evaluation → Deployment → Monitoring
```

### Experiment Tracking

```python
# Use MLflow or Weights & Biases
import mlflow

with mlflow.start_run(run_name="experiment-1"):
    mlflow.log_param("learning_rate", 0.001)
    mlflow.log_param("batch_size", 32)
    mlflow.log_metric("accuracy", 0.95)
    mlflow.log_artifact("model.pkl")
```

## Best Practices

- Version control data (DVC or LakeFS)
- Track EVERY experiment — params, metrics, artifacts
- Use feature stores for reusable features
- A/B test models before full rollout
- Monitor for data drift and concept drift
- Automate retraining pipelines
- Document model cards (what, why, limitations)
