---
name: browser-qa
description: "Use when: manually testing browser behavior, debugging UI issues, or verifying cross-browser compatibility."
user-invocable: true
---

# Browser QA

## When to Activate

- Testing browser rendering
- Debugging CSS/JS issues
- Verifying cross-browser compatibility
- Manual QA test plans

## Core Concepts

### QA Checklist

- [ ] Responsive: mobile, tablet, desktop
- [ ] Cross-browser: Chrome, Firefox, Safari, Edge
- [ ] Loading states visible
- [ ] Empty states handled
- [ ] Error states visible
- [ ] Keyboard navigation works
- [ ] Screen reader friendly
- [ ] Touch targets ≥ 44px
- [ ] Console errors = 0
- [ ] Network requests complete successfully

## Best Practices

- Use Browser DevTools for debugging
- Test on real devices (not just emulation)
- Document test cases with screenshots
- Use BrowserStack for cross-browser coverage
