---
name: nodejs-bot-architecture
description: Architectural guidance for building Node.js chat bots and automation tools (Discord.js, Telegraf, Facebook Messenger/fca-unofficial, Instagram automation). Use when creating event-driven bot handlers, managing socket reconnections, preventing event listener memory leaks, or structuring multi-platform bot commands.
---

# Node.js Bot Architecture & Automation

This skill provides patterns for building production Node.js chat bots, automation daemons, and socket-driven handlers.

## 1. Clean Modular Command & Event Handler Layout

```text
src/
├── index.ts                # Client initialization & process lifecycle
├── config.ts               # Environment validation (dotenv / clean-env)
├── events/                 # Discord/Telegram event listeners
│   ├── ready.ts
│   └── messageCreate.ts
├── commands/               # Modular bot commands
│   ├── ping.ts
│   └── info.ts
└── services/               # External APIs, database, rate limiters
```

## 2. Discord.js v14 TypeScript Architecture

```typescript
// src/index.ts
import { Client, GatewayIntentBits, Collection, Partials } from 'discord.js';
import dotenv from 'dotenv';

dotenv.config();

export class BotClient extends Client {
  public commands: Collection<string, any> = new Collection();
}

const client = new BotClient({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
    GatewayIntentBits.DirectMessages,
  ],
  partials: [Partials.Channel, Partials.Message],
});

// Avoid memory leaks by tracking and unbinding event listeners on shutdown
process.on('SIGINT', async () => {
  console.log('Shutting down gracefully...');
  client.destroy();
  process.exit(0);
});

client.login(process.env.DISCORD_TOKEN);
```

## 3. Resilient Long-Polling & Reconnection

When running socket-driven or long-polling bot engines (like Facebook Chat `fca-unofficial` or Telegram):

```javascript
// Reliable auto-reconnecting listener pattern
function startListener(api) {
  const stopListening = api.listenMqtt((err, event) => {
    if (err) {
      console.error('MQTT listener error encountered:', err);
      // Clean up previous listener before retrying
      if (typeof stopListening === 'function') stopListening();
      setTimeout(() => startListener(api), 5000);
      return;
    }

    handleEvent(api, event).catch(e => console.error('Handler error:', e));
  });
}
```

## 4. Preventing Event Listener & Memory Leaks

- **Always specify max listeners appropriately:** Avoid unmonitored event emitter churn (`emitter.setMaxListeners(20)`).
- **Clean timers on exit:** Always keep references to `setInterval` and `setTimeout` so they can be cleared via `clearInterval` during graceful termination.
- **Do not cache messages indefinitely in memory:** Restrict Discord.js message cache size via `ClientOptions.sweepers` to avoid OOM crashes on VPS instances:

```typescript
const client = new Client({
  sweepers: {
    messages: {
      interval: 3600, // Sweep every hour
      lifetime: 1800, // Discard messages older than 30 mins
    },
  },
  // ...
});
```
