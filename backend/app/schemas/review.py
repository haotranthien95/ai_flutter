"""
Review schemas for request/response validation
"""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


# Request Schemas
class ReviewCreate(BaseModel):
    """Schema for creating a new review"""
    product_id: UUID = Field(..., description="Product ID")
    order_id: UUID = Field(..., description="Order ID containing the product")
    rating: int = Field(..., ge=1, le=5, description="Rating from 1 to 5 stars")
    content: Optional[str] = Field(None, max_length=2000, description="Review content")
    images: Optional[list[str]] = Field(None, max_items=5, description="List of image URLs (max 5)")
    
    @field_validator('images')
    @classmethod
    def validate_images(cls, v):
        """Validate image URLs"""
        if v is not None and len(v) > 5:
            raise ValueError('Maximum 5 images allowed')
        return v


class ReviewUpdate(BaseModel):
    """Schema for updating a review"""
    rating: Optional[int] = Field(None, ge=1, le=5, description="Updated rating")
    content: Optional[str] = Field(None, max_length=2000, description="Updated content")
    images: Optional[list[str]] = Field(None, max_items=5, description="Updated image URLs")
    
    @field_validator('images')
    @classmethod
    def validate_images(cls, v):
        """Validate image URLs"""
        if v is not None and len(v) > 5:
            raise ValueError('Maximum 5 images allowed')
        return v


# Response Schemas
class ReviewUserInfo(BaseModel):
    """User info in review response"""
    id: UUID
    username: str
    full_name: str
    avatar_url: Optional[str]
    
    class Config:
        from_attributes = True


class ReviewResponse(BaseModel):
    """Schema for review response"""
    id: UUID
    product_id: UUID
    user_id: UUID
    order_id: Optional[UUID]
    rating: int
    content: Optional[str]
    images: Optional[list[str]]
    is_verified_purchase: bool
    is_visible: bool
    created_at: datetime
    updated_at: datetime
    user: Optional[ReviewUserInfo] = None
    
    class Config:
        from_attributes = True


class ReviewListResponse(BaseModel):
    """Schema for paginated review list"""
    items: list[ReviewResponse]
    total: int
    page: int
    page_size: int
    total_pages: int
    average_rating: Optional[float] = None
    rating_distribution: Optional[dict[int, int]] = None  # {1: count, 2: count, ...}


class ReviewStats(BaseModel):
    """Schema for review statistics"""
    total_reviews: int
    average_rating: float
    rating_distribution: dict[int, int]  # {1: count, 2: count, 3: count, 4: count, 5: count}
