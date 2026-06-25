---
name: pytorch-patterns
description: "Use when: building PyTorch models, training loops, or ML pipelines with PyTorch."
user-invocable: true
---

# PyTorch Patterns

## When to Activate

- Implementing deep learning models
- Writing training loops
- Setting up data pipelines
- Debugging model training

## Core Concepts

### Project Structure

```
project/
├── config/
│   └── config.yaml
├── data/
│   ├── dataset.py
│   └── preprocessing.py
├── models/
│   └── model.py
├── training/
│   ├── trainer.py
│   └── losses.py
├── evaluation/
│   └── metrics.py
├── scripts/
│   ├── train.py
│   └── evaluate.py
└── requirements.txt
```

### Training Loop Pattern

```python
import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from tqdm import tqdm


def train_epoch(
    model: nn.Module,
    loader: DataLoader,
    optimizer: torch.optim.Optimizer,
    criterion: nn.Module,
    device: torch.device,
) -> float:
    model.train()
    total_loss = 0.0

    for batch in tqdm(loader, desc="Training"):
        x, y = batch
        x, y = x.to(device), y.to(device)

        optimizer.zero_grad()
        output = model(x)
        loss = criterion(output, y)
        loss.backward()
        optimizer.step()

        total_loss += loss.item()

    return total_loss / len(loader)
```

## Best Practices

- Use `torch.nn.Module` for all models
- Use `DataLoader` for data pipelines
- Enable `pin_memory=True` and `num_workers>0` for speed
- Use gradient clipping for stable training
- Log metrics with TensorBoard or Weights & Biases
