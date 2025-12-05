"""
Public product API endpoints
"""
from typing import Optional
from uuid import UUID
from decimal import Decimal

from fastapi import APIRouter, Depends, Query

from app.dependencies import get_product_service
from app.services.product import ProductService
from app.schemas.product import (
    ProductResponse,
    ProductListResponse,
    ProductListItem,
    ProductVariantResponse,
    ProductCondition,
)

router = APIRouter(prefix="/products", tags=["products"])


@router.get("", response_model=ProductListResponse)
async def list_products(
    category_id: Optional[UUID] = Query(None, description="Filter by category"),
    shop_id: Optional[UUID] = Query(None, description="Filter by shop"),
    min_price: Optional[Decimal] = Query(None, ge=0, description="Minimum price"),
    max_price: Optional[Decimal] = Query(None, ge=0, description="Maximum price"),
    condition: Optional[ProductCondition] = Query(None, description="Product condition"),
    min_rating: Optional[float] = Query(None, ge=0, le=5, description="Minimum rating"),
    search: Optional[str] = Query(None, description="Search in title and description"),
    sort_by: str = Query("created_at", pattern="^(created_at|base_price|average_rating|sold_count)$"),
    sort_order: str = Query("desc", pattern="^(asc|desc)$"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    product_service: ProductService = Depends(get_product_service),
):
    """
    List products with filters and pagination
    
    Public endpoint - no authentication required
    """
    products, total, total_pages = await product_service.list_products(
        category_id=category_id,
        shop_id=shop_id,
        min_price=min_price,
        max_price=max_price,
        condition=condition,
        min_rating=min_rating,
        search_query=search,
        sort_by=sort_by,
        sort_order=sort_order,
        page=page,
        page_size=page_size,
    )
    
    return ProductListResponse(
        products=[ProductListItem.model_validate(p) for p in products],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.get("/search/autocomplete")
async def search_autocomplete(
    q: str = Query(..., min_length=2, description="Search query"),
    limit: int = Query(10, ge=1, le=20, description="Max suggestions"),
    product_service: ProductService = Depends(get_product_service),
):
    """
    Get product title suggestions for autocomplete
    
    Public endpoint - no authentication required
    """
    suggestions = await product_service.search_autocomplete(q, limit)
    return {"suggestions": suggestions}


@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: UUID,
    product_service: ProductService = Depends(get_product_service),
):
    """
    Get product detail with variants
    
    Public endpoint - no authentication required
    """
    product = await product_service.get_product_detail(product_id)
    return ProductResponse.model_validate(product)


@router.get("/{product_id}/variants", response_model=list[ProductVariantResponse])
async def get_product_variants(
    product_id: UUID,
    product_service: ProductService = Depends(get_product_service),
):
    """
    Get all active variants for a product
    
    Public endpoint - no authentication required
    """
    variants = await product_service.get_product_variants(product_id)
    return [ProductVariantResponse.model_validate(v) for v in variants]
