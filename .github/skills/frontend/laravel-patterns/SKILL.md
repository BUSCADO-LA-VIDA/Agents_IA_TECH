---
name: laravel-patterns
description: "Use when: building Laravel applications, Eloquent models, controllers, services, or Blade views."
user-invocable: true
---

# Laravel Patterns

## When to Activate

- Creating new Laravel applications
- Designing Eloquent models and relationships
- Writing service classes
- Building Blade components

## Core Concepts

### Project Structure

```
app/
├── Models/
├── Services/        # Business logic (fat services, thin controllers)
├── Http/
│   ├── Controllers/
│   ├── Requests/    # Form Request validation
│   └── Resources/   # API Resources
├── Providers/
├── Traits/          # Reusable traits (HasUuid, SoftDeletes, etc.)
└── Actions/         # Single-action classes
```

### Service Layer Pattern

```php
namespace App\Services;

use App\Models\User;
use App\Traits\HasUuid;
use Illuminate\Support\Facades\Hash;

class UserService
{
    public function create(array $data): User
    {
        return User::create([
            'uuid' => (string) str()->uuid(),
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
        ]);
    }

    public function findByUuid(string $uuid): ?User
    {
        return Cache::remember("user:{$uuid}", 300, function () use ($uuid) {
            return User::where('uuid', $uuid)->first();
        });
    }
}
```

### Controller Pattern

```php
namespace App\Http\Controllers\Api;

use App\Services\UserService;
use App\Http\Requests\CreateUserRequest;
use App\Http\Resources\UserResource;

class UserController extends Controller
{
    public function __construct(
        private readonly UserService $service
    ) {}

    public function store(CreateUserRequest $request): UserResource
    {
        $user = $this->service->create($request->validated());
        return new UserResource($user);
    }
}
```

## Best Practices

- Fat services, thin controllers — no business logic in controllers
- Use Form Requests for validation
- Use API Resources for response formatting
- Use traits for reusable model behavior (HasUuid, SoftDeletes)
- Use Eloquent ORM — avoid raw SQL
- Use Spatie Permission for roles
- Use Laravel's cache facade for performance
- Register routes with Route::apiResource() when possible
