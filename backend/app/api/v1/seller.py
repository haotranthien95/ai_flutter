"""
Seller API routes for shop and product management
"""
from uuid import UUID
from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db, get_product_service
from app.models.user import User
from app.schemas.shop import ShopCreate, ShopUpdate, ShopResponse
from app.schemas.product import (
    ProductCreate,
    ProductUpdate,
    ProductResponse,
    ProductListResponse,
    ProductListItem,
    ProductVariantCreate,
    ProductVariantUpdate,
    ProductVariantResponse,
)
from app.services.shop import ShopService
from app.services.product import ProductService

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


# Product management endpoints

@router.post("/products", response_model=ProductResponse, status_code=status.HTTP_201_CREATED)
async def create_product(
    product_data: ProductCreate,
    current_user: User = Depends(get_current_user),
    product_service: ProductService = Depends(get_product_service),
):
    """
    Create a new product
    
    Requires:
    - User must be a seller with an active shop
    - Valid category if provided
    """
    return await product_service.create_product(current_user.id, product_data)


@router.get("/products", response_model=ProductListResponse)
async def list_my_products(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_user),
    product_service: ProductService = Depends(get_product_service),
):
    """List all products for seller's shop"""
    products, total, total_pages = await product_service.list_shop_products(
        current_user.id, page, page_size
    )
    
    return ProductListResponse(
        products=[ProductListItem.model_validate(p) for p in products],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.put("/products/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: UUID,
    product_data: ProductUpdate,
    current_user: User = Depends(get_current_user),
    product_service: ProductService = Depends(get_product_service),
):
    """Update a product (only own products)"""
    return await product_service.update_product(
        current_user.id, product_id, product_data
    )


@router.delete("/products/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(
    product_id: UUID,
    current_user: User = Depends(get_current_user),
    product_service: ProductService = Depends(get_product_service),
):
    """Delete a product (only own products)"""
    await product_service.delete_product(current_user.id, product_id)


# Product variant management endpoints

@router.post("/products/{product_id}/variants", response_model=ProductVariantResponse, status_code=status.HTTP_201_CREATED)
async def create_variant(
    product_id: UUID,
    variant_data: ProductVariantCreate,
    current_user: User = Depends(get_current_user),
    product_service: ProductService = Depends(get_product_service),
):
    """Create a product variant (only for own products)"""
    return await product_service.create_variant(
        current_user.id, product_id, variant_data
    )


@router.put("/variants/{variant_id}", response_model=ProductVariantResponse)
async def update_variant(
    variant_id: UUID,
    variant_data: ProductVariantUpdate,
    current_user: User = Depends(get_current_user),
    product_service: ProductService = Depends(get_product_service),
):
    """Update a product variant (only for own products)"""
    return await product_service.update_variant(
        current_user.id, variant_id, variant_data
    )


@router.delete("/variants/{variant_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_variant(
    variant_id: UUID,
    current_user: User = Depends(get_current_user),
    product_service: ProductService = Depends(get_product_service),
):
    """Delete a product variant (only for own products)"""
    await product_service.delete_variant(current_user.id, variant_id)
