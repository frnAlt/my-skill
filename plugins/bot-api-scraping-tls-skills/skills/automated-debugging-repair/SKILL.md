---
name: automated-debugging-repair
description: Systematic process for analyzing stack traces, isolating root causes, reproducing failures with minimal tests, applying targeted fixes, and verifying zero regressions. Use when investigating test failures, build errors, exceptions, or runtime crashes.
---

# Automated Debugging & Code Repair Specialist

This skill defines a disciplined, 4-phase methodology for investigating, isolating, repairing, and verifying bugs in any codebase.

## The 4-Phase Debugging Workflow

```
[Phase 1: Trace Analysis] ──> [Phase 2: Minimal Reproduction] ──> [Phase 3: Root Cause Fix] ──> [Phase 4: Regression Verification]
```

### Phase 1: Stack Trace Deconstruction

1. **Locate the First Application Frame:**
   - Filter out framework internals (`node_modules/`, `lib/python3.x/`, `vendor/`).
   - Find the exact file name and line number in user code that initiated the failure.
2. **Classify the Failure Pattern:**
   - **TypeError / Null Dereference:** Property accessed on `undefined` or `None`.
   - **ReferenceError:** Undefined variable, circular import, or missing export.
   - **AssertionError:** Business logic invariant failed.
   - **Network / Socket Error:** Timeout, DNS failure (`ENOTFOUND`), TLS handshake rejected.
   - **Syntax / Build Error:** Incompatible language feature, missing tsconfig setting, or corrupted lockfile.

### Phase 2: Minimal Reproduction (Failing Test)

Before touching production code, write a focused test case or scratch script that triggers the failure consistently:

```bash
# In JavaScript/TypeScript (Jest/Vitest/Mocha)
npm test -- -t "reproducing test name"

# In Python (pytest)
pytest tests/test_reproduce.py -v
```

Confirm that the test fails for the exact reason described in the original bug report.

### Phase 3: Root Cause Fix (Minimal Delta)

- Formulate a single, verified hypothesis explaining **why** the bug happened.
- Apply the minimal change required to fix the root cause.
- Avoid shotgun debugging (changing multiple random files or adding speculative type assertions without verifying the data flow).
- Preserve existing APIs, docstrings, and comments.

### Phase 4: Regression Verification

1. Run the targeted reproducing test $\rightarrow$ Verify it passes (**Green**).
2. Run the entire project test suite $\rightarrow$ Verify zero regressions across other modules:
   ```bash
   npm test
   # or
   pytest
   ```
3. Run linter and typechecker:
   ```bash
   npm run lint && npm run typecheck
   # or
   flake8 && mypy .
   ```
