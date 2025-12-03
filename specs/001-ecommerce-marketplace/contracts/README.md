# API Contracts

**Feature**: Multi-Vendor E-Commerce Marketplace  
**Branch**: `001-ecommerce-marketplace`  
**Date**: 2025-12-03  
**Purpose**: OpenAPI 3.0 specifications for all REST API endpoints.

## Overview

This directory contains REST API contracts organized by feature domain. Each OpenAPI spec defines request/response schemas, authentication requirements, error codes, and example payloads.

## Files

- `auth.yaml` - Authentication & authorization (login, register, OTP, token refresh)
- `products.yaml` - Product catalog (search, browse, product details, reviews)
- `cart.yaml` - Shopping cart operations (add, update, remove, sync)
- `orders.yaml` - Order management (checkout, order history, tracking, cancellation)
- `seller.yaml` - Seller features (shop setup, product management, order fulfillment, analytics)
- `chat.yaml` - Buyer-seller messaging (REST endpoints for history, WebSocket for real-time)
- `admin.yaml` - Platform administration (content moderation, user management, campaigns)
- `common.yaml` - Shared schemas, error responses, pagination patterns

## Base URL

```
Development: http://localhost:3000/api/v1
Production: https://api.marketplace.example.com/api/v1
```

## Authentication

All authenticated endpoints require JWT Bearer token in header:

```http
Authorization: Bearer <access_token>
```

Token obtained from `/auth/login` or `/auth/register` endpoints.

## Common Response Format

### Success Response
```json
{
  "success": true,
  "data": { /* response payload */ },
  "message": "Operation successful"
}
```

### Error Response
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message",
    "details": { /* additional error context */ }
  }
}
```

## Pagination

List endpoints use cursor-based pagination:

**Request**:
```
GET /products?limit=20&cursor=eyJpZCI6IjEyMyJ9
```

**Response**:
```json
{
  "success": true,
  "data": {
    "items": [ /* array of items */ ],
    "pagination": {
      "nextCursor": "eyJpZCI6IjE0MyJ9",
      "hasMore": true,
      "total": 150
    }
  }
}
```

## Rate Limiting

- **Authenticated**: 1000 requests/hour per user
- **Anonymous**: 100 requests/hour per IP
- Rate limit headers included in responses:
  ```
  X-RateLimit-Limit: 1000
  X-RateLimit-Remaining: 987
  X-RateLimit-Reset: 1701612000
  ```

## Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_REQUEST` | 400 | Malformed request body or parameters |
| `UNAUTHORIZED` | 401 | Missing or invalid authentication token |
| `FORBIDDEN` | 403 | User lacks permission for this action |
| `NOT_FOUND` | 404 | Requested resource does not exist |
| `CONFLICT` | 409 | Resource conflict (e.g., duplicate email) |
| `VALIDATION_ERROR` | 422 | Request validation failed |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `INTERNAL_SERVER_ERROR` | 500 | Unexpected server error |

## Viewing the Specs

Use Swagger UI to view interactive API documentation:

```bash
# Install Swagger UI
npm install -g swagger-ui-watcher

# Serve docs
swagger-ui-watcher contracts/auth.yaml
```

Or use online tool: https://editor.swagger.io/
