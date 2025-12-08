"""
Product schemas for request/response validation
"""
from typing import Optional, List, Dict, Any
from uuid import UUID
from decimal import Decimal
from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from app.models.product import ProductCondition


# ProductVariant Schemas
class ProductVariantBase(BaseModel):
    """Base product variant schema"""
    name: str = Field(..., min_length=1, max_length=255)
    attributes: Optional[Dict[str, Any]] = Field(default_factory=dict)
    sku: Optional[str] = Field(None, max_length=100)
    price: Decimal = Field(..., gt=0, description="Variant price")
    stock: int = Field(default=0, ge=0, description="Variant stock quantity")
    is_active: bool = True


class ProductVariantCreate(ProductVariantBase):
    """Schema for creating a product variant"""
    pass


class ProductVariantUpdate(BaseModel):
    """Schema for updating a product variant"""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    attributes: Optional[Dict[str, Any]] = None
    sku: Optional[str] = Field(None, max_length=100)
    price: Optional[Decimal] = Field(None, gt=0)
    stock: Optional[int] = Field(None, ge=0)
    is_active: Optional[bool] = None


class ProductVariantResponse(ProductVariantBase):
    """Schema for product variant response"""
    id: UUID
    product_id: UUID
    created_at: datetime
    updated_at: datetime
    
    model_config = {"from_attributes": True}


# Product Schemas
class ProductBase(BaseModel):
    """Base product schema"""
    title: str = Field(..., min_length=3, max_length=500, description="Product title")
    description: Optional[str] = Field(None, max_length=10000, description="Product description")
    category_id: Optional[UUID] = Field(None, description="Category ID")
    base_price: Decimal = Field(..., gt=0, description="Base price")
    currency: str = Field(default="VND", max_length=3)
    total_stock: int = Field(default=0, ge=0, description="Total stock quantity")
    images: Optional[List[str]] = Field(default_factory=list, description="Array of image URLs")
    condition: ProductCondition = Field(default=ProductCondition.NEW)
    is_active: bool = True
    
    @field_validator('title')
    @classmethod
    def validate_title(cls, v: str) -> str:
        """Validate and clean product title"""
        if not v.strip():
            raise ValueError("Product title cannot be empty or whitespace")
        return ' '.join(v.split())
    
    @field_validator('images')
    @classmethod
    def validate_images(cls, v: Optional[List[str]]) -> List[str]:
        """Validate image URLs"""
        if v is None:
            return []
        if len(v) > 10:
            raise ValueError("Maximum 10 images allowed")
        return v


class ProductCreate(ProductBase):
    """Schema for creating a product"""
    variants: Optional[List[ProductVariantCreate]] = Field(default_factory=list)


class ProductUpdate(BaseModel):
    """Schema for updating a product"""
    title: Optional[str] = Field(None, min_length=3, max_length=500)
    description: Optional[str] = Field(None, max_length=10000)
    category_id: Optional[UUID] = None
    base_price: Optional[Decimal] = Field(None, gt=0)
    currency: Optional[str] = Field(None, max_length=3)
    total_stock: Optional[int] = Field(None, ge=0)
    images: Optional[List[str]] = None
    condition: Optional[ProductCondition] = None
    is_active: Optional[bool] = None
    
    @field_validator('title')
    @classmethod
    def validate_title(cls, v: Optional[str]) -> Optional[str]:
        """Validate and clean product title"""
        if v is not None:
            if not v.strip():
                raise ValueError("Product title cannot be empty or whitespace")
            return ' '.join(v.split())
        return v
    
    @field_validator('images')
    @classmethod
    def validate_images(cls, v: Optional[List[str]]) -> Optional[List[str]]:
        """Validate image URLs"""
        if v is not None and len(v) > 10:
            raise ValueError("Maximum 10 images allowed")
        return v


class ProductResponse(ProductBase):
    """Schema for product response"""
    id: UUID
    shop_id: UUID
    average_rating: float = 0.0
    total_reviews: int = 0
    sold_count: int = 0
    created_at: datetime
    updated_at: datetime
    variants: List[ProductVariantResponse] = []
    
    model_config = {"from_attributes": True}


class ProductListItem(BaseModel):
    """Schema for product list item (simplified)"""
    id: UUID
    shop_id: UUID
    category_id: Optional[UUID]
    title: str
    base_price: Decimal
    currency: str
    images: List[str] = []
    condition: ProductCondition
    average_rating: float = 0.0
    total_reviews: int = 0
    sold_count: int = 0
    is_active: bool
    created_at: datetime
    
    model_config = {"from_attributes": True}


class ProductListResponse(BaseModel):
    """Schema for paginated product list"""
    products: List[ProductListItem]
    total: int
    page: int
    page_size: int
    total_pages: int
    
    model_config = {"from_attributes": True}


class ProductSearchFilters(BaseModel):
    """Schema for product search filters"""
    category_id: Optional[UUID] = None
    shop_id: Optional[UUID] = None
    min_price: Optional[Decimal] = Field(None, ge=0)
    max_price: Optional[Decimal] = Field(None, ge=0)
    condition: Optional[ProductCondition] = None
    min_rating: Optional[float] = Field(None, ge=0, le=5)
    is_active: bool = True
    sort_by: str = Field(default="created_at", pattern="^(created_at|price|rating|sold_count)$")
    sort_order: str = Field(default="desc", pattern="^(asc|desc)$")
