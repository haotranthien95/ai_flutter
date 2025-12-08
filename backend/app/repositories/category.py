"""
Category repository for database operations
"""
from typing import List, Optional
from uuid import UUID

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.category import Category
from app.repositories.base import BaseRepository


class CategoryRepository(BaseRepository[Category]):
    """Repository for category operations"""
    
    def __init__(self, session: AsyncSession):
        super().__init__(Category, session)
    
    async def get_root_categories(
        self, 
        active_only: bool = True
    ) -> List[Category]:
        """
        Get all root categories (categories without parent)
        
        Args:
            active_only: If True, only return active categories
        
        Returns:
            List of root categories
        """
        conditions = [Category.parent_id.is_(None)]
        if active_only:
            conditions.append(Category.is_active == True)
        
        result = await self.db.execute(
            select(Category)
            .where(and_(*conditions))
            .order_by(Category.sort_order, Category.name)
        )
        return list(result.scalars().all())
    
    async def get_subcategories(
        self, 
        parent_id: UUID,
        active_only: bool = True
    ) -> List[Category]:
        """
        Get all subcategories of a parent category
        
        Args:
            parent_id: Parent category ID
            active_only: If True, only return active categories
        
        Returns:
            List of subcategories
        """
        conditions = [Category.parent_id == parent_id]
        if active_only:
            conditions.append(Category.is_active == True)
        
        result = await self.db.execute(
            select(Category)
            .where(and_(*conditions))
            .order_by(Category.sort_order, Category.name)
        )
        return list(result.scalars().all())
    
    async def get_with_subcategories(
        self, 
        category_id: UUID
    ) -> Optional[Category]:
        """
        Get category with all its subcategories loaded
        
        Args:
            category_id: Category ID
        
        Returns:
            Category with subcategories or None
        """
        result = await self.db.execute(
            select(Category)
            .where(Category.id == category_id)
            .options(selectinload(Category.subcategories))
        )
        return result.scalar_one_or_none()
    
    async def get_all_active(self) -> List[Category]:
        """
        Get all active categories
        
        Returns:
            List of all active categories
        """
        result = await self.db.execute(
            select(Category)
            .where(Category.is_active == True)
            .order_by(Category.level, Category.sort_order, Category.name)
        )
        return list(result.scalars().all())
    
    async def get_category_tree(
        self,
        parent_id: Optional[UUID] = None,
        active_only: bool = True
    ) -> List[Category]:
        """
        Get hierarchical category tree
        
        Args:
            parent_id: Start from this parent (None for roots)
            active_only: If True, only return active categories
        
        Returns:
            List of categories with subcategories loaded recursively
        """
        conditions = []
        if parent_id is None:
            conditions.append(Category.parent_id.is_(None))
        else:
            conditions.append(Category.parent_id == parent_id)
        
        if active_only:
            conditions.append(Category.is_active == True)
        
        result = await self.db.execute(
            select(Category)
            .where(and_(*conditions))
            .options(selectinload(Category.subcategories))
            .order_by(Category.sort_order, Category.name)
        )
        categories = list(result.scalars().all())
        
        # Recursively load subcategories
        for category in categories:
            if category.subcategories:
                for subcategory in category.subcategories:
                    subcategory.subcategories = await self.get_category_tree(
                        parent_id=subcategory.id,
                        active_only=active_only
                    )
        
        return categories
    
    async def exists_by_name(
        self, 
        name: str, 
        parent_id: Optional[UUID] = None,
        exclude_id: Optional[UUID] = None
    ) -> bool:
        """
        Check if category with name exists under parent
        
        Args:
            name: Category name to check
            parent_id: Parent category ID (None for root level)
            exclude_id: Exclude this category ID from check (for updates)
        
        Returns:
            True if category exists, False otherwise
        """
        conditions = [Category.name == name]
        
        if parent_id is None:
            conditions.append(Category.parent_id.is_(None))
        else:
            conditions.append(Category.parent_id == parent_id)
        
        if exclude_id is not None:
            conditions.append(Category.id != exclude_id)
        
        result = await self.db.execute(
            select(Category.id)
            .where(and_(*conditions))
            .limit(1)
        )
        return result.scalar_one_or_none() is not None
