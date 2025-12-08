"""
Admin service for platform management and moderation.
"""
from typing import Optional, Dict, Any
from uuid import UUID
from datetime import datetime, timedelta
from fastapi import HTTPException, status
from sqlalchemy import select, func, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, UserRole
from app.models.shop import Shop
from app.models.product import Product
from app.models.order import Order, OrderStatus
from app.repositories.user import UserRepository
from app.repositories.shop import ShopRepository
from app.repositories.product import ProductRepository
from app.repositories.order import OrderRepository


class AdminService:
    """Service for admin platform management."""

    def __init__(
        self,
        user_repo: UserRepository,
        shop_repo: ShopRepository,
        product_repo: ProductRepository,
        order_repo: OrderRepository,
        db: AsyncSession,
    ):
        self.user_repo = user_repo
        self.shop_repo = shop_repo
        self.product_repo = product_repo
        self.order_repo = order_repo
        self.db = db

    async def get_platform_metrics(self) -> Dict[str, Any]:
        """
        Get platform-wide metrics for admin dashboard.
        
        Returns:
            Dictionary with platform metrics
        """
        # Total users
        total_users_query = select(func.count(User.id))
        total_users_result = await self.db.execute(total_users_query)
        total_users = total_users_result.scalar_one()

        # Active users (not suspended)
        active_users_query = select(func.count(User.id)).where(User.is_suspended == False)
        active_users_result = await self.db.execute(active_users_query)
        active_users = active_users_result.scalar_one()

        # Total shops
        total_shops_query = select(func.count(Shop.id))
        total_shops_result = await self.db.execute(total_shops_query)
        total_shops = total_shops_result.scalar_one()

        # Active shops
        active_shops_query = select(func.count(Shop.id)).where(Shop.is_active == True)
        active_shops_result = await self.db.execute(active_shops_query)
        active_shops = active_shops_result.scalar_one()

        # Total products
        total_products_query = select(func.count(Product.id))
        total_products_result = await self.db.execute(total_products_query)
        total_products = total_products_result.scalar_one()

        # Active products
        active_products_query = select(func.count(Product.id)).where(Product.is_active == True)
        active_products_result = await self.db.execute(active_products_query)
        active_products = active_products_result.scalar_one()

        # Total orders
        total_orders_query = select(func.count(Order.id))
        total_orders_result = await self.db.execute(total_orders_query)
        total_orders = total_orders_result.scalar_one()

        # Total revenue (completed orders)
        revenue_query = select(func.sum(Order.total_amount)).where(
            Order.status.in_([OrderStatus.COMPLETED, OrderStatus.DELIVERED])
        )
        revenue_result = await self.db.execute(revenue_query)
        total_revenue = revenue_result.scalar_one() or 0

        # Orders in last 30 days
        thirty_days_ago = datetime.utcnow() - timedelta(days=30)
        recent_orders_query = select(func.count(Order.id)).where(
            Order.created_at >= thirty_days_ago
        )
        recent_orders_result = await self.db.execute(recent_orders_query)
        recent_orders = recent_orders_result.scalar_one()

        # Revenue in last 30 days
        recent_revenue_query = select(func.sum(Order.total_amount)).where(
            and_(
                Order.created_at >= thirty_days_ago,
                Order.status.in_([OrderStatus.COMPLETED, OrderStatus.DELIVERED])
            )
        )
        recent_revenue_result = await self.db.execute(recent_revenue_query)
        recent_revenue = recent_revenue_result.scalar_one() or 0

        return {
            "users": {
                "total": total_users,
                "active": active_users,
                "suspended": total_users - active_users,
            },
            "shops": {
                "total": total_shops,
                "active": active_shops,
                "inactive": total_shops - active_shops,
            },
            "products": {
                "total": total_products,
                "active": active_products,
                "inactive": total_products - active_products,
            },
            "orders": {
                "total": total_orders,
                "last_30_days": recent_orders,
            },
            "revenue": {
                "total": float(total_revenue),
                "last_30_days": float(recent_revenue),
            },
        }

    async def list_users(
        self,
        page: int = 1,
        page_size: int = 20,
        role: Optional[UserRole] = None,
        is_suspended: Optional[bool] = None,
        search: Optional[str] = None,
    ) -> tuple[list[User], int]:
        """
        List users with filters.
        
        Args:
            page: Page number
            page_size: Items per page
            role: Filter by role
            is_suspended: Filter by suspension status
            search: Search by name, phone, or email
            
        Returns:
            Tuple of (users list, total count)
        """
        query = select(User)
        
        # Apply filters
        if role is not None:
            query = query.where(User.role == role)
        
        if is_suspended is not None:
            query = query.where(User.is_suspended == is_suspended)
        
        if search:
            search_filter = or_(
                User.full_name.ilike(f"%{search}%"),
                User.phone_number.ilike(f"%{search}%"),
                User.email.ilike(f"%{search}%") if search else False,
            )
            query = query.where(search_filter)
        
        # Get total count
        count_query = select(func.count()).select_from(query.subquery())
        count_result = await self.db.execute(count_query)
        total = count_result.scalar_one()
        
        # Apply pagination
        skip = (page - 1) * page_size
        query = query.order_by(User.created_at.desc()).offset(skip).limit(page_size)
        
        result = await self.db.execute(query)
        users = list(result.scalars().all())
        
        return users, total

    async def suspend_user(self, user_id: UUID, reason: Optional[str] = None) -> User:
        """
        Suspend a user account.
        
        Args:
            user_id: User's UUID
            reason: Suspension reason
            
        Returns:
            Updated user
            
        Raises:
            HTTPException: If user not found or already suspended
        """
        user = await self.user_repo.get(user_id)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        if user.role == UserRole.ADMIN:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cannot suspend admin users"
            )
        
        if user.is_suspended:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User is already suspended"
            )
        
        user.is_suspended = True
        await self.db.commit()
        await self.db.refresh(user)
        
        return user

    async def unsuspend_user(self, user_id: UUID) -> User:
        """
        Unsuspend a user account.
        
        Args:
            user_id: User's UUID
            
        Returns:
            Updated user
            
        Raises:
            HTTPException: If user not found or not suspended
        """
        user = await self.user_repo.get(user_id)
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        if not user.is_suspended:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User is not suspended"
            )
        
        user.is_suspended = False
        await self.db.commit()
        await self.db.refresh(user)
        
        return user

    async def list_shops(
        self,
        page: int = 1,
        page_size: int = 20,
        is_active: Optional[bool] = None,
        search: Optional[str] = None,
    ) -> tuple[list[Shop], int]:
        """
        List shops with filters.
        
        Args:
            page: Page number
            page_size: Items per page
            is_active: Filter by active status
            search: Search by shop name or description
            
        Returns:
            Tuple of (shops list, total count)
        """
        query = select(Shop)
        
        # Apply filters
        if is_active is not None:
            query = query.where(Shop.is_active == is_active)
        
        if search:
            search_filter = or_(
                Shop.name.ilike(f"%{search}%"),
                Shop.description.ilike(f"%{search}%"),
            )
            query = query.where(search_filter)
        
        # Get total count
        count_query = select(func.count()).select_from(query.subquery())
        count_result = await self.db.execute(count_query)
        total = count_result.scalar_one()
        
        # Apply pagination
        skip = (page - 1) * page_size
        query = query.order_by(Shop.created_at.desc()).offset(skip).limit(page_size)
        
        result = await self.db.execute(query)
        shops = list(result.scalars().all())
        
        return shops, total

    async def update_shop_status(self, shop_id: UUID, is_active: bool, reason: Optional[str] = None) -> Shop:
        """
        Update shop active status (approve or suspend).
        
        Args:
            shop_id: Shop's UUID
            is_active: New active status
            reason: Reason for status change
            
        Returns:
            Updated shop
            
        Raises:
            HTTPException: If shop not found
        """
        shop = await self.shop_repo.get(shop_id)
        
        if not shop:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Shop not found"
            )
        
        shop.is_active = is_active
        await self.db.commit()
        await self.db.refresh(shop)
        
        return shop

    async def list_all_products(
        self,
        page: int = 1,
        page_size: int = 20,
        is_active: Optional[bool] = None,
        search: Optional[str] = None,
    ) -> tuple[list[Product], int]:
        """
        List all products across all shops with filters.
        
        Args:
            page: Page number
            page_size: Items per page
            is_active: Filter by active status
            search: Search by product name or description
            
        Returns:
            Tuple of (products list, total count)
        """
        query = select(Product)
        
        # Apply filters
        if is_active is not None:
            query = query.where(Product.is_active == is_active)
        
        if search:
            search_filter = or_(
                Product.name.ilike(f"%{search}%"),
                Product.description.ilike(f"%{search}%"),
            )
            query = query.where(search_filter)
        
        # Get total count
        count_query = select(func.count()).select_from(query.subquery())
        count_result = await self.db.execute(count_query)
        total = count_result.scalar_one()
        
        # Apply pagination
        skip = (page - 1) * page_size
        query = query.order_by(Product.created_at.desc()).offset(skip).limit(page_size)
        
        result = await self.db.execute(query)
        products = list(result.scalars().all())
        
        return products, total

    async def moderate_product(self, product_id: UUID, is_active: bool, reason: Optional[str] = None) -> Product:
        """
        Moderate a product (activate or deactivate).
        
        Args:
            product_id: Product's UUID
            is_active: New active status
            reason: Moderation reason
            
        Returns:
            Updated product
            
        Raises:
            HTTPException: If product not found
        """
        product = await self.product_repo.get(product_id)
        
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
        
        product.is_active = is_active
        await self.db.commit()
        await self.db.refresh(product)
        
        return product
