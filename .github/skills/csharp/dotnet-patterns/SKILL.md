---
name: dotnet-patterns
description: "Use when: building .NET applications, ASP.NET Core APIs, Entity Framework, or C# services."
user-invocable: true
---

# .NET Patterns

## When to Activate

- Creating new .NET projects
- Designing ASP.NET Core APIs
- Using Entity Framework Core
- Writing C# services

## Core Concepts

### Project Structure

```
project/
├── src/
│   └── Project.Api/
│       ├── Controllers/
│       ├── Services/
│       ├── Models/
│       ├── Data/
│       │   ├── Migrations/
│       │   └── AppDbContext.cs
│       ├── Program.cs
│       └── appsettings.json
├── tests/
│   └── Project.Tests/
├── Project.sln
└── README.md
```

### Minimal API Pattern

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<AppDbContext>(opts =>
    opts.UseNpgsql(builder.Configuration.GetConnectionString("Default")));
builder.Services.AddScoped<IUserService, UserService>();

var app = builder.Build();

app.MapPost("/api/v1/users", async (CreateUserRequest request, IUserService service) =>
{
    var user = await service.CreateAsync(request);
    return Results.Created($"/api/v1/users/{user.Id}", user);
});

app.Run();
```

### Controller Pattern

```csharp
[ApiController]
[Route("api/v1/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUserService _service;

    public UsersController(IUserService service) => _service = service;

    [HttpPost]
    public async Task<ActionResult<UserResponse>> Create(CreateUserRequest request)
    {
        var user = await _service.CreateAsync(request);
        return CreatedAtAction(nameof(FindById), new { id = user.Id }, user);
    }
}
```

## Best Practices

- Use Minimal APIs for simple endpoints, Controllers for complex ones
- Use records for DTOs
- Use primary constructors (C# 12+)
- Use dependency injection everywhere
- Use EF Core with migrations
- Never use synchronous .Result or .Wait() on async calls
- Use IOptions pattern for configuration
