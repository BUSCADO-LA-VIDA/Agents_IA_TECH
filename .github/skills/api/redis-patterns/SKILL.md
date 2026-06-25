---
name: redis-patterns
description: "Use when: implementing Redis caching, rate limiting, queues, sessions, or real-time features."
user-invocable: true
---

# Redis Patterns

## When to Activate

- Implementing caching strategies
- Rate limiting endpoints
- Managing background job queues
- Storing sessions
- Real-time features (Pub/Sub)

## Core Concepts

### Cache-Aside Pattern

```python
import redis.asyncio as redis
from typing import Optional

cache = redis.from_url("redis://localhost:6379/0")


async def get_user(user_id: int) -> Optional[dict]:
    # Try cache first
    cached = await cache.get(f"user:{user_id}")
    if cached:
        return json.loads(cached)

    # Miss — fetch from DB
    user = await db.fetch_user(user_id)
    if user:
        # Store in cache with TTL
        await cache.setex(f"user:{user_id}", 300, json.dumps(user.to_dict()))
    return user
```

### Rate Limiting

```python
import time


async def check_rate_limit(key: str, max_requests: int, window: int) -> bool:
    """Sliding window rate limiter."""
    now = int(time.time())
    window_start = now - window

    await cache.zremrangebyscore(f"ratelimit:{key}", 0, window_start)
    count = await cache.zcard(f"ratelimit:{key}")

    if count >= max_requests:
        return False  # Rate limited

    await cache.zadd(f"ratelimit:{key}", {str(now): now})
    await cache.expire(f"ratelimit:{key}", window)
    return True
```

### Queue Pattern

```python
# Producer
await cache.lpush("queue:emails", json.dumps({
    "to": "user@test.com",
    "subject": "Welcome!",
}))

# Consumer (worker)
while True:
    task = await cache.brpop("queue:emails", timeout=5)
    if task:
        process_email(json.loads(task[1]))
```

## Best Practices

- Always set TTLs — avoid memory leaks
- Use connection pooling
- Use separate DB indexes for different concerns (0=cache, 1=queue, 2=sessions)
- Use Redis CLI for debugging: `redis-cli monitor`
- Monitor memory with `INFO memory`
- Use Redis Sentinel or Cluster for high availability
- Never store sensitive data unencrypted in Redis
