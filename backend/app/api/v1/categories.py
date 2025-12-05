"""
Category API endpoints
"""
from typing import Optional, List
from uuid import UUID

from fastapi import APIRouter, Depends

from app.dependencies import get_category_service
from app.services.category import CategoryService
from app.schemas.category import (
    CategoryResponse,
    CategoryWithSubcategories,
    CategoryTree,
    CategoryListResponse,
)

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=CategoryListResponse)
async def list_categories(
    category_service: CategoryService = Depends(get_category_service),
):
    """
    List all active categories
    
    Public endpoint - no authentication required
    """
    categories = await category_service.list_all_categories()
    return CategoryListResponse(
        categories=[CategoryResponse.model_validate(c) for c in categories],
        total=len(categories),
    )


@router.get("/roots", response_model=list[CategoryResponse])
async def list_root_categories(
    category_service: CategoryService = Depends(get_category_service),
):
    """
    List root categories (no parent)
    
    Public endpoint - no authentication required
    """
    categories = await category_service.list_root_categories()
    return [CategoryResponse.model_validate(c) for c in categories]


@router.get("/tree", response_model=list[CategoryTree])
async def get_category_tree(
    parent_id: Optional[UUID] = None,
    category_service: CategoryService = Depends(get_category_service),
):
    """
    Get hierarchical category tree
    
    Public endpoint - no authentication required
    """
    categories = await category_service.get_category_tree(parent_id)
    return [CategoryTree.model_validate(c) for c in categories]


@router.get("/{category_id}", response_model=CategoryWithSubcategories)
async def get_category(
    category_id: UUID,
    category_service: CategoryService = Depends(get_category_service),
):
    """
    Get category with subcategories
    
    Public endpoint - no authentication required
    """
    category = await category_service.get_category_with_subcategories(category_id)
    return CategoryWithSubcategories.model_validate(category)


@router.get("/{category_id}/subcategories", response_model=list[CategoryResponse])
async def list_subcategories(
    category_id: UUID,
    category_service: CategoryService = Depends(get_category_service),
):
    """
    List subcategories of a parent category
    
    Public endpoint - no authentication required
    """
    categories = await category_service.list_subcategories(category_id)
    return [CategoryResponse.model_validate(c) for c in categories]
