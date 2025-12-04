# API Documentation

This document describes all API endpoints used in the AI Flutter Marketplace application.

## Base Configuration

- **Base URL**: `http://localhost:3000/api/v1` (default, configurable via environment variables)
- **Connect Timeout**: 5 seconds
- **Receive Timeout**: 10 seconds
- **Send Timeout**: 10 seconds

All authenticated endpoints require an `Authorization` header with a Bearer token:
```
Authorization: Bearer {access_token}
```

---

## Authentication APIs

### 1. Register User
**POST** `/auth/register`

Register a new user account.

**Request Body**:
```json
{
  "phoneNumber": "string",
  "password": "string",
  "fullName": "string"
}
```

**Response** (200):
```json
{
  "id": "string",
  "phoneNumber": "string",
  "fullName": "string",
  "email": "string?",
  "avatarUrl": "string?",
  "isPhoneVerified": false,
  "createdAt": "timestamp"
}
```

**Errors**:
- `409 Conflict` - Phone number already exists

---

### 2. Verify OTP
**POST** `/auth/verify-otp`

Verify OTP code for phone verification.

**Request Body**:
```json
{
  "phoneNumber": "string",
  "otpCode": "string"
}
```

**Response** (200):
```json
{
  "accessToken": "string",
  "refreshToken": "string"
}
```

**Errors**:
- `400 Bad Request` - OTP invalid or expired

---

### 3. Login
**POST** `/auth/login`

Login with phone number and password.

**Request Body**:
```json
{
  "phoneNumber": "string",
  "password": "string"
}
```

**Response** (200):
```json
{
  "user": {
    "id": "string",
    "phoneNumber": "string",
    "fullName": "string",
    "email": "string?",
    "avatarUrl": "string?",
    "isPhoneVerified": true
  },
  "accessToken": "string",
  "refreshToken": "string"
}
```

**Errors**:
- `401 Unauthorized` - Invalid credentials
- `403 Forbidden` - Account suspended

---

### 4. Logout
**POST** `/auth/logout`

Logout and invalidate refresh token.

**Headers**: Requires authentication

**Response** (200): No content

---

### 5. Refresh Token
**POST** `/auth/refresh`

Refresh access token using refresh token.

**Request Body**:
```json
{
  "refreshToken": "string"
}
```

**Response** (200):
```json
{
  "accessToken": "string",
  "refreshToken": "string"
}
```

**Errors**:
- `401 Unauthorized` - Refresh token invalid or expired

---

### 6. Forgot Password
**POST** `/auth/forgot-password`

Request password reset OTP.

**Request Body**:
```json
{
  "phoneNumber": "string"
}
```

**Response** (200): No content

**Errors**:
- `404 Not Found` - Phone number not registered

---

### 7. Reset Password
**POST** `/auth/reset-password`

Reset password with OTP verification.

**Request Body**:
```json
{
  "phoneNumber": "string",
  "otpCode": "string",
  "newPassword": "string"
}
```

**Response** (200): No content

**Errors**:
- `400 Bad Request` - OTP invalid or expired

---

## Product APIs

### 8. Get Products
**GET** `/products`

Fetch paginated list of products with filters.

**Query Parameters**:
- `limit` (int, default: 20) - Number of items per page
- `cursor` (string, optional) - Pagination cursor
- `category_id` (string, optional) - Filter by category ID
- `min_price` (number, optional) - Minimum price filter
- `max_price` (number, optional) - Maximum price filter
- `rating` (number, optional) - Minimum rating filter (1-5)
- `condition` (string, optional) - Product condition filter
- `sort_by` (string, optional) - Sort option (e.g., "price_asc", "price_desc", "rating", "newest")

**Response** (200):
```json
{
  "data": [
    {
      "id": "string",
      "name": "string",
      "description": "string",
      "price": number,
      "originalPrice": number,
      "currency": "VND",
      "images": ["string"],
      "rating": number,
      "reviewCount": number,
      "soldCount": number,
      "stock": number,
      "categoryId": "string",
      "categoryName": "string",
      "shopId": "string",
      "shopName": "string",
      "condition": "string",
      "createdAt": "timestamp"
    }
  ],
  "nextCursor": "string?"
}
```

---

### 9. Search Products
**GET** `/products/search`

Search products by query string.

