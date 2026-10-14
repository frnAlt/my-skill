---
name: nodejs-bot-engineering
description: Diagnostic and architectural skill for building, repairing, and scaling Node.js bots (Discord.js, Telegraf, FCA/Facebook, WhatsApp, and automation daemons). Use when diagnosing bot crashes, unhandled rejections, EventEmitter memory leaks, socket reconnection drops, CJS/ESM module conflicts, or designing robust multi-command architectures.
---

# Node.js Bot Engineering & Crash Recovery

This skill provides production standards for building resilient Node.js bots, resolving common runtime crashes, eliminating event memory leaks, and managing WebSocket socket life cycles.

## 1. Process Crash Prevention & Unhandled Rejection Traps

Node.js exits with non-zero status on unhandled promise rejections unless explicitly trapped. Always mount defensive global handlers:

```typescript
// src/processGuard.ts
import { Logger } from './logger';

export function setupProcessGuards(cleanupFn?: () => Promise<void>) {
  // Catch unhandled asynchronous rejections without silently dying
  process.on('unhandledRejection', (reason: unknown, promise: Promise<unknown>) => {
    Logger.error('Unhandled Promise Rejection detected:', {
      reason: reason instanceof Error ? reason.stack || reason.message : reason,
      promise,
    });
  });

  // Catch synchronous exceptions, log full stack trace, then perform graceful exit
  process.on('uncaughtException', async (error: Error) => {
    Logger.fatal('Uncaught Exception occurred:', error.stack || error.message);
    if (cleanupFn) {
      try {
        await cleanupFn();
      } catch (err) {
        Logger.error('Error during emergency shutdown cleanup:', err);
      }
    }
    process.exit(1);
  });

  // Handle process signals from orchestrators (Docker, PM2, systemd, Kubernetes)
  const signals: NodeJS.Signals[] = ['SIGINT', 'SIGTERM', 'SIGHUP'];
  for (const signal of signals) {
    process.on(signal, async () => {
      Logger.info(`Received ${signal}. Starting graceful shutdown...`);
      if (cleanupFn) await cleanupFn();
      process.exit(0);
    });
  }
}
```

## 2. EventEmitter Memory Leak Elimination

When bots register dynamic handlers on message streams or socket events, listeners accumulate:

```text
(node:12345) MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 message listeners added.
```

### Remedies:
1. **Never mount listeners inside command execution paths:**
   - ❌ *Incorrect:* `client.on('message', ...)` inside a command function.
   - ✔ *Correct:* Mount listeners **once** during startup, route events through a centralized dispatcher.
2. **Explicitly deregister temporary collectors:**
   ```typescript
   // For one-off await messages or reactions:
   const collector = channel.createMessageComponentCollector({ filter, time: 30000 });
   collector.on('collect', interaction => handleInteraction(interaction));
   collector.on('end', () => collector.removeAllListeners());
   ```
3. **Explicit listener limits:** If high concurrent listeners are required by design:
   ```typescript
   emitter.setMaxListeners(50);
   ```

## 3. Resolving CJS & ESM Dependency Conflicts

Common errors: `ERR_REQUIRE_ESM`, `ERR_MODULE_NOT_FOUND`, `SyntaxError: Cannot use import statement outside a module`.

| Scenario | Diagnosis | Solution |
| :--- | :--- | :--- |
| Importing pure ESM package (e.g. `node-fetch@3`, `chalk@5`) in CommonJS | `ERR_REQUIRE_ESM` | Use dynamic import: `const fetch = (...args) => import('node-fetch').then(({default: f}) => f(...args));` OR migrate `package.json` to `"type": "module"`. |
| Importing CommonJS into ESM | Named import failure | Use default import then destructure: `import pkg from 'cjs-module'; const { foo } = pkg;` |
| TypeScript compilation failure | `moduleResolution` mismatch | In `tsconfig.json`, set `"moduleResolution": "NodeNext"`, `"module": "NodeNext"`. |

## 4. Resilient WebSocket Reconnection & Heartbeat Watchdogs

When bots lose internet connection or the gateway drops the connection, a naive bot hangs indefinitely. Implement an exponential backoff with jitter:

```typescript
class ReconnectingSocketGateway {
  private retryCount = 0;
  private maxRetries = 10;
  private baseDelayMs = 1000;
  private maxDelayMs = 60000;
  private heartbeatInterval: NodeJS.Timeout | null = null;

  public connect(): void {
    try {
      this.initiateSocketConnection();
      this.startHeartbeat();
      this.retryCount = 0; // Reset upon successful handshake
    } catch (err) {
      this.scheduleReconnect();
    }
  }

  private scheduleReconnect(): void {
    if (this.retryCount >= this.maxRetries) {
      Logger.fatal('Maximum socket reconnection retries reached. Exiting for process manager restart.');
      process.exit(1);
    }

    const jitter = Math.random() * 500;
    const delay = Math.min(this.baseDelayMs * (2 ** this.retryCount), this.maxDelayMs) + jitter;
    this.retryCount++;
    Logger.warn(`Connection dropped. Reconnecting in ${(delay / 1000).toFixed(2)}s (Attempt ${this.retryCount}/${this.maxRetries})...`);

    setTimeout(() => this.connect(), delay);
  }

  private startHeartbeat(): void {
    if (this.heartbeatInterval) clearInterval(this.heartbeatInterval);
    this.heartbeatInterval = setInterval(() => {
      // Send ping packet. If no pong received within threshold, trigger reconnect
    }, 30000);
  }
}
```
