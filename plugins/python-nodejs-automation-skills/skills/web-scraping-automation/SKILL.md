---
name: web-scraping-automation
description: Robust methodologies for web scraping, media downloading, API reverse-engineering, and anti-bot mitigation in Python and Node.js. Use when building web scrapers, extracting HTML/JSON from protected web pages, handling user-agent headers, parsing with BeautifulSoup/lxml, or orchestrating headless browsers with Playwright.
---

# Web Scraping & Automation Specialist

This skill provides patterns for extracting structured data from modern websites, media services, and undocumented APIs while adhering to resilient anti-bot practices.

## 1. Core Scraping Architecture

Always evaluate the target site in this order:
1. **Hidden JSON API**: Open DevTools Network tab. Filter by `Fetch/XHR`. If the frontend consumes a clean REST/GraphQL endpoint, consume the API directly rather than parsing HTML.
2. **Lightweight Static HTTP**: Use `httpx` with HTTP/2 and realistic browser headers.
3. **Headless Browser (Playwright)**: Required only when content depends on dynamic JavaScript evaluation, canvas verification, or complex interaction.

## 2. High-Performance Async Scraper (`httpx` + `BeautifulSoup`)

```python
import asyncio
import httpx
from bs4 import BeautifulSoup
from typing import List, Dict, Any

HEADERS = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Accept-Encoding": "gzip, deflate, br, zstd",
    "DNT": "1",
    "Connection": "keep-alive",
    "Upgrade-Insecure-Requests": "1",
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-User": "?1",
}

async def fetch_page(url: str, client: httpx.AsyncClient) -> str:
    response = await client.get(url, headers=HEADERS, timeout=15.0)
    response.raise_for_status()
    return response.text

def parse_items(html: str) -> List[Dict[str, Any]]:
    soup = BeautifulSoup(html, "lxml")
    results = []
    for card in soup.select("div.item-card"):
        title_el = card.select_one("h3.title")
        link_el = card.select_one("a.link")
        if title_el and link_el:
            results.append({
                "title": title_el.get_text(strip=True),
                "url": link_el.get("href"),
            })
    return results

async def main():
    async with httpx.AsyncClient(http2=True, follow_redirects=True) as client:
        html = await fetch_page("https://example.com/items", client)
        items = parse_items(html)
        print(f"Scraped {len(items)} items")

if __name__ == "__main__":
    asyncio.run(main())
```

## 3. Playwright Stealth Automation

When dealing with Cloudflare challenge pages, SPA rendering, or lazy-loaded infinite scrolling:

```python
import asyncio
from playwright.async_api import async_playwright

async def scrape_spa(url: str):
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context(
            user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
            viewport={"width": 1920, "height": 1080},
            locale="en-US"
        )
        page = await context.new_page()

        # Mask webdriver flag
        await page.add_init_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")

        await page.goto(url, wait_until="networkidle")
        
        # Scroll to trigger lazy loading
        for _ in range(3):
            await page.mouse.wheel(0, 1000)
            await asyncio.sleep(1)

        content = await page.content()
        await browser.close()
        return content
```

## 4. Media & Video Streaming Extraction Rules

- Always verify `Content-Type` and `Content-Length` headers before streaming downloads to disk.
- Stream chunks into disk with `aiofiles` or async iterators:
  ```python
  async with client.stream("GET", media_url) as resp:
      with open("video.mp4", "wb") as f:
          async for chunk in resp.aiter_bytes(chunk_size=65536):
              f.write(chunk)
  ```
