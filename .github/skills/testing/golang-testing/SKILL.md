---
name: golang-testing
description: "Use when: writing Go tests, table-driven tests, benchmarks, or testing Go applications."
user-invocable: true
---

# Go Testing

## When to Activate

- Writing unit tests for Go code
- Using table-driven tests
- Writing benchmarks
- Testing HTTP handlers

## Core Concepts

### Table-Driven Test

```go
func TestCalculateTotal(t *testing.T) {
    tests := []struct {
        name     string
        items    []Item
        expected float64
    }{
        {"empty cart", []Item{}, 0},
        {"single item", []Item{{Price: 10}}, 10},
        {"multiple items", []Item{{Price: 10}, {Price: 20}}, 30},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            cart := NewCart(tt.items)
            result := cart.CalculateTotal()
            if result != tt.expected {
                t.Errorf("got %f, want %f", result, tt.expected)
            }
        })
    }
}
```

### Benchmark

```go
func BenchmarkCalculateTotal(b *testing.B) {
    items := []Item{{Price: 10}, {Price: 20}}
    cart := NewCart(items)
    for i := 0; i < b.N; i++ {
        cart.CalculateTotal()
    }
}
```

## Best Practices

- Use table-driven tests for multiple scenarios
- Use `t.Run` for subtests
- Use `testing/synctest` for concurrent tests
- Use httptest for HTTP handler tests
- Use testify/assert for readable assertions
- Run `go test -race` for race detection
