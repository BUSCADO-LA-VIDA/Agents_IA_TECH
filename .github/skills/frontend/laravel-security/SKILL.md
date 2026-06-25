---
name: laravel-security
description: "Use when: securing Laravel applications, authentication, authorization, middleware, or security best practices."
user-invocable: true
---

# Laravel Security

## When to Activate

- Configuring authentication in Laravel
- Implementing authorization (Policies, Gates)
- Securing API routes
- Auditing Laravel security

## Core Concepts

### Security Checklist

- [ ] `APP_DEBUG=false` in production
- [ ] `APP_KEY` generated and in `.env`
- [ ] `APP_ENV=production` in production
- [ ] CSRF protection enabled on all forms
- [ ] XSS protection via Blade `{{ }}` (not `{!! !!}`)
- [ ] SQL injection prevention via Eloquent ORM
- [ ] Rate limiting on API routes
- [ ] CORS configured correctly
- [ ] Headers: X-Frame-Options, HSTS, Content-Type
- [ ] Authentication: password hashing (bcrypt)
- [ ] Authorization: Policies or Spatie Permission
- [ ] 2FA implemented
- [ ] Login throttling
- [ ] Session security (HTTP-only, Secure, SameSite)

### Middleware Pattern

```php
// app/Http/Kernel.php
protected $routeMiddleware = [
    'auth' => \App\Http\Middleware\Authenticate::class,
    'throttle' => \Illuminate\Routing\Middleware\ThrottleRequests::class,
    '2fa' => \App\Http\Middleware\RequireTwoFactor::class,
    'role' => \Spatie\Permission\Middleware\RoleMiddleware::class,
];
```

### Policy Pattern

```php
namespace App\Policies;

use App\Models\User;

class UserPolicy
{
    public function view(User $user, User $target): bool
    {
        return $user->id === $target->id || $user->hasRole('admin');
    }

    public function delete(User $user, User $target): bool
    {
        return $user->hasRole('admin') && $user->id !== $target->id;
    }
}
```

## Best Practices

- Use Eloquent — never raw SQL with user input
- Use Form Requests for validation
- Use Policies for authorization logic
- Use Spatie Permission for complex roles/ACL
- Use rate limiting on ALL API routes
- Hash passwords with bcrypt (Laravel default)
- Never trust user input — validate, sanitize, escape
- Enable 2FA for admin users
- Log failed login attempts
- Use `env()` only in config files — use config() everywhere else
