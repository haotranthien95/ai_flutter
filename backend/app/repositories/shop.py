"""
Shop repository for database operations
"""
from typing import Optional, List
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.shop import Shop, ShopStatus
from app.repositories.base import BaseRepository


class ShopRepository(BaseRepository[Shop]):
    """Repository for Shop model operations"""
    
    def __init__(self, db: AsyncSession):
        super().__init__(Shop, db)
    
    async def get_by_owner(self, owner_id: UUID) -> Optional[Shop]:
        """
        Get shop by owner ID
        
        Args:
            owner_id: User ID of the shop owner
            
        Returns:
            Shop if found, None otherwise
        """
        query = select(Shop).where(Shop.owner_id == owner_id)
        result = await self.db.execute(query)
        return result.scalar_one_or_none()
    
    async def get_by_name(self, shop_name: str) -> Optional[Shop]:
        """
        Get shop by name
        
        Args:
            shop_name: Unique shop name
            
        Returns:
            Shop if found, None otherwise
        """
        query = select(Shop).where(Shop.shop_name == shop_name)
        result = await self.db.execute(query)
        return result.scalar_one_or_none()
    
    async def list_all(
        self,
        status: Optional[ShopStatus] = None,
        skip: int = 0,
        limit: int = 100
    ) -> List[Shop]:
        """
        List all shops with optional filtering
        
        Args:
            status: Filter by shop status
            skip: Number of records to skip (pagination)
            limit: Maximum number of records to return
            
        Returns:
            List of shops
        """
        query = select(Shop)
        
        if status:
            query = query.where(Shop.status == status)
        
        query = query.order_by(Shop.created_at.desc()).offset(skip).limit(limit)
        
        result = await self.db.execute(query)
        return list(result.scalars().all())
    
    async def count_all(self, status: Optional[ShopStatus] = None) -> int:
        """
        Count total shops with optional filtering
        
        Args:
            status: Filter by shop status
            
        Returns:
            Total count
        """
        query = select(func.count(Shop.id))
        
        if status:
            query = query.where(Shop.status == status)
        
        result = await self.db.execute(query)
        return result.scalar_one()
