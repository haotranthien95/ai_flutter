"""
Cart schemas for request/response validation
"""
from typing import List, Optional, Dict
from uuid import UUID
from decimal import Decimal
from datetime import datetime

from pydantic import BaseModel, Field, field_validator


# CartItem Schemas

class CartItemCreate(BaseModel):
    """Schema for adding item to cart"""
    product_id: UUID = Field(..., description="Product ID")
    variant_id: Optional[UUID] = Field(None, description="Product variant ID (optional)")
    quantity: int = Field(default=1, ge=1, le=999, description="Quantity to add")


class CartItemUpdate(BaseModel):
    """Schema for updating cart item"""
    quantity: int = Field(..., ge=1, le=999, description="New quantity")


class ProductSummary(BaseModel):
    """Simplified product info for cart response"""
    id: UUID
    title: str
    base_price: Decimal
    images: List[str] = []
    is_active: bool
    
    model_config = {"from_attributes": True}


class VariantSummary(BaseModel):
    """Simplified variant info for cart response"""
    id: UUID
    name: str
    price: Decimal
    attributes: Dict[str, str] = {}
    is_active: bool
    
    model_config = {"from_attributes": True}


class CartItemResponse(BaseModel):
    """Schema for cart item in response"""
    id: UUID
    product_id: UUID
    variant_id: Optional[UUID]
    quantity: int
    added_at: datetime
    product: ProductSummary
    variant: Optional[VariantSummary] = None
    
    # Computed fields
    unit_price: Decimal
    total_price: Decimal
    
    model_config = {"from_attributes": True}


class ShopCartGroup(BaseModel):
    """Cart items grouped by shop"""
    shop_id: UUID
    shop_name: str
    items: List[CartItemResponse]
    subtotal: Decimal


class CartResponse(BaseModel):
    """Schema for full cart response"""
    items: List[CartItemResponse]
    shops: List[ShopCartGroup]
    total_items: int
    total_quantity: int
    total_price: Decimal


class CartSyncItem(BaseModel):
    """Schema for syncing a single cart item"""
    product_id: UUID
    variant_id: Optional[UUID] = None
    quantity: int = Field(..., ge=1, le=999)


class CartSyncRequest(BaseModel):
    """Schema for syncing entire cart (for guest → logged in)"""
    items: List[CartSyncItem] = Field(..., max_length=100, description="Cart items to sync")
    
    @field_validator('items')
    @classmethod
    def validate_unique_items(cls, v: List[CartSyncItem]) -> List[CartSyncItem]:
        """Ensure no duplicate product-variant combinations"""
        seen = set()
        for item in v:
            key = (str(item.product_id), str(item.variant_id) if item.variant_id else None)
            if key in seen:
                raise ValueError(f"Duplicate item: product_id={item.product_id}, variant_id={item.variant_id}")
            seen.add(key)
        return v