**Query Parameters**:
- `q` (string, required) - Search query
- `limit` (int, default: 20) - Number of items per page
- `cursor` (string, optional) - Pagination cursor
- `min_price` (number, optional) - Minimum price filter
- `max_price` (number, optional) - Maximum price filter
- `rating` (number, optional) - Minimum rating filter
- `condition` (string, optional) - Product condition filter
- `sort_by` (string, optional) - Sort option

**Response** (200): Same as Get Products

---

### 10. Get Product Detail
**GET** `/products/{id}`

Get detailed information about a specific product.

**Path Parameters**:
- `id` (string) - Product ID

**Response** (200):
```json
{
  "data": {
    "id": "string",
    "name": "string",
    "description": "string",
    "price": number,
    "originalPrice": number,
    "currency": "VND",
    "images": ["string"],
    "rating": number,
    "reviewCount": number,
    "soldCount": number,
    "stock": number,
    "categoryId": "string",
    "categoryName": "string",
    "shopId": "string",
    "shopName": "string",
    "shopAvatar": "string",
    "shopRating": number,
    "condition": "string",
    "specifications": {
      "key": "value"
    },
    "createdAt": "timestamp"
  }
}
```

**Errors**:
- `404 Not Found` - Product not found

---

### 11. Get Product Variants
**GET** `/products/{id}/variants`

Get available variants for a product.

**Path Parameters**:
- `id` (string) - Product ID

**Response** (200):
```json
{
  "data": [
    {
      "id": "string",
      "name": "string",
      "price": number,
      "stock": number,
      "sku": "string",
      "attributes": {
        "color": "string",
        "size": "string"
      }
    }
  ]
}
```

---

### 12. Get Product Reviews
**GET** `/products/{id}/reviews`

Get reviews for a specific product.

**Path Parameters**:
- `id` (string) - Product ID

**Query Parameters**:
- `limit` (int, default: 20) - Number of items per page
- `cursor` (string, optional) - Pagination cursor
- `rating` (int, optional) - Filter by rating (1-5)

**Response** (200):
```json
{
  "data": [
    {
      "id": "string",
      "userId": "string",
      "userName": "string",
      "userAvatar": "string",
      "rating": number,
      "comment": "string",
      "images": ["string"],
      "createdAt": "timestamp",
      "variantInfo": "string?"
    }
  ],
  "nextCursor": "string?"
}
```

---

### 13. Get Categories
**GET** `/categories`

Get all product categories.

**Response** (200):
```json
{
  "data": [
    {
      "id": "string",
      "name": "string",
      "icon": "string",
      "parentId": "string?",
      "level": number,
      "order": number
    }
  ]
}
```

---

### 14. Get Search Suggestions
**GET** `/products/search/autocomplete`

Get autocomplete suggestions for search.

**Query Parameters**:
- `q` (string, required) - Search query
- `limit` (int, default: 5) - Number of suggestions

**Response** (200):
```json
{
  "data": ["string", "string", "string"]
}
```

---

## Cart APIs

### 15. Get Cart
**GET** `/cart`

Get current user's cart.

**Headers**: Requires authentication

**Response** (200):
```json
{
  "items": [
    {
      "id": "string",
      "productId": "string",
      "variantId": "string?",
      "quantity": number,
      "addedAt": "timestamp"
    }
  ]
}
```

---

### 16. Add to Cart
**POST** `/cart`

Add item to cart.

**Headers**: Requires authentication

**Request Body**:
```json
{
  "productId": "string",
  "variantId": "string?",
  "quantity": number
}
```

**Response** (200):
```json
{
  "id": "string",
  "productId": "string",
  "variantId": "string?",
  "quantity": number,
  "addedAt": "timestamp"
}
```

---

### 17. Update Cart Item Quantity
**PATCH** `/cart/items/{cartItemId}`

Update quantity of a cart item.

**Headers**: Requires authentication

**Path Parameters**:
- `cartItemId` (string) - Cart item ID

**Request Body**:
```json
{
  "quantity": number
}
```

**Response** (200): Same as Add to Cart

---

### 18. Remove Cart Item
**DELETE** `/cart/items/{cartItemId}`

Remove item from cart.

**Headers**: Requires authentication

**Path Parameters**:
- `cartItemId` (string) - Cart item ID

