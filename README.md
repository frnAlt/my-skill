# Antigravity & Agent Skills Suite (`my-skill`)

A comprehensive, curated collection of production-grade agent skills, workflows, and plugins for **Google Antigravity**, **Claude Code**, and **Agent Skills**-compatible coding environments.

---

## 📦 What's Inside

### 1. `plugins/bot-api-scraping-tls-skills/`
- **`nodejs-bot-engineering`**: Process crash prevention (`unhandledRejection`, `uncaughtException`), EventEmitter memory leak elimination, CJS/ESM interop, WebSocket backoff and reconnection logic.
- **`web-scraping-playwright-puppeteer`**: Resilient DOM pagination, route aborts for images/fonts, concurrency controls (`p-limit`), and headless browser automation without disabling SSL.
- **`api-engineering-integration`**: REST client design, automatic OAuth2 token refresh queues, cookie jar sessions, rate limit parsing (`Retry-After`), and curl debugging.
- **`ssl-tls-https-diagnostics`**: Diagnosis for `UNABLE_TO_VERIFY_LEAF_SIGNATURE`, `CERT_HAS_EXPIRED`, `ERR_TLS_CERT_ALTNAME_INVALID`, OpenSSL handshake inspection, and secure custom CA injection (`NODE_EXTRA_CA_CERTS`).
- **`automated-debugging-repair`**: 4-phase debugging (Trace Analysis $\rightarrow$ Minimal Reproduction $\rightarrow$ Root Cause Fix $\rightarrow$ Regression Verification).
- **`github-cicd-maintenance`**: Hardened GitHub Actions test matrices across Node.js/Python versions, Dependabot configuration, and lockfile synchronization.

### 2. `plugins/python-nodejs-automation-skills/`
- **`python-bot-development`**: Async Telegram (`aiogram` v3) and Discord (`discord.py`) bots with FSM and rate limiting.
- **`web-scraping-automation`**: HTTP/2 scraping using `httpx` and `BeautifulSoup` with anti-bot header profiles.
- **`fastapi-rest-apis`**: High-performance FastAPI with Pydantic v2 schemas and async database sessions.
- **`nodejs-bot-architecture`**: Discord.js v14, Telegraf, and chat automation daemon patterns.
- **`express-and-backend-apis`**: Express + TypeScript with Zod validation, helmet, and rate limiting.

### 3. `plugins/android-rom-and-gradle-skills/`
- **`android-gradle-builds`**: Gradle Version Catalogs (`libs.versions.toml`), ProGuard/R8, daemon memory tuning, and dependency conflict resolution.
- **`adb-fastboot-device-control`**: Filtered logcat crash debugging, activity/package management, and Fastboot partition flashing.
- **`android-rom-device-tree`**: AOSP, LineageOS, and custom ROM device trees (`BoardConfig.mk`, `device.mk`), vendor blob extraction, and SELinux denial fixes.

### 4. `plugins/superpowers/`
- Standardized software engineering skills by `@obra`:
  - `test-driven-development` (Strict Red-Green-Refactor)
  - `systematic-debugging` (4-phase root-cause analysis)
  - `brainstorming` (Socratic requirements clarification)
  - `writing-plans` (2-to-5 minute task breakdowns)
  - `executing-plans` & `subagent-driven-development`
  - `using-git-worktrees` & `verification-before-completion`

### 5. `plugins/sentry-skills/`
- Sentry production engineering skills:
  - `security-review` (High-confidence OWASP/CWE vulnerability reviews)
  - `gha-security-review` (GitHub Actions workflow exploit audits)
  - `find-bugs` & `code-simplifier`
  - `commit`, `create-branch`, `pr-writer`, `iterate-pr`, `gh-review-requests`

### 6. `plugins/anthropic-skills/`
- Official Anthropic agent skills:
  - `webapp-testing` (Playwright component and browser testing)
  - `frontend-design` & `web-artifacts-builder`
  - `mcp-builder` & `skill-creator`
  - Document processing suites (`pdf`, `docx`, `pptx`, `xlsx`)

### 7. `plugins/vercel-web-skills/`
- Vercel engineering best practices:
  - `react-best-practices` (Next.js App Router, Server Components, eliminating waterfalls)
  - `composition-patterns` & `react-view-transitions`
  - `react-native-skills`, `web-design-guidelines`, `vercel-optimize`

### 8. `skills/` (Standalone Cloud & Data Skills)
- `accidental-data-loss-prevention`
- `managing-python-dependencies`
- `ml-best-practices`
- `schema-mapping`
- `dbt-bigquery`, `dataform-bigquery`, `bigquery-sql`
- `gcp-dataflow`, `gcp-spark`, `gcp-pipeline-orchestration`

---

## 🚀 Installation

### Option 1: One-Line Terminal Install

```bash
git clone git@github.com:frnAlt/my-skill.git
cd my-skill
chmod +x install.sh
./install.sh
```

### Option 2: Selective Antigravity Plugin Installation

Install any specific plugin from this repository:

```bash
agy plugin install /path/to/my-skill/plugins/<plugin-name>
```

### Option 3: Automatic Workspace Discovery (`skills.json`)

To use these skills directly in any project, add this repository to your `.agents/skills.json`:

```json
{
  "inherits": [
    {
      "path": "/path/to/my-skill/skills.json"
    }
  ]
}
```

---

## 🔒 Security & Safe Open Source

- **No Stored Secrets:** No API keys, credentials, or private tokens are contained in this repository.
- **TLS Integrity:** All skills enforce strict SSL/TLS validation and prohibit dangerous global flags like `NODE_TLS_REJECT_UNAUTHORIZED='0'`.
