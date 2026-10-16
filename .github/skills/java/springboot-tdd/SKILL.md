---
name: springboot-tdd
description: "Use when: doing TDD in Spring Boot, writing tests before implementation, testing controllers, services, repositories."
user-invocable: true
---

# Spring Boot TDD

## When to Activate

- Starting a new Spring Boot feature
- Writing tests first (RED phase)
- Testing REST endpoints and services

## Core Concepts

### Test Slices

| Test | Annotation | Scope |
|------|------------|-------|
| Unit | `@ExtendWith(MockitoExtension.class)` | Service logic |
| Web | `@WebMvcTest` | Controller only |
| Data | `@DataJpaTest` | Repository only |
| Integration | `@SpringBootTest` | Full context |

### Service Test

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    @Mock
    private UserRepository repository;

    @InjectMocks
    private UserService service;

    @Test
    void create_shouldSaveUser() {
        var request = new CreateUserRequest("test@test.com", "pass");
        when(repository.save(any())).thenReturn(new User(1L, "test@test.com"));

        var result = service.create(request);

        assertThat(result.email()).isEqualTo("test@test.com");
        verify(repository).save(any());
    }
}
```

### Controller Test

```java
@WebMvcTest(UserController.class)
class UserControllerTest {
    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService service;

    @Test
    void create_shouldReturn201() throws Exception {
        var request = new CreateUserRequest("test@test.com", "pass");
        when(service.create(any())).thenReturn(new UserResponse(1L, "test@test.com"));

        mockMvc.perform(post("/api/v1/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"test@test.com\",\"password\":\"pass\"}"))
            .andExpect(status().isCreated());
    }
}
```

## Best Practices

- Use test slices for focused tests
- Mock external services
- Use AssertJ for fluent assertions
- Test error cases (400, 401, 403, 404, 500)
- Use @Sql for test data setup

---

## Profundidad ECC (integrada b92f181b, 2026-10-16)

> Fuente: proyect_ext/ECC/skills/springboot-tdd/SKILL.md (cache de descarga, no se sincroniza). Contenido copiado al KIT: viaja en git a los demas proyectos.

---
name: springboot-tdd
description: Test-driven development for Spring Boot using JUnit 5, Mockito, MockMvc, Testcontainers, and JaCoCo. Use when adding features, fixing bugs, or refactoring.
metadata:
  origin: ECC
---

# Spring Boot TDD Workflow

TDD guidance for Spring Boot services with 80%+ coverage (unit + integration).

## When to Use

- New features or endpoints
- Bug fixes or refactors
- Adding data access logic or security rules

## Workflow

1) Write tests first (they should fail)
2) Implement minimal code to pass
3) Refactor with tests green
4) Enforce coverage (JaCoCo)

## Unit Tests (JUnit 5 + Mockito)

```java
@ExtendWith(MockitoExtension.class)
class MarketServiceTest {
  @Mock MarketRepository repo;
  @InjectMocks MarketService service;

  @Test
  void createsMarket() {
    CreateMarketRequest req = new CreateMarketRequest("name", "desc", Instant.now(), List.of("cat"));
    when(repo.save(any())).thenAnswer(inv -> inv.getArgument(0));

    Market result = service.create(req);

    assertThat(result.name()).isEqualTo("name");
    verify(repo).save(any());
  }
}
```

Patterns:
- Arrange-Act-Assert
- Avoid partial mocks; prefer explicit stubbing
- Use `@ParameterizedTest` for variants

## Web Layer Tests (MockMvc)

```java
@WebMvcTest(MarketController.class)
class MarketControllerTest {
  @Autowired MockMvc mockMvc;
  @MockBean MarketService marketService;

  @Test
  void returnsMarkets() throws Exception {
    when(marketService.list(any())).thenReturn(Page.empty());

    mockMvc.perform(get("/api/markets"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.content").isArray());
  }
}
```

## Integration Tests (SpringBootTest)

```java
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class MarketIntegrationTest {
  @Autowired MockMvc mockMvc;

  @Test
  void createsMarket() throws Exception {
    mockMvc.perform(post("/api/markets")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {"name":"Test","description":"Desc","endDate":"2030-01-01T00:00:00Z","categories":["general"]}
        """))
      .andExpect(status().isCreated());
  }
}
```

## Persistence Tests (DataJpaTest)

```java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(TestContainersConfig.class)
class MarketRepositoryTest {
  @Autowired MarketRepository repo;

  @Test
  void savesAndFinds() {
    MarketEntity entity = new MarketEntity();
    entity.setName("Test");
    repo.save(entity);

    Optional<MarketEntity> found = repo.findByName("Test");
    assertThat(found).isPresent();
  }
}
```

## Testcontainers

- Use reusable containers for Postgres/Redis to mirror production
- Wire via `@DynamicPropertySource` to inject JDBC URLs into Spring context

## Coverage (JaCoCo)

Maven snippet:
```xml
<plugin>
  <groupId>org.jacoco</groupId>
  <artifactId>jacoco-maven-plugin</artifactId>
  <version>0.8.14</version>
  <executions>
    <execution>
      <goals><goal>prepare-agent</goal></goals>
    </execution>
    <execution>
      <id>report</id>
      <phase>verify</phase>
      <goals><goal>report</goal></goals>
    </execution>
  </executions>
</plugin>
```

## Assertions

- Prefer AssertJ (`assertThat`) for readability
- For JSON responses, use `jsonPath`
- For exceptions: `assertThatThrownBy(...)`

## Test Data Builders

```java
class MarketBuilder {
  private String name = "Test";
  MarketBuilder withName(String name) { this.name = name; return this; }
  Market build() { return new Market(null, name, MarketStatus.ACTIVE); }
}
```

## CI Commands

- Maven: `mvn -T 4 test` or `mvn verify`
- Gradle: `./gradlew test jacocoTestReport`

**Remember**: Keep tests fast, isolated, and deterministic. Test behavior, not implementation details.