**Response** (200): No content

---

### 19. Sync Cart
**POST** `/cart/sync`

Sync local cart items with server.

**Headers**: Requires authentication

**Request Body**:
```json
{
  "items": [
    {
      "id": "string",
      "productId": "string",
      "variantId": "string?",
      "quantity": number,
      "addedAt": "timestamp"
    }
  ]
}
```

**Response** (200):
```json
{
  "items": [
    {
      "id": "string",
      "productId": "string",
      "variantId": "string?",
      "quantity": number,
      "addedAt": "timestamp"
    }
  ]
}
```

---

## Order APIs

### 20. Create Order
**POST** `/orders`

Create order from cart items.

**Headers**: Requires authentication

**Request Body**:
```json
{
  "userId": "string",
  "items": [
    {
      "productId": "string",
      "variantId": "string?",
      "quantity": number
    }
  ],
  "addressId": "string",
  "paymentMethod": "string",
  "voucherCode": "string?",
  "notes": "string?"
}
```

**Response** (200):
```json
{
  "orders": [
    {
      "id": "string",
      "orderNumber": "string",
      "userId": "string",
      "shopId": "string",
      "shopName": "string",
      "items": [
        {
          "productId": "string",
          "productName": "string",
          "productImage": "string",
          "variantId": "string?",
          "variantName": "string?",
          "quantity": number,
          "price": number
        }
      ],
      "subtotal": number,
      "shippingFee": number,
      "discount": number,
      "total": number,
      "status": "string",
      "paymentMethod": "string",
      "shippingAddress": {
        "recipientName": "string",
        "phoneNumber": "string",
        "streetAddress": "string",
        "ward": "string",
        "district": "string",
        "city": "string"
      },
      "notes": "string?",
      "createdAt": "timestamp"
    }
  ]
}
```

---

### 21. Get Orders
**GET** `/orders`

Get user's orders with filters.

**Headers**: Requires authentication

**Query Parameters**:
- `userId` (string) - User ID (automatically filled from token)
- `status` (string, optional) - Filter by order status
- `limit` (int, optional) - Number of items per page
- `cursor` (string, optional) - Pagination cursor

**Response** (200):
```json
{
  "orders": [
    {
      "id": "string",
      "orderNumber": "string",
      "shopId": "string",
      "shopName": "string",
      "items": [...],
      "subtotal": number,
      "shippingFee": number,
      "discount": number,
      "total": number,
      "status": "string",
      "paymentMethod": "string",
      "createdAt": "timestamp"
    }
  ],
  "nextCursor": "string?"
}
```

---

### 22. Get Order Detail
**GET** `/orders/{orderId}`

Get detailed information about a specific order.

**Headers**: Requires authentication

**Path Parameters**:
- `orderId` (string) - Order ID

**Response** (200): Same as single order in Create Order response

**Errors**:
- `404 Not Found` - Order not found

---

### 23. Cancel Order
**POST** `/orders/{orderId}/cancel`

Cancel an order.

**Headers**: Requires authentication

**Path Parameters**:
- `orderId` (string) - Order ID

**Request Body**:
```json
{
  "reason": "string",
  "notes": "string?"
}
```

**Response** (200): Same as single order

---

### 24. Validate Voucher
**POST** `/vouchers/validate`

Validate voucher code for order.

**Headers**: Requires authentication

**Request Body**:
```json
{
  "code": "string",
  "shopId": "string",
  "orderSubtotal": number
}
```

**Response** (200):
```json
{
  "id": "string",
  "code": "string",
  "discountType": "string",
  "discountValue": number,
  "minOrderValue": number,
  "maxDiscount": number?,
  "validFrom": "timestamp",
  "validUntil": "timestamp",
  "isValid": true
}
```

**Errors**:
- `400 Bad Request` - Voucher invalid or expired

---

### 25. Get Available Vouchers
**GET** `/vouchers/available`

Get available vouchers for shop and order.

**Headers**: Requires authentication

**Query Parameters**:
- `shopId` (string) - Shop ID
- `orderSubtotal` (number) - Order subtotal amount

**Response** (200):
```json
{
  "vouchers": [
    {
      "id": "string",
      "code": "string",
      "discountType": "string",
      "discountValue": number,
      "minOrderValue": number,
      "maxDiscount": number?,
      "validFrom": "timestamp",
      "validUntil": "timestamp"
    }
  ]
}
```

