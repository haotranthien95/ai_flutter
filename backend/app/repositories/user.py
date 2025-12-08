"""
User repository for database operations
"""
from typing import Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.repositories.base import BaseRepository


class UserRepository(BaseRepository[User]):
    """
    Repository for User model operations
    """
    
    def __init__(self, db: AsyncSession):
        """
        Initialize User repository
        
        Args:
            db: Database session
        """
        super().__init__(User, db)
    
    async def get_by_phone(self, phone_number: str) -> Optional[User]:
        """
        Get user by phone number
        
        Args:
            phone_number: User's phone number
            
        Returns:
            User instance or None if not found
        """
        result = await self.db.execute(
            select(User).where(User.phone_number == phone_number)
        )
        return result.scalar_one_or_none()
    
    async def get_by_email(self, email: str) -> Optional[User]:
        """
        Get user by email address
        
        Args:
            email: User's email address
            
        Returns:
            User instance or None if not found
        """
        result = await self.db.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()
    
    async def phone_exists(self, phone_number: str) -> bool:
        """
        Check if phone number is already registered
        
        Args:
            phone_number: Phone number to check
            
        Returns:
            True if phone exists, False otherwise
        """
        result = await self.db.execute(
            select(User.id).where(User.phone_number == phone_number)
        )
        return result.scalar_one_or_none() is not None
    
    async def email_exists(self, email: str) -> bool:
        """
        Check if email is already registered
        
        Args:
            email: Email to check
            
        Returns:
            True if email exists, False otherwise
        """
        result = await self.db.execute(
            select(User.id).where(User.email == email)
        )
        return result.scalar_one_or_none() is not None
    
    async def mark_as_verified(self, user_id: UUID) -> Optional[User]:
        """
        Mark user as verified
        
        Args:
            user_id: User's UUID
            
        Returns:
            Updated user instance or None if not found
        """
        user = await self.get_by_id(user_id)
        if user:
            user.is_verified = True
            return await self.update(user)
        return None
    
    async def update_password(self, user_id: UUID, password_hash: str) -> Optional[User]:
        """
        Update user's password hash
        
        Args:
            user_id: User's UUID
            password_hash: New password hash
            
        Returns:
            Updated user instance or None if not found
        """
        user = await self.get_by_id(user_id)
        if user:
            user.password_hash = password_hash
            return await self.update(user)
        return None
