"""
Seller API routes for shop and product management
"""
from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db, get_product_service, get_order_service, get_voucher_service
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
from app.schemas.order import (
    OrderListResponse,
    OrderResponse,
    OrderStatusUpdate,
    OrderStatus,
)
from app.schemas.voucher import (
    VoucherCreate,
    VoucherUpdate,
    VoucherResponse,
    VoucherListResponse,
)
from app.services.shop import ShopService
from app.services.product import ProductService
from app.services.order import OrderService
from app.services.voucher import VoucherService

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


# Order management endpoints

@router.get("/orders", response_model=OrderListResponse)
async def list_shop_orders(
    status_filter: Optional[OrderStatus] = Query(None, description="Filter by order status"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_user),
    order_service: OrderService = Depends(get_order_service),
    db: AsyncSession = Depends(get_db),
):
    """
    List all orders for seller's shop
    
    - Supports pagination
    - Optional status filter
    - Returns order summaries
    
    Requires seller with active shop.
    """
    # Get seller's shop
    shop_service = ShopService(db)
    shop = await shop_service.get_my_shop(current_user.id)
    
    return await order_service.list_shop_orders(
        shop_id=shop.id,
        status_filter=status_filter,
        page=page,
        page_size=page_size
    )


@router.get("/orders/{order_id}", response_model=OrderResponse)
async def get_shop_order_detail(
    order_id: UUID,
    current_user: User = Depends(get_current_user),
    order_service: OrderService = Depends(get_order_service),
    db: AsyncSession = Depends(get_db),
):
    """
    Get detailed information about a shop order
    
    - Includes all order items
    - Shows buyer information
    
    Requires seller with active shop and order ownership.
    """
    # Get seller's shop
    shop_service = ShopService(db)
    shop = await shop_service.get_my_shop(current_user.id)
    
    return await order_service.get_shop_order_detail(
        shop_id=shop.id,
        order_id=order_id
    )


@router.patch("/orders/{order_id}/status", response_model=OrderResponse)
async def update_order_status(
    order_id: UUID,
    status_update: OrderStatusUpdate,
    current_user: User = Depends(get_current_user),
    order_service: OrderService = Depends(get_order_service),
    db: AsyncSession = Depends(get_db),
):
    """
    Update order status
    
    Valid status transitions:
    - PENDING → CONFIRMED, CANCELLED
    - CONFIRMED → PACKED, CANCELLED
    - PACKED → SHIPPING
    - SHIPPING → DELIVERED
    - DELIVERED → COMPLETED
    
    Requires seller with active shop and order ownership.
    """
    # Get seller's shop
    shop_service = ShopService(db)
    shop = await shop_service.get_my_shop(current_user.id)
    
    return await order_service.update_order_status(
        shop_id=shop.id,
        order_id=order_id,
        status_update=status_update
    )


# ==================== Voucher Management ====================

@router.post("/shops/{shop_id}/vouchers", response_model=VoucherResponse, status_code=status.HTTP_201_CREATED)
async def create_voucher(
    shop_id: UUID,
    voucher_data: VoucherCreate,
    current_user: User = Depends(get_current_user),
    voucher_service: VoucherService = Depends(get_voucher_service)
):
    """
    Create a new voucher for a shop
    
    Voucher types:
    - PERCENTAGE: Discount as a percentage (0-100)
    - FIXED_AMOUNT: Fixed discount amount
    
    Optional constraints:
    - min_order_value: Minimum order value to apply
    - max_discount: Maximum discount for percentage type
    - usage_limit: Total usage limit (null for unlimited)
    - start_date/end_date: Validity period
    
    Requires seller with shop ownership.
    """
    return await voucher_service.create_voucher(
        shop_id=shop_id,
        voucher_data=voucher_data,
        seller_id=current_user.id
    )


@router.get("/shops/{shop_id}/vouchers", response_model=VoucherListResponse)
async def list_shop_vouchers(
    shop_id: UUID,
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    current_user: User = Depends(get_current_user),
    voucher_service: VoucherService = Depends(get_voucher_service)
):
    """
    List vouchers for a shop with pagination
    
    Optional filters:
    - is_active: true/false/null (all)
    
    Requires seller with shop ownership.
    """
    return await voucher_service.list_shop_vouchers(
        shop_id=shop_id,
        seller_id=current_user.id,
        page=page,
        page_size=page_size,
        is_active=is_active
    )


@router.get("/vouchers/{voucher_id}", response_model=VoucherResponse)
async def get_voucher(
    voucher_id: UUID,
    current_user: User = Depends(get_current_user),
    voucher_service: VoucherService = Depends(get_voucher_service)
):
    """
    Get voucher details
    
    Requires seller with shop ownership.
    """
    return await voucher_service.get_voucher(
        voucher_id=voucher_id,
        seller_id=current_user.id
    )


@router.patch("/vouchers/{voucher_id}", response_model=VoucherResponse)
async def update_voucher(
    voucher_id: UUID,
    voucher_data: VoucherUpdate,
    current_user: User = Depends(get_current_user),
    voucher_service: VoucherService = Depends(get_voucher_service)
):
    """
    Update a voucher
    
    Can update all fields except:
    - code (immutable)
    - shop_id (immutable)
    - usage_count (system-managed)
    
    Requires seller with shop ownership.
    """
    return await voucher_service.update_voucher(
        voucher_id=voucher_id,
        voucher_data=voucher_data,
        seller_id=current_user.id
    )


@router.delete("/vouchers/{voucher_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_voucher(
    voucher_id: UUID,
    current_user: User = Depends(get_current_user),
    voucher_service: VoucherService = Depends(get_voucher_service)
):
    """
    Delete a voucher
    
    Permanently removes the voucher. Cannot be undone.
    
    Requires seller with shop ownership.
    """
    await voucher_service.delete_voucher(
        voucher_id=voucher_id,
        seller_id=current_user.id
    )
    return None


