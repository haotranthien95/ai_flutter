"""
Category service for business logic
"""
from typing import List, Optional
from uuid import UUID

from fastapi import HTTPException, status

from app.models.category import Category
from app.repositories.category import CategoryRepository
from app.schemas.category import CategoryCreate, CategoryUpdate


class CategoryService:
    """Service for category business logic"""
    
    def __init__(self, category_repo: CategoryRepository):
        self.category_repo = category_repo
    
    async def create_category(
        self,
        category_data: CategoryCreate
    ) -> Category:
        """
        Create a new category
        
        Args:
            category_data: Category creation data
        
        Returns:
            Created category
        
        Raises:
            HTTPException: If parent not found or category name exists
        """
        # Validate parent exists if parent_id provided
        if category_data.parent_id:
            parent = await self.category_repo.get(category_data.parent_id)
            if not parent:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Parent category not found"
                )
            if not parent.is_active:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Cannot create subcategory under inactive parent"
                )
            level = parent.level + 1
        else:
            level = 0
        
        # Check if category with same name exists under parent
        exists = await self.category_repo.exists_by_name(
            name=category_data.name,
            parent_id=category_data.parent_id
        )
        if exists:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Category with this name already exists under parent"
            )
        
        # Create category
        category = Category(
            **category_data.model_dump(),
            level=level
        )
        return await self.category_repo.create(category)
    
    async def get_category(self, category_id: UUID) -> Category:
        """
        Get category by ID
        
        Args:
            category_id: Category ID
        
        Returns:
            Category
        
        Raises:
            HTTPException: If category not found
        """
        category = await self.category_repo.get(category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found"
            )
        return category
    
    async def get_category_with_subcategories(
        self,
        category_id: UUID
    ) -> Category:
        """
        Get category with all its subcategories
        
        Args:
            category_id: Category ID
        
        Returns:
            Category with subcategories
        
        Raises:
            HTTPException: If category not found
        """
        category = await self.category_repo.get_with_subcategories(category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found"
            )
        return category
    
    async def list_root_categories(
        self,
        active_only: bool = True
    ) -> List[Category]:
        """
        List all root categories
        
        Args:
            active_only: If True, only return active categories
        
        Returns:
            List of root categories
        """
        return await self.category_repo.get_root_categories(active_only)
    
    async def list_subcategories(
        self,
        parent_id: UUID,
        active_only: bool = True
    ) -> List[Category]:
        """
        List subcategories of a parent
        
        Args:
            parent_id: Parent category ID
            active_only: If True, only return active categories
        
        Returns:
            List of subcategories
        
        Raises:
            HTTPException: If parent not found
        """
        # Verify parent exists
        parent = await self.category_repo.get(parent_id)
        if not parent:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Parent category not found"
            )
        
        return await self.category_repo.get_subcategories(parent_id, active_only)
    
    async def list_all_categories(self) -> List[Category]:
        """
        List all active categories
        
        Returns:
            List of all active categories
        """
        return await self.category_repo.get_all_active()
    
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
        if parent_id:
            # Verify parent exists
            parent = await self.category_repo.get(parent_id)
            if not parent:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Parent category not found"
                )
        
        return await self.category_repo.get_category_tree(parent_id, active_only)
    
    async def update_category(
        self,
        category_id: UUID,
        category_data: CategoryUpdate
    ) -> Category:
        """
        Update category
        
        Args:
            category_id: Category ID
            category_data: Category update data
        
        Returns:
            Updated category
        
        Raises:
            HTTPException: If category not found or validation fails
        """
        category = await self.category_repo.get(category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found"
            )
        
        # Validate parent_id if being updated
        if category_data.parent_id is not None:
            if category_data.parent_id == category_id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Category cannot be its own parent"
                )
            
            if category_data.parent_id:
                parent = await self.category_repo.get(category_data.parent_id)
                if not parent:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail="Parent category not found"
                    )
                
                # Check for circular reference
                if await self._is_descendant(category_id, category_data.parent_id):
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Cannot set descendant as parent (circular reference)"
                    )
                
                # Update level
                category.level = parent.level + 1
            else:
                # Moving to root level
                category.level = 0
        
        # Check name uniqueness if name is being updated
        if category_data.name is not None:
            parent_id = category_data.parent_id if category_data.parent_id is not None else category.parent_id
            exists = await self.category_repo.exists_by_name(
                name=category_data.name,
                parent_id=parent_id,
                exclude_id=category_id
            )
            if exists:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Category with this name already exists under parent"
                )
        
        # Update category
        update_data = category_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(category, field, value)
        
        return await self.category_repo.update(category)
    
    async def delete_category(self, category_id: UUID) -> None:
        """
        Delete category (will cascade to subcategories)
        
        Args:
            category_id: Category ID
        
        Raises:
            HTTPException: If category not found
        """
        category = await self.category_repo.get(category_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found"
            )
        
        await self.category_repo.delete(category_id)
    
    async def _is_descendant(
        self,
        ancestor_id: UUID,
        potential_descendant_id: UUID
    ) -> bool:
        """
        Check if potential_descendant is a descendant of ancestor
        
        Args:
            ancestor_id: Potential ancestor category ID
            potential_descendant_id: Potential descendant category ID
        
        Returns:
            True if potential_descendant is a descendant of ancestor
        """
        current = await self.category_repo.get(potential_descendant_id)
        while current and current.parent_id:
            if current.parent_id == ancestor_id:
                return True
            current = await self.category_repo.get(current.parent_id)
        return False
