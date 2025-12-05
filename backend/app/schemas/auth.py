"""
Authentication schemas for request/response validation
"""
from typing import Optional

from pydantic import BaseModel, EmailStr, Field


# Request Schemas
class RegisterRequest(BaseModel):
    """Schema for user registration"""
    phone_number: str = Field(
        ...,
        min_length=10,
        max_length=20,
        description="User's phone number (Vietnamese format)"
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
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "phone_number": "+84912345678",
                "password": "SecurePass123!",
                "full_name": "Nguyen Van A",
                "email": "user@example.com"
            }
        }
    }


class OTPVerifyRequest(BaseModel):
    """Schema for OTP verification"""
    phone_number: str = Field(
        ...,
        description="User's phone number"
    )
    otp: str = Field(
        ...,
        min_length=6,
        max_length=6,
        description="6-digit OTP code"
    )
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "phone_number": "+84912345678",
                "otp": "123456"
            }
        }
    }


class LoginRequest(BaseModel):
    """Schema for user login"""
    phone_number: str = Field(
        ...,
        description="User's phone number"
    )
    password: str = Field(
        ...,
        description="User's password"
    )
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "phone_number": "+84912345678",
                "password": "SecurePass123!"
            }
        }
    }


class RefreshTokenRequest(BaseModel):
    """Schema for token refresh"""
    refresh_token: str = Field(
        ...,
        description="Refresh token"
    )
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
            }
        }
    }


class ForgotPasswordRequest(BaseModel):
    """Schema for forgot password request"""
    phone_number: str = Field(
        ...,
        description="User's phone number"
    )
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "phone_number": "+84912345678"
            }
        }
    }


class PasswordResetRequest(BaseModel):
    """Schema for password reset with OTP"""
    phone_number: str = Field(
        ...,
        description="User's phone number"
    )
    otp: str = Field(
        ...,
        min_length=6,
        max_length=6,
        description="6-digit OTP code"
    )
    new_password: str = Field(
        ...,
        min_length=8,
        max_length=100,
        description="New password (min 8 characters)"
    )
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "phone_number": "+84912345678",
                "otp": "123456",
                "new_password": "NewSecurePass123!"
            }
        }
    }


# Response Schemas
class TokenResponse(BaseModel):
    """Schema for token response"""
    access_token: str = Field(
        ...,
        description="JWT access token (expires in 15 minutes)"
    )
    refresh_token: str = Field(
        ...,
        description="JWT refresh token (expires in 7 days)"
    )
    token_type: str = Field(
        default="bearer",
        description="Token type"
    )
    expires_in: int = Field(
        ...,
        description="Access token expiration time in seconds"
    )
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "bearer",
                "expires_in": 900
            }
        }
    }


class MessageResponse(BaseModel):
    """Generic message response"""
    message: str
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "message": "Operation completed successfully"
            }
        }
    }
