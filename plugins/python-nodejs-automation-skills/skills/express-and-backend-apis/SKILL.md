---
name: express-and-backend-apis
description: Architecture standards for Node.js Express and TypeScript backend APIs and microservices. Use when structuring Express routers, request validation middleware with Zod, async error handling, JWT auth verification, helmet security headers, or rate-limiting.
---

# Express & TypeScript Backend API Specialist

This skill outlines production patterns for building robust, secure, and type-safe REST APIs with Express.js and TypeScript.

## 1. Type-Safe Architecture Layout

```text
src/
├── app.ts                  # Express application setup, middleware mounting
├── server.ts               # HTTP server listener and cluster management
├── routes/                 # Express Router modules
├── controllers/            # Route handler logic
├── middlewares/            # Auth, validation, error handler, rate-limiting
└── schemas/                # Zod request/response validation schemas
```

## 2. Express Server with Security Defaults

```typescript
// src/app.ts
import express, { Application } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';

const app: Application = express();

// Security headers
app.use(helmet());

// Cross-origin resource sharing
app.use(cors({ origin: process.env.ALLOWED_ORIGINS?.split(',') || '*' }));

// Body parser with strict limits
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// Global IP rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Max 100 requests per window
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

export default app;
```

## 3. Zod Request Validation Middleware

```typescript
// src/middlewares/validate.ts
import { Request, Response, NextFunction } from 'express';
import { AnyZodObject, ZodError } from 'zod';

export const validate = (schema: AnyZodObject) => {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      await schema.parseAsync({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        res.status(400).json({
          success: false,
          errors: error.errors.map(e => ({ path: e.path.join('.'), message: e.message })),
        });
        return;
      }
      next(error);
    }
  };
};
```

## 4. Centralized Async Error Handling

Avoid unhandled promise rejections by wrapping route handlers or using Express 5:

```typescript
// src/middlewares/errorHandler.ts
import { Request, Response, NextFunction, ErrorRequestHandler } from 'express';

export const errorHandler: ErrorRequestHandler = (err, req, res, next) => {
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';

  console.error(`[ERROR] ${req.method} ${req.url}:`, err.stack || err);

  res.status(statusCode).json({
    success: false,
    message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};
```
