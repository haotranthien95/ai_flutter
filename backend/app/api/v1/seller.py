"""
Seller API routes for shop management
"""
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.shop import ShopCreate, ShopUpdate, ShopResponse
from app.services.shop import ShopService

router = APIRouter()


@router.post("/shops", response_model=ShopResponse, status_code=status.HTTP_201_CREATED)
async def register_shop(
    shop_data: ShopCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Register as a seller by creating a shop
    
    - User role will be upgraded to SELLER
    - User can only have one shop
    - Shop name must be unique
    """
    shop_service = ShopService(db)
    return await shop_service.register_shop(current_user.id, shop_data)


@router.get("/shops/me", response_model=ShopResponse)
async def get_my_shop(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get current user's shop"""
    shop_service = ShopService(db)
    return await shop_service.get_my_shop(current_user.id)


@router.put("/shops/me", response_model=ShopResponse)
async def update_my_shop(
    shop_data: ShopUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update current user's shop"""
    shop_service = ShopService(db)
    return await shop_service.update_shop(current_user.id, shop_data)
