"""
Order schemas for requests and responses
"""
from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional
from uuid import UUID
from datetime import datetime
from decimal import Decimal
from enum import Enum


class OrderStatus(str, Enum):
    """Order status enum"""
    PENDING = "pending"
    CONFIRMED = "confirmed"
    PACKED = "packed"
    SHIPPING = "shipping"
    DELIVERED = "delivered"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class PaymentMethod(str, Enum):
    """Payment method enum"""
    COD = "cod"
    BANK_TRANSFER = "bank_transfer"
    E_WALLET = "e_wallet"


class PaymentStatus(str, Enum):
    """Payment status enum"""
    PENDING = "pending"
    PAID = "paid"
    FAILED = "failed"
    REFUNDED = "refunded"


# ============================================================================
# Request Schemas
# ============================================================================

class OrderItemCreate(BaseModel):
    """Schema for creating an order item"""
    product_id: UUID
    variant_id: Optional[UUID] = None
    quantity: int = Field(ge=1, description="Must be at least 1")


class OrderCreate(BaseModel):
    """Schema for creating orders"""
    items: List[OrderItemCreate] = Field(..., min_length=1, description="At least one item required")
    address_id: UUID
    payment_method: PaymentMethod
    voucher_code: Optional[str] = None
    notes: Optional[str] = None


class OrderCancelRequest(BaseModel):
    """Schema for cancelling an order"""
    reason: str = Field(..., min_length=10, max_length=500)


class OrderStatusUpdate(BaseModel):
    """Schema for updating order status (seller)"""
    status: OrderStatus


# ============================================================================
# Response Schemas
# ============================================================================

class ProductSnapshotResponse(BaseModel):
    """Product snapshot in order"""
    id: UUID
    title: str
    base_price: Decimal
    images: List[str]
    condition: str
    
    model_config = ConfigDict(from_attributes=True)


class VariantSnapshotResponse(BaseModel):
    """Variant snapshot in order"""
    id: UUID
    name: str
    sku: str
    price: Decimal
    attributes: dict
    
    model_config = ConfigDict(from_attributes=True)


class OrderItemResponse(BaseModel):
    """Order item response"""
    id: UUID
    order_id: UUID
    product_id: Optional[UUID]
    variant_id: Optional[UUID]
    product_snapshot: dict
    variant_snapshot: Optional[dict]
    quantity: int
    unit_price: Decimal
    subtotal: Decimal
    currency: str
    
    model_config = ConfigDict(from_attributes=True)


class ShippingAddressResponse(BaseModel):
    """Shipping address snapshot"""
    full_name: str
    phone_number: str
    address_line1: str
    address_line2: Optional[str]
    ward: str
    district: str
    city: str
    postal_code: Optional[str]


class OrderResponse(BaseModel):
    """Order response"""
    id: UUID
    order_number: str
    buyer_id: UUID
    shop_id: UUID
    address_id: Optional[UUID]
    shipping_address: dict
    status: OrderStatus
    payment_method: PaymentMethod
    payment_status: PaymentStatus
    subtotal: Decimal
    shipping_fee: Decimal
    discount: Decimal
    total: Decimal
    currency: str
    voucher_code: Optional[str]
    notes: Optional[str]
    cancellation_reason: Optional[str]
    created_at: datetime
    updated_at: datetime
    completed_at: Optional[datetime]
    items: List[OrderItemResponse] = []
    
    model_config = ConfigDict(from_attributes=True)


class OrderSummaryResponse(BaseModel):
    """Order summary for list views"""
    id: UUID
    order_number: str
    shop_id: UUID
    shop_name: str
    status: OrderStatus
    payment_method: PaymentMethod
    payment_status: PaymentStatus
    total: Decimal
    currency: str
    item_count: int
    created_at: datetime
    
    model_config = ConfigDict(from_attributes=True)


class OrderListResponse(BaseModel):
    """Paginated order list response"""
    orders: List[OrderSummaryResponse]
    total: int
    page: int
    page_size: int
    total_pages: int


class CheckoutSummaryResponse(BaseModel):
    """Checkout summary before order creation"""
    items: List[OrderItemResponse]
    subtotal: Decimal
    shipping_fee: Decimal
    discount: Decimal
    total: Decimal
    currency: str
