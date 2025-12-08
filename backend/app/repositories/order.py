"""
Order repository for database operations
"""
from typing import List, Optional
from uuid import UUID
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import joinedload, selectinload

from app.models.order import Order, OrderItem, OrderStatus
from app.repositories.base import BaseRepository


class OrderRepository(BaseRepository[Order]):
    """Repository for Order model"""
    
    def __init__(self, db: AsyncSession):
        super().__init__(Order, db)
    
    async def get_by_order_number(self, order_number: str) -> Optional[Order]:
        """
        Get order by order number
        
        Args:
            order_number: Order number
        
        Returns:
            Order or None
        """
        query = select(Order).where(Order.order_number == order_number)
        result = await self.db.execute(query)
        return result.scalar_one_or_none()
    
    async def get_with_items(self, order_id: UUID) -> Optional[Order]:
        """
        Get order with items loaded
        
        Args:
            order_id: Order ID
        
        Returns:
            Order with items or None
        """
        query = (
            select(Order)
            .options(
                selectinload(Order.items),
                joinedload(Order.buyer),
                joinedload(Order.shop),
            )
            .where(Order.id == order_id)
        )
        result = await self.db.execute(query)
        return result.scalar_one_or_none()
    
    async def list_by_buyer(
        self,
        buyer_id: UUID,
        status: Optional[OrderStatus] = None,
        skip: int = 0,
        limit: int = 20
    ) -> tuple[List[Order], int]:
        """
        List orders by buyer with optional status filter
        
        Args:
            buyer_id: Buyer user ID
            status: Optional order status filter
            skip: Number of records to skip
            limit: Maximum number of records to return
        
        Returns:
            Tuple of (list of orders, total count)
        """
        # Build base query
        query = (
            select(Order)
            .options(
                selectinload(Order.items),
                joinedload(Order.shop),
            )
            .where(Order.buyer_id == buyer_id)
        )
        
        # Apply status filter
        if status:
            query = query.where(Order.status == status)
        
        # Get total count
        count_query = select(Order).where(Order.buyer_id == buyer_id)
        if status:
            count_query = count_query.where(Order.status == status)
        
        from sqlalchemy import func
        total_result = await self.db.execute(
            select(func.count()).select_from(count_query.subquery())
        )
        total = total_result.scalar_one()
        
        # Apply pagination and ordering
        query = query.order_by(Order.created_at.desc()).offset(skip).limit(limit)
        
        result = await self.db.execute(query)
        orders = list(result.scalars().unique().all())
        
        return orders, total
    
    async def list_by_shop(
        self,
        shop_id: UUID,
        status: Optional[OrderStatus] = None,
        skip: int = 0,
        limit: int = 20
    ) -> tuple[List[Order], int]:
        """
        List orders by shop with optional status filter
        
        Args:
            shop_id: Shop ID
            status: Optional order status filter
            skip: Number of records to skip
            limit: Maximum number of records to return
        
        Returns:
            Tuple of (list of orders, total count)
        """
        # Build base query
        query = (
            select(Order)
            .options(
                selectinload(Order.items),
                joinedload(Order.buyer),
            )
            .where(Order.shop_id == shop_id)
        )
        
        # Apply status filter
        if status:
            query = query.where(Order.status == status)
        
        # Get total count
        count_query = select(Order).where(Order.shop_id == shop_id)
        if status:
            count_query = count_query.where(Order.status == status)
        
        from sqlalchemy import func
        total_result = await self.db.execute(
            select(func.count()).select_from(count_query.subquery())
        )
        total = total_result.scalar_one()
        
        # Apply pagination and ordering
        query = query.order_by(Order.created_at.desc()).offset(skip).limit(limit)
        
        result = await self.db.execute(query)
        orders = list(result.scalars().unique().all())
        
        return orders, total


class OrderItemRepository(BaseRepository[OrderItem]):
    """Repository for OrderItem model"""
    
    def __init__(self, db: AsyncSession):
        super().__init__(OrderItem, db)
    
    async def list_by_order(self, order_id: UUID) -> List[OrderItem]:
        """
        List all items for an order
        
        Args:
            order_id: Order ID
        
        Returns:
            List of order items
        """
        query = (
            select(OrderItem)
            .options(
                joinedload(OrderItem.product),
                joinedload(OrderItem.variant),
            )
            .where(OrderItem.order_id == order_id)
        )
        result = await self.db.execute(query)
        return list(result.scalars().unique().all())
