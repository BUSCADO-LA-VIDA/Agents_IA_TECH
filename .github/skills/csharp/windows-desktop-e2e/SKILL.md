---
name: windows-desktop-e2e
description: "Use when: testing Windows desktop applications end-to-end, WinForms, WPF, or WinUI automation."
user-invocable: true
---

# Windows Desktop E2E

## When to Activate

- Writing E2E tests for Windows desktop apps
- Automating WinForms/WPF UI testing
- Setting up Appium or WinAppDriver

## Core Concepts

### WinAppDriver Pattern

```csharp
// E2E test with WinAppDriver
[TestMethod]
public void Login_ValidCredentials_OpensDashboard()
{
    var session = new WindowsDriver<WindowsElement>(
        new Uri("http://127.0.0.1:4723"),
        new DesiredCapabilities { { "app", "MyApp.exe" } });

    var username = session.FindElementByAccessibilityId("txtUsername");
    username.SendKeys("admin");

    var password = session.FindElementByAccessibilityId("txtPassword");
    password.SendKeys("pass123");

    session.FindElementByAccessibilityId("btnLogin").Click();

    var dashboard = session.FindElementByAccessibilityId("dashboardView");
    Assert.IsNotNull(dashboard);
}
```

## Best Practices

- Use AutomationId for element identification
- Use Appium/WinAppDriver for automation
- Test critical user flows only
- Use video recording for debugging failures
