"""
Voucher repository for database operations
"""
from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from sqlalchemy import select, and_, or_, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.voucher import Voucher, VoucherType
from app.repositories.base import BaseRepository


class VoucherRepository(BaseRepository[Voucher]):
    """Repository for voucher database operations"""
    
    def __init__(self, db: AsyncSession):
        super().__init__(Voucher, db)
    
    async def get_by_code(self, code: str) -> Optional[Voucher]:
        """Get voucher by code"""
        result = await self.db.execute(
            select(Voucher).where(Voucher.code == code.upper())
        )
        return result.scalar_one_or_none()
    
    async def get_by_code_and_shop(self, code: str, shop_id: UUID) -> Optional[Voucher]:
        """Get voucher by code and shop"""
        result = await self.db.execute(
            select(Voucher).where(
                and_(
                    Voucher.code == code.upper(),
                    Voucher.shop_id == shop_id
                )
            )
        )
        return result.scalar_one_or_none()
    
    async def list_by_shop(
        self,
        shop_id: UUID,
        skip: int = 0,
        limit: int = 20,
        is_active: Optional[bool] = None
    ) -> tuple[list[Voucher], int]:
        """List vouchers for a shop with pagination"""
        conditions = [Voucher.shop_id == shop_id]
        
        if is_active is not None:
            conditions.append(Voucher.is_active == is_active)
        
        # Count query
        count_result = await self.db.execute(
            select(func.count(Voucher.id)).where(and_(*conditions))
        )
        total = count_result.scalar_one()
        
        # Data query
        result = await self.db.execute(
            select(Voucher)
            .where(and_(*conditions))
            .order_by(Voucher.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        vouchers = result.scalars().all()
        
        return list(vouchers), total
    
    async def get_available_for_order(
        self,
        shop_id: UUID,
        subtotal: Decimal,
        current_time: Optional[datetime] = None
    ) -> list[Voucher]:
        """
        Get all available vouchers for an order
        
        A voucher is available if:
        - It belongs to the shop
        - It is active
        - Current time is within validity period
        - Usage limit not reached (if set)
        - Minimum order value met (if set)
        """
        if current_time is None:
            current_time = datetime.utcnow()
        
        conditions = [
            Voucher.shop_id == shop_id,
            Voucher.is_active == True,
            Voucher.start_date <= current_time,
            Voucher.end_date >= current_time,
            or_(
                Voucher.usage_limit.is_(None),
                Voucher.usage_count < Voucher.usage_limit
            ),
            or_(
                Voucher.min_order_value.is_(None),
                Voucher.min_order_value <= subtotal
            )
        ]
        
        result = await self.db.execute(
            select(Voucher)
            .where(and_(*conditions))
            .order_by(Voucher.value.desc())  # Show highest discounts first
        )
        
        return list(result.scalars().all())
    
    async def increment_usage(self, voucher_id: UUID) -> None:
        """Increment voucher usage count"""
        voucher = await self.get(voucher_id)
        if voucher:
            voucher.usage_count += 1
            await self.db.flush()
    
    async def code_exists(self, code: str, exclude_id: Optional[UUID] = None) -> bool:
        """Check if voucher code already exists"""
        query = select(func.count(Voucher.id)).where(Voucher.code == code.upper())
        
        if exclude_id:
            query = query.where(Voucher.id != exclude_id)
        
        result = await self.db.execute(query)
        count = result.scalar_one()
        
        return count > 0
    
    async def get_active_by_shop(self, shop_id: UUID) -> list[Voucher]:
        """Get all currently active vouchers for a shop"""
        current_time = datetime.utcnow()
        
        result = await self.db.execute(
            select(Voucher)
            .where(
                and_(
                    Voucher.shop_id == shop_id,
                    Voucher.is_active == True,
                    Voucher.start_date <= current_time,
                    Voucher.end_date >= current_time
                )
            )
            .order_by(Voucher.created_at.desc())
        )
        
        return list(result.scalars().all())
