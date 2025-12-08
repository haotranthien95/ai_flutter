"""
Product repository for database operations
"""
from typing import List, Optional, Tuple
from uuid import UUID
from decimal import Decimal

from sqlalchemy import select, and_, or_, func, desc, asc
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.product import Product, ProductVariant, ProductCondition
from app.repositories.base import BaseRepository


class ProductRepository(BaseRepository[Product]):
    """Repository for product operations"""
    
    def __init__(self, session: AsyncSession):
        super().__init__(Product, session)
    
    async def get_with_variants(self, product_id: UUID) -> Optional[Product]:
        """
        Get product with all variants loaded
        
        Args:
            product_id: Product ID
        
        Returns:
            Product with variants or None
        """
        result = await self.db.execute(
            select(Product)
            .where(Product.id == product_id)
            .options(selectinload(Product.variants))
        )
        return result.scalar_one_or_none()
    
    async def list_with_filters(
        self,
        shop_id: Optional[UUID] = None,
        category_id: Optional[UUID] = None,
        min_price: Optional[Decimal] = None,
        max_price: Optional[Decimal] = None,
        condition: Optional[ProductCondition] = None,
        min_rating: Optional[float] = None,
        is_active: bool = True,
        search_query: Optional[str] = None,
        sort_by: str = "created_at",
        sort_order: str = "desc",
        skip: int = 0,
        limit: int = 20
    ) -> Tuple[List[Product], int]:
        """
        List products with filters and pagination
        
        Args:
            shop_id: Filter by shop
            category_id: Filter by category
            min_price: Minimum price filter
            max_price: Maximum price filter
            condition: Product condition filter
            min_rating: Minimum rating filter
            is_active: Filter by active status
            search_query: Text search in title/description
            sort_by: Field to sort by (created_at, price, rating, sold_count)
            sort_order: Sort order (asc, desc)
            skip: Number of records to skip
            limit: Maximum number of records to return
        
        Returns:
            Tuple of (list of products, total count)
        """
        # Build conditions
        conditions = []
        
        if shop_id is not None:
            conditions.append(Product.shop_id == shop_id)
        
        if category_id is not None:
            conditions.append(Product.category_id == category_id)
        
        if min_price is not None:
            conditions.append(Product.base_price >= min_price)
        
        if max_price is not None:
            conditions.append(Product.base_price <= max_price)
        
        if condition is not None:
            conditions.append(Product.condition == condition)
        
        if min_rating is not None:
            conditions.append(Product.average_rating >= min_rating)
        
        conditions.append(Product.is_active == is_active)
        
        if search_query:
            search_pattern = f"%{search_query}%"
            conditions.append(
                or_(
                    Product.title.ilike(search_pattern),
                    Product.description.ilike(search_pattern)
                )
            )
        
        # Build base query
        query = select(Product).where(and_(*conditions))
        
        # Apply sorting
        sort_column = getattr(Product, sort_by, Product.created_at)
        if sort_order == "desc":
            query = query.order_by(desc(sort_column))
        else:
            query = query.order_by(asc(sort_column))
        
        # Get total count
        count_query = select(func.count()).select_from(Product).where(and_(*conditions))
        total_result = await self.db.execute(count_query)
        total = total_result.scalar_one()
        
        # Apply pagination
        query = query.offset(skip).limit(limit)
        
        # Execute query
        result = await self.db.execute(query)
        products = list(result.scalars().all())
        
        return products, total
    
    async def get_by_shop(
        self,
        shop_id: UUID,
        skip: int = 0,
        limit: int = 20
    ) -> Tuple[List[Product], int]:
        """
        Get all products for a shop
        
        Args:
            shop_id: Shop ID
            skip: Number of records to skip
            limit: Maximum number of records to return
        
        Returns:
            Tuple of (list of products, total count)
        """
        # Count query
        count_result = await self.db.execute(
            select(func.count())
            .select_from(Product)
            .where(Product.shop_id == shop_id)
        )
        total = count_result.scalar_one()
        
        # Data query
        result = await self.db.execute(
            select(Product)
            .where(Product.shop_id == shop_id)
            .order_by(desc(Product.created_at))
            .offset(skip)
            .limit(limit)
        )
        products = list(result.scalars().all())
        
        return products, total
    
    async def search_autocomplete(
        self,
        query: str,
        limit: int = 10
    ) -> List[str]:
        """
        Search product titles for autocomplete
        
        Args:
            query: Search query
            limit: Maximum number of suggestions
        
        Returns:
            List of matching product titles
        """
        search_pattern = f"%{query}%"
        
        result = await self.db.execute(
            select(Product.title)
            .where(
                and_(
                    Product.is_active == True,
                    Product.title.ilike(search_pattern)
                )
            )
            .distinct()
            .limit(limit)
        )
        return list(result.scalars().all())
    
    async def update_stock(
        self,
        product_id: UUID,
        quantity_change: int
    ) -> Optional[Product]:
        """
        Update product stock by adding quantity_change
        
        Args:
            product_id: Product ID
            quantity_change: Change in stock (positive or negative)
        
        Returns:
            Updated product or None if not found
        """
        product = await self.get(product_id)
        if product:
            product.total_stock += quantity_change
            if product.total_stock < 0:
                product.total_stock = 0
            await self.db.flush()
        return product
    
    async def update_rating(
        self,
        product_id: UUID,
        new_rating: float,
        review_increment: int = 1
    ) -> Optional[Product]:
        """
        Update product rating and review count
        
        Args:
            product_id: Product ID
            new_rating: New rating value to incorporate
            review_increment: Number of reviews to add (usually 1)
        
        Returns:
            Updated product or None if not found
        """
        product = await self.get(product_id)
        if product:
            # Calculate new average rating
            total_reviews = product.total_reviews + review_increment
            current_total = product.average_rating * product.total_reviews
            new_total = current_total + (new_rating * review_increment)
            product.average_rating = new_total / total_reviews
            product.total_reviews = total_reviews
            await self.db.flush()
        return product
    
    async def increment_sold_count(
        self,
        product_id: UUID,
        quantity: int = 1
    ) -> Optional[Product]:
        """
        Increment product sold count
        
        Args:
            product_id: Product ID
            quantity: Quantity sold
        
        Returns:
            Updated product or None if not found
        """
        product = await self.get(product_id)
        if product:
            product.sold_count += quantity
            await self.db.flush()
        return product


