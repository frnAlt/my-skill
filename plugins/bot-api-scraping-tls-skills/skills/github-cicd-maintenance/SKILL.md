---
name: github-cicd-maintenance
description: Automated CI/CD pipeline authoring, GitHub Actions workflow optimization, dependency upgrade management, and repository maintenance. Use when configuring .github/workflows/*.yml, setting up multi-version test matrices, configuring Dependabot, caching build artifacts, or debugging GitHub Actions runner failures.
---

# GitHub CI/CD & Repository Maintenance Specialist

This skill provides templates and engineering rules for constructing hardened, performant GitHub Actions workflows, dependency upgrade routines, and test automation matrices.

## 1. Hardened GitHub Actions Test Matrix (`.github/workflows/ci.yml`)

```yaml
name: Continuous Integration

on:
  push:
    branches: [ main, master, develop ]
  pull_request:
    branches: [ main, master ]

permissions:
  contents: read

jobs:
  test:
    name: Test on Node ${{ matrix.node-version }} (${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ ubuntu-latest ]
        node-version: [ 18.x, 20.x, 22.x ]

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          persist-credentials: false

      - name: Setup Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies strictly from lockfile
        run: npm ci

      - name: Run linter & typecheck
        run: |
          npm run lint --if-present
          npm run typecheck --if-present

      - name: Execute test suite
        run: npm test -- --coverage
```

## 2. Automated Dependency Upgrades (`.github/dependabot.yml`)

Keep dependencies secure without manual overhead:

```yaml
version: 2
updates:
  # Maintain npm dependencies
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 10
    versioning-strategy: increase
    labels:
      - "dependencies"
      - "javascript"

  # Maintain GitHub Actions dependencies
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "ci"
      - "actions"
```

## 3. Fast Debugging of Failed GitHub Actions

When an action fails on GitHub:
1. **Inspect step summary:** Check which job and step failed.
2. **Reproduce locally:** Run the exact command in the container or local shell with the specified Node or Python version.
3. **Verify lockfile synchronization:** If `npm ci` fails with `npm ERR! code EUSAGE`, run `npm install --package-lock-only` locally and commit the updated `package-lock.json`.
4. **Never store secrets in workflow logs:** Mask credentials with `::add-mask::<secret>` if writing scripts that touch sensitive tokens.
