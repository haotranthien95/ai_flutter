"""
Shop service for business logic
"""
from typing import List, Optional
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.shop import Shop, ShopStatus
from app.models.user import UserRole
from app.repositories.shop import ShopRepository
from app.repositories.user import UserRepository
from app.schemas.shop import ShopCreate, ShopUpdate, ShopResponse


class ShopService:
    """Service for shop operations"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.shop_repo = ShopRepository(db)
        self.user_repo = UserRepository(db)
    
    async def register_shop(self, user_id: UUID, shop_data: ShopCreate) -> ShopResponse:
        """
        Register a new shop for a user
        
        Args:
            user_id: ID of the user registering the shop
            shop_data: Shop creation data
            
        Returns:
            Created shop
            
        Raises:
            HTTPException: If user already has a shop or shop name is taken
        """
        # Check if user already has a shop
        existing_shop = await self.shop_repo.get_by_owner(user_id)
        if existing_shop:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User already has a registered shop"
            )
        
        # Check if shop name is taken
        existing_name = await self.shop_repo.get_by_name(shop_data.shop_name)
        if existing_name:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Shop name is already taken"
            )
        
        # Get user
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        
        # Create shop
        shop = Shop(
            owner_id=user_id,
            **shop_data.model_dump()
        )
        
        created_shop = await self.shop_repo.create(shop)
        
        # Update user role to SELLER
        if user.role == UserRole.BUYER:
            user.role = UserRole.SELLER
            await self.user_repo.update(user)
        
        await self.db.commit()
        await self.db.refresh(created_shop)
        
        return ShopResponse.model_validate(created_shop)
    
    async def get_shop(self, shop_id: UUID) -> ShopResponse:
        """
        Get shop by ID
        
        Args:
            shop_id: Shop UUID
            
        Returns:
            Shop details
            
        Raises:
            HTTPException: If shop not found
        """
        shop = await self.shop_repo.get_by_id(shop_id)
        if not shop:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Shop not found"
            )
        
        return ShopResponse.model_validate(shop)
    
    async def get_my_shop(self, user_id: UUID) -> ShopResponse:
        """
        Get current user's shop
        
        Args:
            user_id: User UUID
            
        Returns:
            User's shop
            
        Raises:
            HTTPException: If user doesn't have a shop
        """
        shop = await self.shop_repo.get_by_owner(user_id)
        if not shop:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="You don't have a registered shop"
            )
        
        return ShopResponse.model_validate(shop)
    
    async def update_shop(self, user_id: UUID, update_data: ShopUpdate) -> ShopResponse:
        """
        Update user's shop
        
        Args:
            user_id: User UUID
            update_data: Shop update data
            
        Returns:
            Updated shop
            
        Raises:
            HTTPException: If shop not found or shop name is taken
        """
        shop = await self.shop_repo.get_by_owner(user_id)
        if not shop:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="You don't have a registered shop"
            )
        
        # If updating shop name, check if new name is taken
        if update_data.shop_name and update_data.shop_name != shop.shop_name:
            existing_name = await self.shop_repo.get_by_name(update_data.shop_name)
            if existing_name:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Shop name is already taken"
                )
        
        # Update fields
        update_dict = update_data.model_dump(exclude_unset=True)
        for field, value in update_dict.items():
            setattr(shop, field, value)
        
        updated_shop = await self.shop_repo.update(shop)
        await self.db.commit()
        await self.db.refresh(updated_shop)
        
        return ShopResponse.model_validate(updated_shop)
    
    async def list_shops(
        self,
        status: Optional[ShopStatus] = None,
        page: int = 1,
        page_size: int = 20
    ) -> tuple[List[ShopResponse], int]:
        """
        List shops with pagination
        
        Args:
            status: Filter by shop status
            page: Page number (1-indexed)
            page_size: Items per page
            
        Returns:
            Tuple of (list of shops, total count)
        """
        skip = (page - 1) * page_size
        
        shops = await self.shop_repo.list_all(status=status, skip=skip, limit=page_size)
        total = await self.shop_repo.count_all(status=status)
        
        return (
            [ShopResponse.model_validate(shop) for shop in shops],
            total
        )
