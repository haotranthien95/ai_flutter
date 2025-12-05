"""
Category schemas for request/response validation
"""
from typing import Optional, List
from uuid import UUID
from datetime import datetime

from pydantic import BaseModel, Field, field_validator


class CategoryBase(BaseModel):
    """Base category schema"""
    name: str = Field(..., min_length=1, max_length=255, description="Category name")
    icon_url: Optional[str] = Field(None, max_length=500, description="Category icon URL")
    parent_id: Optional[UUID] = Field(None, description="Parent category ID")
    sort_order: int = Field(default=0, description="Sort order within parent")
    is_active: bool = True
    
    @field_validator('name')
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Validate and clean category name"""
        if not v.strip():
            raise ValueError("Category name cannot be empty or whitespace")
        return ' '.join(v.split())


class CategoryCreate(CategoryBase):
    """Schema for creating a category"""
    pass


class CategoryUpdate(BaseModel):
    """Schema for updating a category"""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    icon_url: Optional[str] = Field(None, max_length=500)
    parent_id: Optional[UUID] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None
    
    @field_validator('name')
    @classmethod
    def validate_name(cls, v: Optional[str]) -> Optional[str]:
        """Validate and clean category name"""
        if v is not None:
            if not v.strip():
                raise ValueError("Category name cannot be empty or whitespace")
            return ' '.join(v.split())
        return v


class CategoryResponse(CategoryBase):
    """Schema for category response"""
    id: UUID
    level: int
    created_at: datetime
    updated_at: datetime
    
    model_config = {"from_attributes": True}


class CategoryWithSubcategories(CategoryResponse):
    """Schema for category with subcategories"""
    subcategories: List['CategoryWithSubcategories'] = []
    
    model_config = {"from_attributes": True}


class CategoryTree(BaseModel):
    """Schema for category tree structure"""
    id: UUID
    name: str
    icon_url: Optional[str]
    level: int
    sort_order: int
    is_active: bool
    children: List['CategoryTree'] = []
    
    model_config = {"from_attributes": True}


class CategoryListResponse(BaseModel):
    """Schema for category list"""
    categories: List[CategoryResponse]
    total: int
    
    model_config = {"from_attributes": True}
