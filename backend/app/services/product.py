"""
Product service for business logic
"""
from typing import List, Optional, Tuple
from uuid import UUID
from decimal import Decimal

from fastapi import HTTPException, status

from app.models.product import Product, ProductVariant, ProductCondition
from app.models.user import UserRole
from app.repositories.product import ProductRepository, ProductVariantRepository
from app.repositories.category import CategoryRepository
from app.repositories.shop import ShopRepository
from app.schemas.product import (
    ProductCreate,
    ProductUpdate,
    ProductListItem,
    ProductVariantCreate,
    ProductVariantUpdate,
)


class ProductService:
    """Service for product business logic"""
    
    def __init__(
        self,
        product_repo: ProductRepository,
        variant_repo: ProductVariantRepository,
        category_repo: CategoryRepository,
        shop_repo: ShopRepository,
    ):
        self.product_repo = product_repo
        self.variant_repo = variant_repo
        self.category_repo = category_repo
        self.shop_repo = shop_repo
    
    # Buyer-facing methods
    
    async def list_products(
        self,
        category_id: Optional[UUID] = None,
        shop_id: Optional[UUID] = None,
        min_price: Optional[Decimal] = None,
        max_price: Optional[Decimal] = None,
        condition: Optional[ProductCondition] = None,
        min_rating: Optional[float] = None,
        search_query: Optional[str] = None,
        sort_by: str = "created_at",
        sort_order: str = "desc",
        page: int = 1,
        page_size: int = 20,
    ) -> Tuple[List[Product], int, int]:
        """
        List products with filters and pagination (public view)
        
        Args:
            category_id: Filter by category
            shop_id: Filter by shop
            min_price: Minimum price
            max_price: Maximum price
            condition: Product condition
            min_rating: Minimum rating
            search_query: Search in title/description
            sort_by: Sort field
            sort_order: Sort order (asc/desc)
            page: Page number (1-based)
            page_size: Items per page
        
        Returns:
            Tuple of (products, total count, total pages)
        """
        if page < 1:
            page = 1
        if page_size < 1 or page_size > 100:
            page_size = 20
        
        skip = (page - 1) * page_size
        
        products, total = await self.product_repo.list_with_filters(
            shop_id=shop_id,
            category_id=category_id,
            min_price=min_price,
            max_price=max_price,
            condition=condition,
            min_rating=min_rating,
            is_active=True,
            search_query=search_query,
            sort_by=sort_by,
            sort_order=sort_order,
            skip=skip,
            limit=page_size,
        )
        
        total_pages = (total + page_size - 1) // page_size
        return products, total, total_pages
    
    async def get_product_detail(self, product_id: UUID) -> Product:
        """
        Get product detail with variants (public view)
        
        Args:
            product_id: Product ID
        
        Returns:
            Product with variants
        
        Raises:
            HTTPException: If product not found or not active
        """
        product = await self.product_repo.get_with_variants(product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
        
        if not product.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not available"
            )
        
        return product
    
    async def get_product_variants(
        self,
        product_id: UUID
    ) -> List[ProductVariant]:
        """
        Get all active variants for a product
        
        Args:
            product_id: Product ID
        
        Returns:
            List of active variants
        
        Raises:
            HTTPException: If product not found
        """
        product = await self.product_repo.get(product_id)
        if not product or not product.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
        
        return await self.variant_repo.get_by_product(product_id, active_only=True)
    
    async def search_autocomplete(
        self,
        query: str,
        limit: int = 10
    ) -> List[str]:
        """
        Get product title suggestions for autocomplete
        
        Args:
            query: Search query
            limit: Max number of suggestions
        
        Returns:
            List of product titles
        """
        if not query or len(query) < 2:
            return []
        
        return await self.product_repo.search_autocomplete(query, limit)
    
    # Seller methods
    
    async def create_product(
        self,
        user_id: UUID,
        product_data: ProductCreate
    ) -> Product:
        """
        Create a new product (seller only)
        
        Args:
            user_id: User ID (must be seller)
            product_data: Product creation data
        
        Returns:
            Created product
        
        Raises:
            HTTPException: If shop not found or validation fails
        """
        # Get user's shop
        shop = await self.shop_repo.get_by_user_id(user_id)
        if not shop:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You must have an active shop to create products"
            )
        
        if shop.status != "ACTIVE":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Your shop must be active to create products"
            )
        
        # Validate category if provided
        if product_data.category_id:
            category = await self.category_repo.get(product_data.category_id)
            if not category:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Category not found"
                )
            if not category.is_active:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Cannot assign product to inactive category"
                )
        
        # Create product
        product_dict = product_data.model_dump(exclude={'variants'})
        product = Product(**product_dict, shop_id=shop.id)
        product = await self.product_repo.create(product)
        
        # Create variants if provided
        if product_data.variants:
            for variant_data in product_data.variants:
                variant = ProductVariant(
                    **variant_data.model_dump(),
                    product_id=product.id
                )
                await self.variant_repo.create(variant)
        
        # Reload with variants
        return await self.product_repo.get_with_variants(product.id)
    
    async def update_product(
        self,
        user_id: UUID,
        product_id: UUID,
        product_data: ProductUpdate
    ) -> Product:
        """
        Update product (seller only, own products)
        
        Args:
            user_id: User ID
            product_id: Product ID
            product_data: Update data
        
        Returns:
            Updated product
        
        Raises:
            HTTPException: If not authorized or validation fails
        """
        product = await self.product_repo.get(product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
        
        # Verify ownership
        shop = await self.shop_repo.get(product.shop_id)
        if not shop or shop.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only update your own products"
            )
        
        # Validate category if being updated
        if product_data.category_id is not None:
            if product_data.category_id:
                category = await self.category_repo.get(product_data.category_id)
                if not category:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail="Category not found"
                    )
                if not category.is_active:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Cannot assign product to inactive category"
                    )
        
        # Update product
        update_data = product_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(product, field, value)
        
        return await self.product_repo.update(product)
    
    async def delete_product(
        self,
        user_id: UUID,
        product_id: UUID
    ) -> None:
        """
        Delete product (seller only, own products)
        
        Args:
            user_id: User ID
            product_id: Product ID
        
        Raises:
            HTTPException: If not authorized
        """
        product = await self.product_repo.get(product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
        
        # Verify ownership
        shop = await self.shop_repo.get(product.shop_id)
        if not shop or shop.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only delete your own products"
            )
        
        await self.product_repo.delete(product_id)
    
    async def list_shop_products(
        self,
        user_id: UUID,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[Product], int, int]:
        """
        List all products for seller's shop
        
        Args:
            user_id: User ID (seller)
            page: Page number
            page_size: Items per page
        
        Returns:
            Tuple of (products, total, total_pages)
        
        Raises:
            HTTPException: If shop not found
        """
        shop = await self.shop_repo.get_by_user_id(user_id)
        if not shop:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Shop not found"
            )
        
        if page < 1:
            page = 1
        if page_size < 1 or page_size > 100:
            page_size = 20
        
        skip = (page - 1) * page_size
        
        products, total = await self.product_repo.get_by_shop(
            shop_id=shop.id,
            skip=skip,
            limit=page_size
        )
        
        total_pages = (total + page_size - 1) // page_size
        return products, total, total_pages
    
    # Variant management methods
    
    async def create_variant(
        self,
        user_id: UUID,
        product_id: UUID,
        variant_data: ProductVariantCreate
    ) -> ProductVariant:
        """
        Create product variant (seller only)
        
        Args:
            user_id: User ID
            product_id: Product ID
            variant_data: Variant creation data
        
        Returns:
            Created variant
        
        Raises:
            HTTPException: If not authorized
        """
        product = await self.product_repo.get(product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
        
        # Verify ownership
        shop = await self.shop_repo.get(product.shop_id)
        if not shop or shop.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only create variants for your own products"
            )
        
        # Check SKU uniqueness if provided
        if variant_data.sku:
            existing = await self.variant_repo.get_by_sku(variant_data.sku)
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="SKU already exists"
                )
        
        variant = ProductVariant(
            **variant_data.model_dump(),
            product_id=product_id
        )
        return await self.variant_repo.create(variant)
    
    async def update_variant(
        self,
        user_id: UUID,
        variant_id: UUID,
        variant_data: ProductVariantUpdate
    ) -> ProductVariant:
        """
        Update product variant (seller only)
        
        Args:
            user_id: User ID
            variant_id: Variant ID
            variant_data: Update data
        
        Returns:
            Updated variant
        
        Raises:
            HTTPException: If not authorized
        """
        variant = await self.variant_repo.get(variant_id)
        if not variant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Variant not found"
            )
        
        # Get product and verify ownership
        product = await self.product_repo.get(variant.product_id)
        shop = await self.shop_repo.get(product.shop_id)
        if not shop or shop.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only update variants of your own products"
            )
        
        # Check SKU uniqueness if being updated
        if variant_data.sku is not None and variant_data.sku != variant.sku:
            existing = await self.variant_repo.get_by_sku(variant_data.sku)
            if existing:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="SKU already exists"
                )
        
        # Update variant
        update_data = variant_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(variant, field, value)
        
        return await self.variant_repo.update(variant)
    
    async def delete_variant(
        self,
        user_id: UUID,
        variant_id: UUID
    ) -> None:
        """
        Delete product variant (seller only)
        
        Args:
            user_id: User ID
            variant_id: Variant ID
        
        Raises:
            HTTPException: If not authorized
        """
        variant = await self.variant_repo.get(variant_id)
        if not variant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Variant not found"
            )
        
        # Get product and verify ownership
        product = await self.product_repo.get(variant.product_id)
        shop = await self.shop_repo.get(product.shop_id)
        if not shop or shop.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You can only delete variants of your own products"
            )
        
        await self.variant_repo.delete(variant_id)
