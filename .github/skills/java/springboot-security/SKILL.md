---
name: springboot-security
description: "Use when: implementing security in Spring Boot, Spring Security configuration, JWT auth, or OAuth2."
user-invocable: true
---

# Spring Boot Security

## When to Activate

- Configuring Spring Security
- Implementing JWT authentication
- Setting up OAuth2
- Securing REST endpoints
- Role-based access control

## Core Concepts

### Security Config

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(sm -> sm.sessionCreationPolicy(STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(POST, "/api/v1/auth/**").permitAll()
                .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .authenticationProvider(authenticationProvider())
            .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}
```

### JWT Filter

```java
@Component
public class JwtFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain chain
    ) throws ServletException, IOException {
        var token = extractToken(request);
        if (token != null && validator.isValid(token)) {
            var auth = validator.getAuthentication(token);
            SecurityContextHolder.getContext().setAuthentication(auth);
        }
        chain.doFilter(request, response);
    }
}
```

## Best Practices

- Use BCryptPasswordEncoder — never plain text
- Stateless JWT for APIs, session for server-rendered
- Validate all inputs — even authenticated requests
- Rate limiting on auth endpoints
- CORS config per environment
- Use @PreAuthorize for method-level security
