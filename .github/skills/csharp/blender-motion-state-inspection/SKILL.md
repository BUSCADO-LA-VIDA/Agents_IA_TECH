---
name: blender-motion-state-inspection
description: "Use when: inspecting Blender motion data from .NET, or working with 3D animation data in C#."
user-invocable: true
---

# Blender Motion State Inspection

## When to Activate

- Reading Blender animation data from C#
- Inspecting motion state in Blender Python API
- Exporting animation data for .NET applications

## Core Concepts

### Blender to .NET Pipeline

```python
# Blender Python — export motion data
import bpy
import json

def export_motion_data(obj_name: str, output_path: str):
    obj = bpy.data.objects[obj_name]
    data = []
    for frame in range(1, 250):
        bpy.context.scene.frame_set(frame)
        data.append({
            "frame": frame,
            "location": list(obj.location),
            "rotation": list(obj.rotation_euler),
            "scale": list(obj.scale),
        })
    with open(output_path, "w") as f:
        json.dump({"frames": data}, f)
```

## Best Practices

- Export to JSON for .NET consumption
- Use System.Text.Json for deserialization
- Batch process frames for performance
