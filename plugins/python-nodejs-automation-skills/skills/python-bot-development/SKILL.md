---
name: python-bot-development
description: Specialist guidance for developing asynchronous Python bots (Telegram Bot API via python-telegram-bot or aiogram, Discord bots via discord.py, and automated social media workflows). Use when creating bot commands, handling rate limits, managing conversational state (FSM), webhook vs polling configurations, or handling async concurrency.
---

# Python Bot Engineering Specialist

This skill provides production standards for building asynchronous, resilient bots in Python using `aiogram` (Telegram) and `discord.py`.

## 1. Asynchronous Architecture Principles

- **Never block the event loop:** Never execute synchronous network calls (`requests.get`), time-consuming CPU operations, or blocking file I/O inside async handlers. Use `httpx.AsyncClient` or `aiofiles`.
- **Graceful Error Handling:** Wrap handler logic in try-except blocks that capture API rate limits (e.g., `TelegramRetryAfter`) and log context without crashing the worker.
- **Session Persistence & State:** Store conversational state (FSM) in Redis or a persistent database rather than in-memory dictionaries that reset on reboot.

## 2. Production Telegram Bot (`aiogram` v3)

```python
import asyncio
import logging
from aiogram import Bot, Dispatcher, types, F
from aiogram.filters import CommandStart, Command
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.fsm.storage.memory import MemoryStorage

logging.basicConfig(level=logging.INFO)

class UserForm(StatesGroup):
    waiting_for_name = State()
    waiting_for_confirmation = State()

dp = Dispatcher(storage=MemoryStorage())

@dp.message(CommandStart())
async def handle_start(message: types.Message, state: FSMContext):
    await message.answer("Welcome! Please reply with your full name:")
    await state.set_state(UserForm.waiting_for_name)

@dp.message(UserForm.waiting_for_name, F.text)
async def process_name(message: types.Message, state: FSMContext):
    await state.update_data(name=message.text)
    await message.answer(f"Got it, {message.text}! Type /confirm to proceed.")
    await state.set_state(UserForm.waiting_for_confirmation)

@dp.message(UserForm.waiting_for_confirmation, Command("confirm"))
async def process_confirmation(message: types.Message, state: FSMContext):
    data = await state.get_data()
    await message.answer(f"Setup complete for {data.get('name')}.")
    await state.clear()

async def main():
    bot = Bot(token="YOUR_BOT_TOKEN")
    await dp.start_polling(bot, allowed_updates=dp.resolve_used_update_types())

if __name__ == "__main__":
    asyncio.run(main())
```

## 3. Production Discord Bot (`discord.py`)

```python
import discord
from discord.ext import commands

intents = discord.Intents.default()
intents.message_content = True

bot = commands.Bot(command_prefix="!", intents=intents)

@bot.event
async def on_ready():
    print(f"Logged in as {bot.user} (ID: {bot.user.id})")
    await bot.change_presence(activity=discord.Game(name="Antigravity Automation"))

@bot.command(name="ping")
async def ping(ctx: commands.Context):
    latency = round(bot.latency * 1000)
    await ctx.reply(f"Pong! Latency: {latency}ms")

@bot.event
async def on_command_error(ctx: commands.Context, error: Exception):
    if isinstance(error, commands.CommandNotFound):
        return
    if isinstance(error, commands.MissingRequiredArgument):
        await ctx.reply(f"Missing parameter: {error.param.name}")
        return
    await ctx.reply(f"Error occurred: {str(error)}")
```

## 4. Rate Limiting & Backoff Strategy

```python
import asyncio
from typing import Callable, Any

async def with_backoff(coro_func: Callable[..., Any], *args, max_retries: int = 5, base_delay: float = 1.0, **kwargs):
    """Executes an async API request with exponential backoff and jitter."""
    for attempt in range(max_retries):
        try:
            return await coro_func(*args, **kwargs)
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            delay = base_delay * (2 ** attempt)
            logging.warning(f"Request failed ({e}). Retrying in {delay:.2f}s...")
            await asyncio.sleep(delay)
```
