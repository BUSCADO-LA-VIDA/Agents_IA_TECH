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
