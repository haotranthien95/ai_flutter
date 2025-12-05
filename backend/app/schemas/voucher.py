"""
Voucher schemas for request/response validation
"""
from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator

from app.models.voucher import VoucherType


# Request Schemas
class VoucherCreate(BaseModel):
    """Schema for creating a new voucher"""
    code: str = Field(..., min_length=3, max_length=50, description="Unique voucher code")
    title: str = Field(..., min_length=3, max_length=255, description="Voucher title")
    description: Optional[str] = Field(None, description="Voucher description")
    type: VoucherType = Field(..., description="Discount type")
    value: Decimal = Field(..., gt=0, description="Discount value (percentage 0-100 or fixed amount)")
    min_order_value: Optional[Decimal] = Field(None, ge=0, description="Minimum order value required")
    max_discount: Optional[Decimal] = Field(None, gt=0, description="Maximum discount for percentage type")
    usage_limit: Optional[int] = Field(None, gt=0, description="Total usage limit (null for unlimited)")
    start_date: datetime = Field(..., description="Voucher validity start date")
    end_date: datetime = Field(..., description="Voucher validity end date")
    is_active: bool = Field(True, description="Voucher active status")
    
    @field_validator('value')
    @classmethod
    def validate_value(cls, v, info):
        """Validate discount value based on type"""
        voucher_type = info.data.get('type')
        if voucher_type == VoucherType.PERCENTAGE:
            if v < 0 or v > 100:
                raise ValueError('Percentage value must be between 0 and 100')
        return v
    
    @field_validator('end_date')
    @classmethod
    def validate_dates(cls, v, info):
        """Validate end_date is after start_date"""
        start_date = info.data.get('start_date')
        if start_date and v <= start_date:
            raise ValueError('end_date must be after start_date')
        return v
    
    @field_validator('code')
    @classmethod
    def validate_code(cls, v):
        """Validate voucher code format"""
        if not v.replace('_', '').replace('-', '').isalnum():
            raise ValueError('Code must contain only alphanumeric characters, hyphens, and underscores')
        return v.upper()  # Store codes in uppercase for consistency


class VoucherUpdate(BaseModel):
    """Schema for updating a voucher"""
    title: Optional[str] = Field(None, min_length=3, max_length=255)
    description: Optional[str] = None
    value: Optional[Decimal] = Field(None, gt=0)
    min_order_value: Optional[Decimal] = Field(None, ge=0)
    max_discount: Optional[Decimal] = Field(None, gt=0)
    usage_limit: Optional[int] = Field(None, gt=0)
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    is_active: Optional[bool] = None


class VoucherValidateRequest(BaseModel):
    """Schema for validating a voucher for an order"""
    code: str = Field(..., description="Voucher code to validate")
    shop_id: UUID = Field(..., description="Shop ID")
    subtotal: Decimal = Field(..., gt=0, description="Order subtotal")


# Response Schemas
class VoucherResponse(BaseModel):
    """Schema for voucher response"""
    id: UUID
    shop_id: UUID
    code: str
    title: str
    description: Optional[str]
    type: VoucherType
    value: Decimal
    min_order_value: Optional[Decimal]
    max_discount: Optional[Decimal]
    usage_limit: Optional[int]
    usage_count: int
    start_date: datetime
    end_date: datetime
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class VoucherListResponse(BaseModel):
    """Schema for paginated voucher list"""
    items: list[VoucherResponse]
    total: int
    page: int
    page_size: int
    total_pages: int


class VoucherValidateResponse(BaseModel):
    """Schema for voucher validation response"""
    valid: bool
    message: str
    discount_amount: Optional[Decimal] = None
    voucher: Optional[VoucherResponse] = None


class VoucherAvailableResponse(BaseModel):
    """Schema for available vouchers for buyer"""
    available_vouchers: list[VoucherResponse]
    total: int
