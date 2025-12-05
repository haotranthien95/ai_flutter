"""
Address repository for database operations
"""
from typing import List, Optional
from uuid import UUID

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.address import Address
from app.repositories.base import BaseRepository


class AddressRepository(BaseRepository[Address]):
    """Repository for Address model operations"""
    
    def __init__(self, db: AsyncSession):
        super().__init__(Address, db)
    
    async def list_by_user(self, user_id: UUID) -> List[Address]:
        """
        Get all addresses for a user
        
        Args:
            user_id: User's UUID
            
        Returns:
            List of user's addresses
        """
        result = await self.db.execute(
            select(Address)
            .where(Address.user_id == user_id)
            .order_by(Address.is_default.desc(), Address.created_at.desc())
        )
        return list(result.scalars().all())
    
    async def get_by_id_and_user(self, address_id: UUID, user_id: UUID) -> Optional[Address]:
        """
        Get address by ID and verify it belongs to the user
        
        Args:
            address_id: Address UUID
            user_id: User UUID
            
        Returns:
            Address if found and belongs to user, None otherwise
        """
        result = await self.db.execute(
            select(Address).where(
                and_(
                    Address.id == address_id,
                    Address.user_id == user_id
                )
            )
        )
        return result.scalar_one_or_none()
    
    async def get_default_address(self, user_id: UUID) -> Optional[Address]:
        """
        Get user's default address
        
        Args:
            user_id: User UUID
            
        Returns:
            Default address if exists, None otherwise
        """
        result = await self.db.execute(
            select(Address).where(
                and_(
                    Address.user_id == user_id,
                    Address.is_default == True
                )
            )
        )
        return result.scalar_one_or_none()
    
    async def unset_all_defaults(self, user_id: UUID) -> None:
        """
        Unset all default addresses for a user
        
        Args:
            user_id: User UUID
        """
        result = await self.db.execute(
            select(Address).where(
                and_(
                    Address.user_id == user_id,
                    Address.is_default == True
                )
            )
        )
        addresses = result.scalars().all()
        
        for address in addresses:
            address.is_default = False
        
        await self.db.flush()
    
    async def set_default(self, user_id: UUID, address_id: UUID) -> None:
        """
        Set an address as default (and unset others)
        
        Args:
            user_id: User UUID
            address_id: Address UUID to set as default
        """
        # First, unset all default addresses
        await self.unset_all_defaults(user_id)
        
        # Then set the specified address as default
        address = await self.get_by_id_and_user(address_id, user_id)
        if address:
            address.is_default = True
            await self.db.flush()
    
    async def delete_by_id_and_user(self, address_id: UUID, user_id: UUID) -> bool:
        """
        Delete an address if it belongs to the user
        
        Args:
            address_id: Address UUID
            user_id: User UUID
            
        Returns:
            True if deleted, False if not found
        """
        address = await self.get_by_id_and_user(address_id, user_id)
        if not address:
            return False
        
        await self.db.delete(address)
        await self.db.flush()
        return True
    
    async def count_by_user(self, user_id: UUID) -> int:
        """
        Count addresses for a user
        
        Args:
            user_id: User UUID
            
        Returns:
            Number of addresses
        """
        result = await self.db.execute(
            select(Address).where(Address.user_id == user_id)
        )
        return len(list(result.scalars().all()))
