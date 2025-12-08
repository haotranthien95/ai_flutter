"""
Admin API routes for platform management.
"""
from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends, Query, Body
from pydantic import BaseModel

from app.dependencies import require_admin, get_admin_service, get_category_service
from app.models.user import User, UserRole
from app.services.admin import AdminService
from app.services.category import CategoryService
from app.schemas.user import UserResponse
from app.schemas.shop import ShopResponse
from app.schemas.product import ProductResponse
from app.schemas.category import (
    CategoryCreate,
    CategoryUpdate,
    CategoryResponse,
)

router = APIRouter()


class PlatformMetricsResponse(BaseModel):
    """Platform metrics response."""
    users: dict
    shops: dict
    products: dict
    orders: dict
    revenue: dict


class UserListResponse(BaseModel):
    """User list response."""
    items: list[UserResponse]
    total: int
    page: int
    page_size: int


class ShopListResponse(BaseModel):
    """Shop list response."""
    items: list[ShopResponse]
    total: int
    page: int
    page_size: int


class ProductListResponse(BaseModel):
    """Product list response."""
    items: list[ProductResponse]
    total: int
    page: int
    page_size: int


class SuspendUserRequest(BaseModel):
    """Request to suspend a user."""
    reason: Optional[str] = None


class UpdateShopStatusRequest(BaseModel):
    """Request to update shop status."""
    is_active: bool
    reason: Optional[str] = None


class ModerateProductRequest(BaseModel):
    """Request to moderate a product."""
    is_active: bool
    reason: Optional[str] = None


@router.get("/dashboard", response_model=PlatformMetricsResponse)
async def get_dashboard_metrics(
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends(get_admin_service),
):
    """
    Get platform-wide metrics for admin dashboard.
    
    **Admin only**
    
    Returns:
    - User statistics (total, active, suspended)
    - Shop statistics (total, active, inactive)
    - Product statistics (total, active, inactive)
    - Order statistics (total, last 30 days)
    - Revenue statistics (total, last 30 days)
    """
    metrics = await admin_service.get_platform_metrics()
    return metrics


@router.get("/users", response_model=UserListResponse)
async def list_users(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    role: Optional[UserRole] = Query(None, description="Filter by role"),
    is_suspended: Optional[bool] = Query(None, description="Filter by suspension status"),
    search: Optional[str] = Query(None, description="Search by name, phone, or email"),
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends(get_admin_service),
):
    """
    List all users with filters.
    
    **Admin only**
    
    - **page**: Page number (default: 1)
    - **page_size**: Items per page (default: 20, max: 100)
    - **role**: Filter by user role
    - **is_suspended**: Filter by suspension status
    - **search**: Search query
    """
    users, total = await admin_service.list_users(
        page=page,
        page_size=page_size,
        role=role,
        is_suspended=is_suspended,
        search=search,
    )
    
    return UserListResponse(
        items=[UserResponse.model_validate(u) for u in users],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.patch("/users/{user_id}/suspend", response_model=UserResponse)
async def suspend_user(
    user_id: UUID,
    request: SuspendUserRequest = Body(...),
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends(get_admin_service),
):
    """
    Suspend a user account.
    
    **Admin only**
    
    - **user_id**: User's UUID
    - **reason**: Optional suspension reason
    """
    user = await admin_service.suspend_user(user_id, request.reason)
    return UserResponse.model_validate(user)


@router.patch("/users/{user_id}/unsuspend", response_model=UserResponse)
async def unsuspend_user(
    user_id: UUID,
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends(get_admin_service),
):
    """
    Unsuspend a user account.
    
    **Admin only**
    
    - **user_id**: User's UUID
    """
    user = await admin_service.unsuspend_user(user_id)
    return UserResponse.model_validate(user)


@router.get("/shops", response_model=ShopListResponse)
async def list_shops(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    search: Optional[str] = Query(None, description="Search by shop name or description"),
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends(get_admin_service),
):
    """
    List all shops with filters.
    
    **Admin only**
    
    - **page**: Page number (default: 1)
    - **page_size**: Items per page (default: 20, max: 100)
    - **is_active**: Filter by active status
    - **search**: Search query
    """
    shops, total = await admin_service.list_shops(
        page=page,
        page_size=page_size,
        is_active=is_active,
        search=search,
    )
    
    return ShopListResponse(
        items=[ShopResponse.model_validate(s) for s in shops],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.patch("/shops/{shop_id}/status", response_model=ShopResponse)
async def update_shop_status(
    shop_id: UUID,
    request: UpdateShopStatusRequest = Body(...),
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends(get_admin_service),
):
    """
    Update shop status (approve or suspend).
    
    **Admin only**
    
    - **shop_id**: Shop's UUID
    - **is_active**: New active status
    - **reason**: Optional reason for status change
    """
    shop = await admin_service.update_shop_status(
        shop_id, 
        request.is_active, 
        request.reason
    )
    return ShopResponse.model_validate(shop)


@router.get("/products", response_model=ProductListResponse)
async def list_products(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    search: Optional[str] = Query(None, description="Search by product name or description"),
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends(get_admin_service),
):
    """
    List all products across all shops with filters.
    
    **Admin only**
    
    - **page**: Page number (default: 1)
    - **page_size**: Items per page (default: 20, max: 100)
    - **is_active**: Filter by active status
    - **search**: Search query
    """
    products, total = await admin_service.list_all_products(
        page=page,
        page_size=page_size,
        is_active=is_active,
        search=search,
    )
    
    return ProductListResponse(
        items=[ProductResponse.model_validate(p) for p in products],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.patch("/products/{product_id}/status", response_model=ProductResponse)
async def moderate_product(
    product_id: UUID,
    request: ModerateProductRequest = Body(...),
    current_user: User = Depends(require_admin),
    admin_service: AdminService = Depends(get_admin_service),
):
    """
    Moderate a product (activate or deactivate).
    
    **Admin only**
    
    - **product_id**: Product's UUID
    - **is_active**: New active status
    - **reason**: Optional moderation reason
    """
    product = await admin_service.moderate_product(
        product_id, 
        request.is_active, 
        request.reason
    )
    return ProductResponse.model_validate(product)


# Category management endpoints

@router.post("/categories", response_model=CategoryResponse, status_code=201)
async def create_category(
    category_data: CategoryCreate,
    current_user: User = Depends(require_admin),
    category_service: CategoryService = Depends(get_category_service),
):
    """
    Create a new category.
    
    **Admin only**
    
    - **name**: Category name
    - **description**: Category description (optional)
    - **parent_id**: Parent category ID (optional, for subcategories)
    """
    category = await category_service.create_category(category_data)
    return CategoryResponse.model_validate(category)


@router.put("/categories/{category_id}", response_model=CategoryResponse)
async def update_category(
    category_id: UUID,
    category_data: CategoryUpdate,
    current_user: User = Depends(require_admin),
    category_service: CategoryService = Depends(get_category_service),
):
    """
    Update a category.
    
    **Admin only**
    
    - **category_id**: Category's UUID
    - **name**: New category name (optional)
    - **description**: New description (optional)
    - **parent_id**: New parent category ID (optional)
    - **is_active**: New active status (optional)
    """
    category = await category_service.update_category(category_id, category_data)
    return CategoryResponse.model_validate(category)


@router.delete("/categories/{category_id}", status_code=204)
async def delete_category(
    category_id: UUID,
    current_user: User = Depends(require_admin),
    category_service: CategoryService = Depends(get_category_service),
):
    """
    Delete a category (will cascade to subcategories).
    
    **Admin only**
    
    - **category_id**: Category's UUID
    """
    await category_service.delete_category(category_id)
    return None
