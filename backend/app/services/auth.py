"""
Authentication service for user registration, login, and verification
"""
from datetime import timedelta
from typing import Optional
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    verify_token_type
)
from app.models.user import User, UserRole
from app.repositories.user import UserRepository
from app.schemas.auth import TokenResponse
from app.schemas.user import UserCreate, UserResponse
from app.utils.otp import generate_otp, store_otp, verify_otp, send_otp_sms


class AuthService:
    """Service for authentication operations"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repo = UserRepository(db)
    
    async def register_user(
        self,
        phone_number: str,
        password: str,
        full_name: str,
        email: Optional[str] = None
    ) -> UserResponse:
        """
        Register a new user and send OTP for verification
        
        Args:
            phone_number: User's phone number
            password: User's password
            full_name: User's full name
            email: User's email (optional)
            
        Returns:
            Created user response
            
        Raises:
            HTTPException: If phone or email already exists
        """
        # Check if phone number already exists
        if await self.user_repo.phone_exists(phone_number):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Phone number already registered"
            )
        
        # Check if email already exists (if provided)
        if email and await self.user_repo.email_exists(email):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered"
            )
        
        # Hash password
        password_hash = hash_password(password)
        
        # Create user
        user = User(
            phone_number=phone_number,
            password_hash=password_hash,
            full_name=full_name,
            email=email,
            role=UserRole.BUYER,
            is_verified=False,
            is_suspended=False
        )
        
        user = await self.user_repo.create(user)
        await self.db.commit()
        
        # Generate and send OTP
        otp = generate_otp()
        store_otp(phone_number, otp)
        send_otp_sms(phone_number, otp)
        
        return UserResponse.model_validate(user)
    
    async def verify_otp(self, phone_number: str, otp: str) -> TokenResponse:
        """
        Verify OTP and mark user as verified, return tokens
        
        Args:
            phone_number: User's phone number
            otp: OTP code to verify
            
        Returns:
            Access and refresh tokens
            
        Raises:
            HTTPException: If OTP is invalid or user not found
        """
        # Verify OTP
        if not verify_otp(phone_number, otp):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired OTP"
            )
        
        # Get user
        user = await self.user_repo.get_by_phone(phone_number)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Mark as verified
        user.is_verified = True
        await self.user_repo.update(user)
        await self.db.commit()
        
        # Generate tokens
        access_token = create_access_token(str(user.id), user.role.value)
        refresh_token = create_refresh_token(str(user.id))
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        )
    
    async def login(self, phone_number: str, password: str) -> TokenResponse:
        """
        Authenticate user and return tokens
        
        Args:
            phone_number: User's phone number
            password: User's password
            
        Returns:
            Access and refresh tokens
            
        Raises:
            HTTPException: If credentials are invalid
        """
        # Get user
        user = await self.user_repo.get_by_phone(phone_number)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid phone number or password"
            )
        
        # Verify password
        if not verify_password(password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid phone number or password"
            )
        
        # Check if suspended
        if user.is_suspended:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Account is suspended"
            )
        
        # Check if verified
        if not user.is_verified:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Please verify your phone number first"
            )
        
        # Generate tokens
        access_token = create_access_token(str(user.id), user.role.value)
        refresh_token = create_refresh_token(str(user.id))
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        )
    
    async def refresh_token(self, refresh_token: str) -> TokenResponse:
        """
        Refresh access token using refresh token
        
        Args:
            refresh_token: Valid refresh token
            
        Returns:
            New access and refresh tokens
            
        Raises:
            HTTPException: If refresh token is invalid
        """
        try:
            # Verify it's a refresh token
            payload = verify_token_type(refresh_token, "refresh")
            user_id = payload.get("sub")
            
            if not user_id:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid token"
                )
            
            # Get user
            user = await self.user_repo.get_by_id(UUID(user_id))
            if not user:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="User not found"
                )
            
            if user.is_suspended:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Account is suspended"
                )
            
            # Generate new tokens
            new_access_token = create_access_token(str(user.id), user.role.value)
            new_refresh_token = create_refresh_token(str(user.id))
            
            return TokenResponse(
                access_token=new_access_token,
                refresh_token=new_refresh_token,
                token_type="bearer",
                expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
            )
            
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Could not validate token: {str(e)}"
            )
    
    async def forgot_password(self, phone_number: str) -> None:
        """
        Send OTP for password reset
        
        Args:
            phone_number: User's phone number
            
        Raises:
            HTTPException: If user not found
        """
        # Get user
        user = await self.user_repo.get_by_phone(phone_number)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Phone number not registered"
            )
        
        # Generate and send OTP
        otp = generate_otp()
        store_otp(phone_number, otp)
        send_otp_sms(phone_number, otp)
    
    async def reset_password(
        self,
        phone_number: str,
        otp: str,
        new_password: str
    ) -> None:
        """
        Reset password using OTP
        
        Args:
            phone_number: User's phone number
            otp: OTP code
            new_password: New password
            
        Raises:
            HTTPException: If OTP is invalid or user not found
        """
        # Verify OTP
        if not verify_otp(phone_number, otp):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid or expired OTP"
            )
        
        # Get user
        user = await self.user_repo.get_by_phone(phone_number)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Update password
        new_password_hash = hash_password(new_password)
        await self.user_repo.update_password(user.id, new_password_hash)
        await self.db.commit()
    
    async def resend_otp(self, phone_number: str) -> None:
        """
        Resend OTP for verification
        
        Args:
            phone_number: User's phone number
            
        Raises:
            HTTPException: If user not found
        """
        # Check if user exists
        user = await self.user_repo.get_by_phone(phone_number)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Phone number not registered"
            )
        
        # Generate and send new OTP
        otp = generate_otp()
        store_otp(phone_number, otp)
        send_otp_sms(phone_number, otp)