---

## Profile APIs

### 26. Get User Profile
**GET** `/profile`

Get current user's profile.

**Headers**: Requires authentication

**Response** (200):
```json
{
  "id": "string",
  "phoneNumber": "string",
  "fullName": "string",
  "email": "string?",
  "avatarUrl": "string?",
  "isPhoneVerified": true,
  "createdAt": "timestamp"
}
```

**Errors**:
- `401 Unauthorized` - Not authenticated

---

### 27. Update Profile
**PUT** `/profile`

Update user profile information.

**Headers**: Requires authentication

**Request Body**:
```json
{
  "fullName": "string?",
  "email": "string?",
  "avatarUrl": "string?"
}
```

**Response** (200): Same as Get User Profile

**Errors**:
- `400 Bad Request` - Validation failed

---

### 28. Get Addresses
**GET** `/profile/addresses`

Get user's saved addresses.

**Headers**: Requires authentication

**Response** (200):
```json
[
  {
    "id": "string",
    "recipientName": "string",
    "phoneNumber": "string",
    "streetAddress": "string",
    "ward": "string",
    "district": "string",
    "city": "string",
    "isDefault": boolean
  }
]
```

---

### 29. Add Address
**POST** `/profile/addresses`

Add new delivery address.

**Headers**: Requires authentication

**Request Body**:
```json
{
  "recipientName": "string",
  "phoneNumber": "string",
  "streetAddress": "string",
  "ward": "string",
  "district": "string",
  "city": "string",
  "isDefault": boolean
}
```

**Response** (200): Same as address object in Get Addresses

**Errors**:
- `400 Bad Request` - Validation failed

---

### 30. Update Address
**PUT** `/profile/addresses/{addressId}`

Update existing address.

**Headers**: Requires authentication

**Path Parameters**:
- `addressId` (string) - Address ID

**Request Body**:
```json
{
  "recipientName": "string?",
  "phoneNumber": "string?",
  "streetAddress": "string?",
  "ward": "string?",
  "district": "string?",
  "city": "string?",
  "isDefault": "boolean?"
}
```

**Response** (200): Same as address object

**Errors**:
- `404 Not Found` - Address not found

---

### 31. Delete Address
**DELETE** `/profile/addresses/{addressId}`

Delete an address.

**Headers**: Requires authentication

**Path Parameters**:
- `addressId` (string) - Address ID

**Response** (200): No content

**Errors**:
- `404 Not Found` - Address not found
- `400 Bad Request` - Cannot delete default address

---

### 32. Set Default Address
**POST** `/profile/addresses/{addressId}/set-default`

Set an address as default.

**Headers**: Requires authentication

**Path Parameters**:
- `addressId` (string) - Address ID

**Response** (200): Same as address object

**Errors**:
- `404 Not Found` - Address not found

---

## Error Response Format

All API errors follow a consistent format:

```json
{
  "error": {
    "code": "string",
    "message": "string",
    "details": "object?"
  }
}
```

Common HTTP Status Codes:
- `200 OK` - Request succeeded
- `201 Created` - Resource created successfully
- `400 Bad Request` - Invalid request parameters
- `401 Unauthorized` - Authentication required or failed
- `403 Forbidden` - Access denied
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists
- `422 Unprocessable Entity` - Validation error
- `500 Internal Server Error` - Server error

---

## Authentication Flow

1. **Register**: POST `/auth/register` → Get user object
2. **Verify OTP**: POST `/auth/verify-otp` → Get tokens
3. **Login**: POST `/auth/login` → Get user + tokens
4. **Use Token**: Include `Authorization: Bearer {accessToken}` in headers
5. **Refresh**: When token expires, POST `/auth/refresh` → Get new tokens
6. **Logout**: POST `/auth/logout` → Invalidate refresh token

---

## Notes

- All timestamps are in ISO 8601 format
- All prices are in VND (Vietnamese Dong)
- Pagination uses cursor-based pagination for better performance
- Maximum page size is 100 items
- Default page size is 20 items
- All authenticated endpoints use JWT tokens
- Tokens are stored securely in device's secure storage
- Access tokens expire after 15 minutes
- Refresh tokens expire after 7 days
