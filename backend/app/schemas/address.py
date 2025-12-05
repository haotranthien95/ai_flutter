"""
Address schemas for request/response validation
"""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field, field_validator
import re


class AddressBase(BaseModel):
    """Base address schema"""
    recipient_name: str = Field(..., min_length=1, max_length=255, description="Recipient's full name")
    phone_number: str = Field(..., description="Recipient's phone number")
    street_address: str = Field(..., min_length=1, description="Street address, house number")
    ward: str = Field(..., min_length=1, max_length=100, description="Ward/Commune")
    district: str = Field(..., min_length=1, max_length=100, description="District")
    city: str = Field(..., min_length=1, max_length=100, description="City/Province")
    
    @field_validator('phone_number')
    @classmethod
    def validate_phone_number(cls, v: str) -> str:
        """Validate Vietnamese phone number format"""
        # Remove spaces and dashes
        phone = v.replace(' ', '').replace('-', '')
        
        # Check if it starts with +84 or 0
        if phone.startswith('+84'):
            phone = '0' + phone[3:]
        
        # Vietnamese phone numbers should be 10 digits starting with 0
        if not re.match(r'^0\d{9}$', phone):
            raise ValueError('Phone number must be a valid Vietnamese phone number (10 digits starting with 0)')
        
        return phone


class AddressCreate(AddressBase):
    """Schema for creating a new address"""
    is_default: bool = Field(default=False, description="Set as default address")


class AddressUpdate(BaseModel):
    """Schema for updating an address (all fields optional)"""
    recipient_name: Optional[str] = Field(None, min_length=1, max_length=255)
    phone_number: Optional[str] = None
    street_address: Optional[str] = Field(None, min_length=1)
    ward: Optional[str] = Field(None, min_length=1, max_length=100)
    district: Optional[str] = Field(None, min_length=1, max_length=100)
    city: Optional[str] = Field(None, min_length=1, max_length=100)
    is_default: Optional[bool] = None
    
    @field_validator('phone_number')
    @classmethod
    def validate_phone_number(cls, v: Optional[str]) -> Optional[str]:
        """Validate Vietnamese phone number format if provided"""
        if v is None:
            return v
        
        # Remove spaces and dashes
        phone = v.replace(' ', '').replace('-', '')
        
        # Check if it starts with +84 or 0
        if phone.startswith('+84'):
            phone = '0' + phone[3:]
        
        # Vietnamese phone numbers should be 10 digits starting with 0
        if not re.match(r'^0\d{9}$', phone):
            raise ValueError('Phone number must be a valid Vietnamese phone number (10 digits starting with 0)')
        
        return phone


class AddressResponse(AddressBase):
    """Schema for address response"""
    id: UUID
    user_id: UUID
    is_default: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True
    
    @property
    def full_address(self) -> str:
        """Get formatted full address"""
        return f"{self.street_address}, {self.ward}, {self.district}, {self.city}"


class AddressListResponse(BaseModel):
    """Schema for list of addresses response"""
    addresses: list[AddressResponse]
    total: int
