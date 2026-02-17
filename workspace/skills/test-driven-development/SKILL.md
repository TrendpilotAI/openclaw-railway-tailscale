---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code
---

# Test-Driven Development (TDD)

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## When to Use

**Always:** New features, bug fixes, refactoring, behavior changes

**Exceptions (ask your human partner):** Throwaway prototypes, generated code, config files

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over. No exceptions.

## Red-Green-Refactor

### RED - Write Failing Test
- One behavior, clear name, real code (no mocks unless unavoidable)
- Run test, confirm it fails for the expected reason

### GREEN - Minimal Code
- Write simplest code to pass the test
- Don't add features beyond the test

### REFACTOR - Clean Up
- Remove duplication, improve names, extract helpers
- Keep tests green. Don't add behavior.

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
| **Clear** | Name describes behavior | `test('test1')` |
| **Shows intent** | Demonstrates desired API | Obscures what code should do |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "TDD will slow me down" | TDD faster than debugging. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |

## Example: Bug Fix

**Bug:** Empty email accepted

**RED:** `test('rejects empty email', ...)` -> FAIL: expected 'Email required', got undefined

**GREEN:** Add `if (!data.email?.trim()) return { error: 'Email required' }` -> PASS

**REFACTOR:** Extract validation for multiple fields if needed.

## Verification Checklist

- [ ] Every new function has a test
- [ ] Watched each test fail before implementing
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass with pristine output
- [ ] Edge cases and errors covered
