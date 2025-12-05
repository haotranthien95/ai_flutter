"""
User schemas for request/response validation
"""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.models.user import UserRole


# Request Schemas
class UserCreate(BaseModel):
    """Schema for creating a new user"""
    phone_number: str = Field(
        ...,
        min_length=10,
        max_length=20,
        description="User's phone number (Vietnamese format: +84XXXXXXXXX)"
    )
    password: str = Field(
        ...,
        min_length=8,
        max_length=100,
        description="User's password (min 8 characters)"
    )
    full_name: str = Field(
        ...,
        min_length=2,
        max_length=255,
        description="User's full name"
    )
    email: Optional[EmailStr] = Field(
        None,
        description="User's email address (optional)"
    )
    
    @field_validator('phone_number')
    @classmethod
    def validate_phone_number(cls, v: str) -> str:
        """Validate Vietnamese phone number format"""
        # Remove spaces and dashes
        v = v.replace(' ', '').replace('-', '')
        
        # Check if it starts with +84 or 0
        if not (v.startswith('+84') or v.startswith('84') or v.startswith('0')):
            raise ValueError('Phone number must be in Vietnamese format')
        
        # Normalize to +84 format
        if v.startswith('0'):
            v = '+84' + v[1:]
        elif v.startswith('84'):
            v = '+' + v
        
        return v


class UserUpdate(BaseModel):
    """Schema for updating user profile"""
    full_name: Optional[str] = Field(
        None,
        min_length=2,
        max_length=255,
        description="User's full name"
    )
    email: Optional[EmailStr] = Field(
        None,
        description="User's email address"
    )
    avatar_url: Optional[str] = Field(
        None,
        max_length=500,
        description="URL to user's avatar image"
    )


# Response Schemas
class UserResponse(BaseModel):
    """Schema for user response"""
    id: UUID
    phone_number: str
    email: Optional[str] = None
    full_name: str
    avatar_url: Optional[str] = None
    role: UserRole
    is_verified: bool
    is_suspended: bool
    created_at: datetime
    updated_at: datetime
    
    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "id": "550e8400-e29b-41d4-a716-446655440000",
                "phone_number": "+84912345678",
                "email": "user@example.com",
                "full_name": "Nguyen Van A",
                "avatar_url": "https://example.com/avatar.jpg",
                "role": "BUYER",
                "is_verified": True,
                "is_suspended": False,
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-01-01T00:00:00Z"
            }
        }
    }


class UserListResponse(BaseModel):
    """Schema for paginated user list response"""
    users: list[UserResponse]
    total: int
    page: int
    page_size: int
    has_next: bool
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "users": [],
                "total": 100,
                "page": 1,
                "page_size": 20,
                "has_next": True
            }
        }
    }
