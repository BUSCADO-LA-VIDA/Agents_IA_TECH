---
name: csharp-testing
description: "Use when: writing C# tests, xUnit, Moq, FluentAssertions, or testing .NET applications."
user-invocable: true
---

# C# Testing

## When to Activate

- Writing unit tests for C# code
- Testing ASP.NET Core controllers
- Mocking dependencies in .NET
- Integration testing with WebApplicationFactory

## Core Concepts

### xUnit Test Pattern

```csharp
public class UserServiceTests
{
    [Fact]
    public async Task Create_ValidRequest_ReturnsUser()
    {
        // Arrange
        var repository = new Mock<IUserRepository>();
        repository.Setup(r => r.AddAsync(It.IsAny<User>()))
            .ReturnsAsync(new User { Id = 1, Email = "test@test.com" });

        var service = new UserService(repository.Object);

        // Act
        var result = await service.CreateAsync(new CreateUserRequest("test@test.com"));

        // Assert
        Assert.Equal("test@test.com", result.Email);
    }
}
```

### Integration Test

```csharp
public class UsersApiTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public UsersApiTests(WebApplicationFactory<Program> factory)
        => _client = factory.CreateClient();

    [Fact]
    public async Task Post_ReturnsCreated()
    {
        var response = await _client.PostAsJsonAsync("/api/v1/users",
            new { Email = "test@test.com", Password = "pass" });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
    }
}
```

## Best Practices

- Use xUnit — it's the standard for .NET
- Use Moq or NSubstitute for mocking
- Use FluentAssertions for readable assertions
- Use WebApplicationFactory for integration tests
- Use TestContainers for database testing
- Name tests: Method_Scenario_ExpectedResult
