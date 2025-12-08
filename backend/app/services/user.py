"""
User service for profile management
"""
from typing import Optional
from uuid import UUID

from fastapi import HTTPException, status, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.repositories.user import UserRepository
from app.schemas.user import UserResponse, UserUpdate


class UserService:
    """Service for user profile operations"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repo = UserRepository(db)
    
    async def get_profile(self, user_id: UUID) -> UserResponse:
        """
        Get user profile
        
        Args:
            user_id: User UUID
            
        Returns:
            UserResponse
            
        Raises:
            HTTPException: If user not found
        """
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        return UserResponse.model_validate(user)
    
    async def update_profile(
        self,
        user_id: UUID,
        update_data: UserUpdate
    ) -> UserResponse:
        """
        Update user profile
        
        Args:
            user_id: User UUID
            update_data: Profile update data
            
        Returns:
            Updated UserResponse
            
        Raises:
            HTTPException: If user not found or email already exists
        """
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Check if email is being updated and already exists
        if update_data.email and update_data.email != user.email:
            if await self.user_repo.email_exists(update_data.email):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email already registered"
                )
        
        # Update fields
        update_dict = update_data.model_dump(exclude_unset=True)
        for field, value in update_dict.items():
            setattr(user, field, value)
        
        updated_user = await self.user_repo.update(user)
        await self.db.commit()
        
        return UserResponse.model_validate(updated_user)
    
    async def upload_avatar(
        self,
        user_id: UUID,
        file: UploadFile
    ) -> str:
        """
        Upload user avatar image
        
        Args:
            user_id: User UUID
            file: Avatar image file
            
        Returns:
            URL to uploaded avatar
            
        Raises:
            HTTPException: If user not found or file invalid
            
        Note:
            This is a placeholder implementation.
            In production, implement actual file upload to S3/GCS/etc.
        """
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Validate file type
        if not file.content_type or not file.content_type.startswith('image/'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be an image"
            )
        
        # Validate file size (5MB max)
        contents = await file.read()
        if len(contents) > 5 * 1024 * 1024:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File size must be less than 5MB"
            )
        
        # TODO: Implement actual file upload to cloud storage
        # For now, return a placeholder URL
        avatar_url = f"https://storage.example.com/avatars/{user_id}/{file.filename}"
        
        # Update user's avatar URL
        user.avatar_url = avatar_url
        await self.user_repo.update(user)
        await self.db.commit()
        
        return avatar_url
