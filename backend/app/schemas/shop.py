"""
Shop schemas for request/response validation
"""
from typing import Optional
from uuid import UUID
from decimal import Decimal
from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from app.models.shop import ShopStatus


class ShopBase(BaseModel):
    """Base shop schema with common fields"""
    shop_name: str = Field(..., min_length=3, max_length=255, description="Unique shop name")
    description: Optional[str] = Field(None, max_length=2000, description="Shop description")
    business_address: Optional[str] = Field(None, max_length=500, description="Business address")
    shipping_fee: Decimal = Field(default=Decimal("0"), ge=0, description="Default shipping fee")
    free_shipping_threshold: Optional[Decimal] = Field(None, ge=0, description="Free shipping threshold")
    
    @field_validator('shop_name')
    @classmethod
    def validate_shop_name(cls, v: str) -> str:
        """Validate shop name format"""
        if not v.strip():
            raise ValueError("Shop name cannot be empty or whitespace")
        # Remove multiple spaces
        v = ' '.join(v.split())
        return v
    
    @field_validator('shipping_fee', 'free_shipping_threshold')
    @classmethod
    def validate_decimal_places(cls, v: Optional[Decimal]) -> Optional[Decimal]:
        """Validate decimal has at most 2 decimal places"""
        if v is not None:
            if v.as_tuple().exponent < -2:
                raise ValueError("Maximum 2 decimal places allowed")
        return v


class ShopCreate(ShopBase):
    """Schema for creating a shop"""
    pass


class ShopUpdate(BaseModel):
    """Schema for updating a shop (all fields optional)"""
    shop_name: Optional[str] = Field(None, min_length=3, max_length=255)
    description: Optional[str] = Field(None, max_length=2000)
    logo_url: Optional[str] = Field(None, max_length=500)
    cover_image_url: Optional[str] = Field(None, max_length=500)
    business_address: Optional[str] = Field(None, max_length=500)
    shipping_fee: Optional[Decimal] = Field(None, ge=0)
    free_shipping_threshold: Optional[Decimal] = Field(None, ge=0)
    
    @field_validator('shop_name')
    @classmethod
    def validate_shop_name(cls, v: Optional[str]) -> Optional[str]:
        """Validate shop name format"""
        if v is not None:
            if not v.strip():
                raise ValueError("Shop name cannot be empty or whitespace")
            v = ' '.join(v.split())
        return v
    
    @field_validator('shipping_fee', 'free_shipping_threshold')
    @classmethod
    def validate_decimal_places(cls, v: Optional[Decimal]) -> Optional[Decimal]:
        """Validate decimal has at most 2 decimal places"""
        if v is not None:
            if v.as_tuple().exponent < -2:
                raise ValueError("Maximum 2 decimal places allowed")
        return v


class ShopResponse(ShopBase):
    """Schema for shop response"""
    id: UUID
    owner_id: UUID
    logo_url: Optional[str] = None
    cover_image_url: Optional[str] = None
    rating: float = 0.0
    total_ratings: int = 0
    follower_count: int = 0
    status: ShopStatus
    created_at: datetime
    updated_at: datetime
    
    model_config = {"from_attributes": True}


class ShopListResponse(BaseModel):
    """Schema for paginated shop list"""
    shops: list[ShopResponse]
    total: int
    page: int
    page_size: int
    
    model_config = {"from_attributes": True}
