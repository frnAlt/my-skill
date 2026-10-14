---
name: web-scraping-playwright-puppeteer
description: Production web scraping and browser automation using Playwright, Puppeteer, and Cheerio. Use when extracting structured data from modern websites, handling pagination, implementing rate limiters (p-limit, Bottleneck), managing session cookies, evading bot detection safely, or intercepting network requests.
---

# Advanced Web Scraping & Browser Automation

This skill provides robust guidelines for reliable data extraction, pagination patterns, rate-limiting, and browser automation using Playwright and Puppeteer.

## 1. Ethical, Safe & Scalable Scraping Rules

- **Respect robots.txt & Service Boundaries:** Do not flood target endpoints. Enforce client-side rate limits.
- **Never Globally Disable SSL:** Never use `rejectUnauthorized: false` or disable TLS checks globally. Configure legitimate proxy CA certs if inspecting traffic through an authorized proxy.
- **Save Bandwidth with Route Interception:** Abort requests for images, fonts, tracking pixels, and CSS when only text/data is required.

## 2. Bandwidth Optimization via Route Abort (Playwright)

```typescript
import { chromium, Browser, Page } from 'playwright';

export async function launchOptimizedScraper(): Promise<{ browser: Browser; page: Page }> {
  const browser = await chromium.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage'],
  });

  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36',
  });

  const page = await context.newPage();

  // Block unnecessary heavy assets to speed up extraction by 5-10x
  await page.route('**/*', (route) => {
    const resourceType = route.request().resourceType();
    if (['image', 'media', 'font', 'stylesheet'].includes(resourceType)) {
      route.abort();
    } else {
      route.continue();
    }
  });

  return { browser, page };
}
```

## 3. Resilient Pagination Patterns

### Pattern A: Next-Page Selector Navigation
```typescript
async function scrapeAllPages(page: Page, baseUrl: string) {
  const allResults = [];
  await page.goto(baseUrl, { waitUntil: 'domcontentloaded' });

  while (true) {
    // 1. Extract items on current page
    const items = await page.$$eval('.item-card', cards => 
      cards.map(c => ({
        title: c.querySelector('h3')?.textContent?.trim() || '',
        price: c.querySelector('.price')?.textContent?.trim() || '',
      }))
    );
    allResults.push(...items);

    // 2. Check for "Next" button
    const nextButton = await page.$('a[rel="next"], .pagination-next:not([disabled])');
    if (!nextButton) break;

    // 3. Click and wait for network or DOM stabilization
    await Promise.all([
      page.waitForNavigation({ waitUntil: 'domcontentloaded', timeout: 10000 }).catch(() => {}),
      nextButton.click(),
    ]);
  }
  return allResults;
}
```

### Pattern B: Infinite Scroll Pagination
```typescript
async function scrollUntilComplete(page: Page, maxScrolls = 20) {
  let previousHeight = await page.evaluate('document.body.scrollHeight');

  for (let i = 0; i < maxScrolls; i++) {
    await page.evaluate('window.scrollTo(0, document.body.scrollHeight)');
    await page.waitForTimeout(1500); // Allow dynamic fetch to trigger

    const newHeight = await page.evaluate('document.body.scrollHeight');
    if (newHeight === previousHeight) {
      // Reached the bottom of the feed
      break;
    }
    previousHeight = newHeight;
  }
}
```

## 4. Controlled Concurrency & Rate Limiting (`p-limit`)

Avoid sending hundreds of concurrent requests that trigger IP bans or 429 status codes:

```typescript
import pLimit from 'p-limit';

// Limit concurrent scraping workers to 5
const limit = pLimit(5);

async function scrapeBatch(urls: string[]) {
  const tasks = urls.map(url => limit(async () => {
    try {
      return await scrapeItemDetails(url);
    } catch (err) {
      console.error(`Failed to scrape ${url}:`, err);
      return null;
    }
  }));

  const results = await Promise.all(tasks);
  return results.filter(Boolean);
}
```
