---
name: api-engineering-integration
description: Comprehensive API client engineering, authentication, session management, and debugging. Use when integrating third-party REST APIs, managing session cookies, implementing OAuth2 token refresh loops, handling cursor/offset pagination, parsing rate-limit headers (Retry-After), or generating reproducible curl commands.
---

# API Engineering & Third-Party Integration

This skill establishes patterns for developing resilient API clients, handling authentication and session persistence, managing rate limits, and debugging failed HTTP interactions.

## 1. Authentication & Automatic Token Refresh

When consuming OAuth2 APIs, never make requests with expired tokens. Implement an interceptor with automated queueing during token refresh:

```typescript
import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';

class ApiClient {
  private client: AxiosInstance;
  private isRefreshing = false;
  private failedQueue: Array<{
    resolve: (token: string) => void;
    reject: (error: any) => void;
  }> = [];

  constructor(baseURL: string) {
    this.client = axios.create({ baseURL, timeout: 10000 });
    this.setupInterceptors();
  }

  private setupInterceptors() {
    this.client.interceptors.response.use(
      response => response,
      async error => {
        const originalRequest = error.config;
        if (error.response?.status === 401 && !originalRequest._retry) {
          if (this.isRefreshing) {
            return new Promise((resolve, reject) => {
              this.failedQueue.push({ resolve, reject });
            }).then(token => {
              originalRequest.headers.Authorization = `Bearer ${token}`;
              return this.client(originalRequest);
            });
          }

          originalRequest._retry = true;
          this.isRefreshing = true;

          try {
            const newToken = await this.refreshAccessToken();
            this.processQueue(null, newToken);
            originalRequest.headers.Authorization = `Bearer ${newToken}`;
            return this.client(originalRequest);
          } catch (refreshErr) {
            this.processQueue(refreshErr, null);
            return Promise.reject(refreshErr);
          } finally {
            this.isRefreshing = false;
          }
        }
        return Promise.reject(error);
      }
    );
  }

  private processQueue(error: any, token: string | null) {
    this.failedQueue.forEach(prom => {
      if (error) prom.reject(error);
      else prom.resolve(token!);
    });
    this.failedQueue = [];
  }

  private async refreshAccessToken(): Promise<string> {
    // Call token endpoint with refresh_token
    return "NEW_ACCESS_TOKEN";
  }
}
```

## 2. Cookie Jar & Session Persistence

When an API relies on stateful cookies (`Set-Cookie`) across multiple steps:

```typescript
import axios from 'axios';
import { wrapper } from 'axios-cookiejar-support';
import { CookieJar } from 'tough-cookie';

export function createPersistentSession() {
  const jar = new CookieJar();
  const client = wrapper(axios.create({
    jar,
    withCredentials: true,
    headers: {
      'User-Agent': 'Antigravity-API-Client/1.0',
      'Accept': 'application/json',
    },
  }));
  return { client, jar };
}
```

## 3. Rate-Limit Handling (`Retry-After`)

Honor server-provided rate limit directives:

```typescript
async function requestWithRateLimitRetry(fn: () => Promise<any>, maxRetries = 3): Promise<any> {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error: any) {
      if (error.response?.status === 429 && attempt < maxRetries - 1) {
        const retryAfterHeader = error.response.headers['retry-after'];
        let waitMs = 2000 * Math.pow(2, attempt); // Fallback exponential backoff

        if (retryAfterHeader) {
          const parsedSeconds = parseInt(retryAfterHeader, 10);
          if (!isNaN(parsedSeconds)) {
            waitMs = parsedSeconds * 1000;
          } else {
            const retryDate = new Date(retryAfterHeader).getTime();
            if (!isNaN(retryDate)) waitMs = Math.max(0, retryDate - Date.now());
          }
        }

        console.warn(`429 Rate Limit encountered. Backing off for ${waitMs / 1000}s...`);
        await new Promise(res => setTimeout(res, waitMs));
        continue;
      }
      throw error;
    }
  }
}
```

## 4. Curl Reproduction for Accurate Debugging

When an API call fails with cryptic status codes, convert the request into a standalone curl command to test outside the application runtime:

```bash
curl -vvv -X POST "https://api.example.com/v1/resource" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Idempotency-Key: uuid-v4-here" \
  -d '{"key": "value"}'
```
