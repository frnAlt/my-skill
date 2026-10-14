---
name: fastapi-rest-apis
description: Production design and implementation patterns for modern asynchronous Python REST APIs using FastAPI and Pydantic v2. Use when creating API routers, dependency injection pipelines, request/response validation schemas, JWT authentication, background workers, or SQLAlchemy 2.0 async sessions.
---

# FastAPI & Modern Python REST APIs

This skill provides architecture and implementation guidelines for high-throughput, type-safe REST APIs using FastAPI and Pydantic v2.

## 1. Project Directory Layout

```text
api/
├── main.py                 # FastAPI application instance & middleware
├── config.py               # pydantic_settings BaseSettings configuration
├── dependencies.py         # Auth, DB session, rate limiting dependencies
├── models/                 # SQLAlchemy 2.0 ORM database models
├── schemas/                # Pydantic v2 request/response schemas
├── routers/                # Modular APIRouters (v1/users.py, v1/items.py)
└── services/               # Core business logic isolated from HTTP transport
```

## 2. Application Setup with Lifespan & CORS

```python
# main.py
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import items, auth

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Initialize DB pools, Redis clients, caches
    print("Application starting up...")
    yield
    # Shutdown: Close connections cleanly
    print("Application shutting down...")

app = FastAPI(
    title="High-Performance API",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(items.router, prefix="/api/v1/items", tags=["items"])
```

## 3. Strict Pydantic v2 Schemas

```python
# schemas/item.py
from datetime import datetime
from pydantic import BaseModel, Field, ConfigDict

class ItemBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=100)
    description: str | None = Field(default=None, max_length=500)
    price: float = Field(..., gt=0.0)

class ItemCreate(ItemBase):
    pass

class ItemResponse(ItemBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
```

## 4. Async Router with Dependency Injection

```python
# routers/items.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List

from schemas.item import ItemCreate, ItemResponse
from dependencies import get_db, get_current_user

router = APIRouter()

@router.get("/", response_model=List[ItemResponse])
async def list_items(
    skip: int = 0,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user)
):
    # Query database via async session
    return []

@router.post("/", response_model=ItemResponse, status_code=status.HTTP_201_CREATED)
async def create_item(
    payload: ItemCreate,
    db: AsyncSession = Depends(get_db),
    user = Depends(get_current_user)
):
    # Business logic execution
    return {"id": 1, **payload.model_dump(), "created_at": datetime.utcnow()}
```
