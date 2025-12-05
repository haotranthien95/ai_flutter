"""
Authentication API endpoints
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.auth import (
    RegisterRequest,
    OTPVerifyRequest,
    LoginRequest,
    RefreshTokenRequest,
    ForgotPasswordRequest,
    PasswordResetRequest,
    TokenResponse,
    MessageResponse
)
from app.schemas.user import UserResponse
from app.services.auth import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/register",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
    description="Register a new user with phone number and password. An OTP will be sent for verification."
)
async def register(
    request: RegisterRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Register a new user
    
    - **phone_number**: Vietnamese phone number (+84XXXXXXXXX)
    - **password**: Minimum 8 characters
    - **full_name**: User's full name
    - **email**: Optional email address
    
    Returns the created user. An OTP will be sent to the phone number for verification.
    """
    auth_service = AuthService(db)
    return await auth_service.register_user(
        phone_number=request.phone_number,
        password=request.password,
        full_name=request.full_name,
        email=request.email
    )


@router.post(
    "/verify-otp",
    response_model=TokenResponse,
    summary="Verify OTP and get tokens",
    description="Verify OTP sent during registration and receive access/refresh tokens"
)
async def verify_otp(
    request: OTPVerifyRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Verify OTP and complete registration
    
    - **phone_number**: Phone number that received the OTP
    - **otp**: 6-digit OTP code
    
    Returns access and refresh tokens upon successful verification.
    """
    auth_service = AuthService(db)
    return await auth_service.verify_otp(
        phone_number=request.phone_number,
        otp=request.otp
    )


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Login with credentials",
    description="Authenticate with phone number and password"
)
async def login(
    request: LoginRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Login with phone number and password
    
    - **phone_number**: Registered phone number
    - **password**: User's password
    
    Returns access and refresh tokens upon successful authentication.
    """
    auth_service = AuthService(db)
    return await auth_service.login(
        phone_number=request.phone_number,
        password=request.password
    )


@router.post(
    "/refresh",
    response_model=TokenResponse,
    summary="Refresh access token",
    description="Get new access token using refresh token"
)
async def refresh_token(
    request: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Refresh access token
    
    - **refresh_token**: Valid refresh token
    
    Returns new access and refresh tokens.
    """
    auth_service = AuthService(db)
    return await auth_service.refresh_token(request.refresh_token)


@router.post(
    "/forgot-password",
    response_model=MessageResponse,
    summary="Request password reset",
    description="Send OTP for password reset"
)
async def forgot_password(
    request: ForgotPasswordRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Request password reset
    
    - **phone_number**: Registered phone number
    
    Sends an OTP to the phone number for password reset.
    """
    auth_service = AuthService(db)
    await auth_service.forgot_password(request.phone_number)
    return MessageResponse(
        message="OTP sent to your phone number. Please check your messages."
    )


@router.post(
    "/reset-password",
    response_model=MessageResponse,
    summary="Reset password with OTP",
    description="Reset password using OTP verification"
)
async def reset_password(
    request: PasswordResetRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Reset password with OTP
    
    - **phone_number**: Registered phone number
    - **otp**: 6-digit OTP code received via SMS
    - **new_password**: New password (min 8 characters)
    
    Resets the password after OTP verification.
    """
    auth_service = AuthService(db)
    await auth_service.reset_password(
        phone_number=request.phone_number,
        otp=request.otp,
        new_password=request.new_password
    )
    return MessageResponse(
        message="Password reset successfully. You can now login with your new password."
    )


@router.post(
    "/resend-otp",
    response_model=MessageResponse,
    summary="Resend OTP",
    description="Resend OTP for verification"
)
async def resend_otp(
    request: ForgotPasswordRequest,  # Reuse same schema (just phone_number)
    db: AsyncSession = Depends(get_db)
):
    """
    Resend OTP
    
    - **phone_number**: Registered phone number
    
    Sends a new OTP to the phone number.
    """
    auth_service = AuthService(db)
    await auth_service.resend_otp(request.phone_number)
    return MessageResponse(
        message="New OTP sent to your phone number. Please check your messages."
    )


@router.post(
    "/logout",
    response_model=MessageResponse,
    summary="Logout (placeholder)",
    description="Logout endpoint (token invalidation handled client-side)"
)
async def logout():
    """
    Logout
    
    In a stateless JWT system, logout is handled client-side by deleting the tokens.
    This endpoint exists for consistency and can be extended to implement token blacklisting.
    """
    return MessageResponse(
        message="Logged out successfully. Please delete your tokens."
    )
