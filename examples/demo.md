# nvim-newfile Demo Examples

This file demonstrates the expected output of the nvim-newfile plugin for various languages and directory structures.

## Go Examples

### Directory: `/project/calculations/`
**Command:** `:NewFile calculator.go`
**Generated content:**
```go
package calculations

```

### Directory: `/project/main/`
**Command:** `:NewFile main.go`
**Generated content:**
```go
package main

import "fmt"

func main() {
	fmt.Println("Hello, World!")
}
```

### Directory: `/project/utils/string-helper/`
**Command:** `:NewFile helper.go`
**Generated content:**
```go
package string_helper

```

## PHP Examples

### Directory: `/project/src/Services/Payment/`
**Command:** `:NewFile PaymentProcessor.php`
**Generated content:**
```php
<?php

namespace Services\Payment;

class PaymentProcessor
{
    // TODO: Implement class
}
```

### Directory: `/project/app/Models/User/`
**Command:** `:NewFile UserRepository.php`
**Generated content:**
```php
<?php

namespace App\Models\User;

class UserRepository
{
    // TODO: Implement class
}
```

### Directory: `/project/lib/Utilities/`
**Command:** `:NewFile StringUtils.php`
**Generated content:**
```php
<?php

namespace Utilities;

class StringUtils
{
    // TODO: Implement class
}
```

## Java Examples

### Directory: `/project/src/main/java/com/example/utils/`
**Command:** `:NewFile StringHelper.java`
**Generated content:**
```java
package com.example.utils;

public class StringHelper {
    // TODO: Implement class
}
```

### Directory: `/project/src/main/java/com/company/services/`
**Command:** `:NewFile UserService.java`
**Generated content:**
```java
package com.company.services;

public class UserService {
    // TODO: Implement class
}
```

## C# Examples

### Directory: `/project/src/MyProject/Services/`
**Command:** `:NewFile UserService.cs`
**Generated content:**
```csharp
namespace MyProject.Services
{

class UserService
{
    // TODO: Implement class
}
```

### Directory: `/project/Source/DataAccess/Repositories/`
**Command:** `:NewFile UserRepository.cs`
**Generated content:**
```csharp
namespace DataAccess.Repositories
{

class UserRepository
{
    // TODO: Implement class
}
```

## Kotlin Examples

### Directory: `/project/src/main/kotlin/com/example/domain/`
**Command:** `:NewFile UserModel.kt`
**Generated content:**
```kotlin
package com.example.domain

```

## Directory Structure Impact

The plugin intelligently detects project structure and generates appropriate namespaces:

### Go Project Structure
```
/project/
├── go.mod
├── main/
│   └── main.go          → package main
├── utils/
│   └── helper.go        → package utils
└── calculations/
    └── math.go          → package calculations
```

### PHP Project Structure
```
/project/
├── composer.json
├── src/
│   ├── Controllers/
│   │   └── UserController.php    → namespace Controllers;
│   └── Models/
│       └── User.php              → namespace Models;
└── app/
    └── Services/
        └── AuthService.php       → namespace Services;
```

### Java Project Structure
```
/project/
├── pom.xml
└── src/
    └── main/
        └── java/
            └── com/
                └── example/
                    ├── models/
                    │   └── User.java     → package com.example.models;
                    └── services/
                        └── UserService.java → package com.example.services;
```

## Special Features

### Template Detection
- Files named `main.go` automatically get the main template
- Files starting with uppercase letters get class templates (PHP, Java, C#)
- Interface files get interface templates

### Project Root Detection
The plugin looks for these files to determine the project root:
- `go.mod` (Go)
- `composer.json` (PHP)
- `pom.xml` (Java Maven)
- `build.gradle` (Gradle)
- `.git` (Git repository)
- And more...

### Directory Name Transformations
- Go: kebab-case → snake_case (`my-package` → `my_package`)
- Java/Kotlin: kebab-case → camelCase (`user-service` → `userService`)
- PHP: kebab-case → PascalCase (`user-service` → `UserService`)
- C#: kebab-case → PascalCase (`data-access` → `DataAccess`) 