class ProductVariantRepository(BaseRepository[ProductVariant]):
    """Repository for product variant operations"""
    
    def __init__(self, session: AsyncSession):
        super().__init__(ProductVariant, session)
    
    async def get_by_product(
        self,
        product_id: UUID,
        active_only: bool = True
    ) -> List[ProductVariant]:
        """
        Get all variants for a product
        
        Args:
            product_id: Product ID
            active_only: If True, only return active variants
        
        Returns:
            List of product variants
        """
        conditions = [ProductVariant.product_id == product_id]
        if active_only:
            conditions.append(ProductVariant.is_active == True)
        
        result = await self.db.execute(
            select(ProductVariant)
            .where(and_(*conditions))
            .order_by(ProductVariant.created_at)
        )
        return list(result.scalars().all())
    
    async def get_by_sku(self, sku: str) -> Optional[ProductVariant]:
        """
        Get variant by SKU
        
        Args:
            sku: Product SKU
        
        Returns:
            Product variant or None
        """
        result = await self.db.execute(
            select(ProductVariant)
            .where(ProductVariant.sku == sku)
        )
        return result.scalar_one_or_none()
    
    async def update_stock(
        self,
        variant_id: UUID,
        quantity_change: int
    ) -> Optional[ProductVariant]:
        """
        Update variant stock by adding quantity_change
        
        Args:
            variant_id: Variant ID
            quantity_change: Change in stock (positive or negative)
        
        Returns:
            Updated variant or None if not found
        """
        variant = await self.get(variant_id)
        if variant:
            variant.stock += quantity_change
            if variant.stock < 0:
                variant.stock = 0
            await self.db.flush()
        return variant
