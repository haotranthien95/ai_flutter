"""
Cart repository for database operations
"""
from typing import List, Optional
from uuid import UUID

from sqlalchemy import select, and_, delete
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.cart import CartItem
from app.repositories.base import BaseRepository


class CartRepository(BaseRepository[CartItem]):
    """Repository for cart operations"""
    
    def __init__(self, db: AsyncSession):
        super().__init__(CartItem, db)
    
    async def list_by_user(
        self,
        user_id: UUID,
        load_relations: bool = True
    ) -> List[CartItem]:
        """
        Get all cart items for a user
        
        Args:
            user_id: User ID
            load_relations: If True, eager load product and variant
        
        Returns:
            List of cart items
        """
        query = select(CartItem).where(CartItem.user_id == user_id)
        
        if load_relations:
            query = query.options(
                selectinload(CartItem.product),
                selectinload(CartItem.variant)
            )
        
        query = query.order_by(CartItem.created_at.desc())
        
        result = await self.db.execute(query)
        return list(result.scalars().all())
    
    async def find_item(
        self,
        user_id: UUID,
        product_id: UUID,
        variant_id: Optional[UUID] = None
    ) -> Optional[CartItem]:
        """
        Find specific cart item for user
        
        Args:
            user_id: User ID
            product_id: Product ID
            variant_id: Variant ID (optional)
        
        Returns:
            Cart item or None
        """
        conditions = [
            CartItem.user_id == user_id,
            CartItem.product_id == product_id
        ]
        
        if variant_id is None:
            conditions.append(CartItem.variant_id.is_(None))
        else:
            conditions.append(CartItem.variant_id == variant_id)
        
        result = await self.db.execute(
            select(CartItem)
            .where(and_(*conditions))
            .options(
                selectinload(CartItem.product),
                selectinload(CartItem.variant)
            )
        )
        return result.scalar_one_or_none()
    
    async def get_with_relations(self, cart_item_id: UUID) -> Optional[CartItem]:
        """
        Get cart item with product and variant loaded
        
        Args:
            cart_item_id: Cart item ID
        
        Returns:
            Cart item with relations or None
        """
        result = await self.db.execute(
            select(CartItem)
            .where(CartItem.id == cart_item_id)
            .options(
                selectinload(CartItem.product),
                selectinload(CartItem.variant)
            )
        )
        return result.scalar_one_or_none()
    
    async def clear_user_cart(self, user_id: UUID) -> None:
        """
        Remove all items from user's cart
        
        Args:
            user_id: User ID
        """
        await self.db.execute(
            delete(CartItem).where(CartItem.user_id == user_id)
        )
        await self.db.flush()
    
    async def delete_by_product(
        self,
        user_id: UUID,
        product_id: UUID,
        variant_id: Optional[UUID] = None
    ) -> None:
        """
        Delete cart item by product/variant
        
        Args:
            user_id: User ID
            product_id: Product ID
            variant_id: Variant ID (optional)
        """
        conditions = [
            CartItem.user_id == user_id,
            CartItem.product_id == product_id
        ]
        
        if variant_id is None:
            conditions.append(CartItem.variant_id.is_(None))
        else:
            conditions.append(CartItem.variant_id == variant_id)
        
        await self.db.execute(
            delete(CartItem).where(and_(*conditions))
        )
        await self.db.flush()
