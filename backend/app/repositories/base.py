"""
Base repository with generic CRUD operations
"""
from typing import Generic, TypeVar, Type, Optional, List
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.base import BaseModel

ModelType = TypeVar("ModelType", bound=BaseModel)


class BaseRepository(Generic[ModelType]):
    """
    Base repository with generic CRUD operations
    
    This class provides common database operations that can be reused
    across all repositories.
    """
    
    def __init__(self, model: Type[ModelType], db: AsyncSession):
        """
        Initialize repository
        
        Args:
            model: SQLAlchemy model class
            db: Database session
        """
        self.model = model
        self.db = db
    
    async def get_by_id(self, id: UUID) -> Optional[ModelType]:
        """
        Get a record by ID
        
        Args:
            id: Record UUID
            
        Returns:
            Model instance or None if not found
        """
        result = await self.db.execute(
            select(self.model).where(self.model.id == id)
        )
        return result.scalar_one_or_none()
    
    async def get_all(self, skip: int = 0, limit: int = 100) -> List[ModelType]:
        """
        Get all records with pagination
        
        Args:
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List of model instances
        """
        result = await self.db.execute(
            select(self.model).offset(skip).limit(limit)
        )
        return list(result.scalars().all())
    
    async def create(self, obj: ModelType) -> ModelType:
        """
        Create a new record
        
        Args:
            obj: Model instance to create
            
        Returns:
            Created model instance
        """
        self.db.add(obj)
        await self.db.flush()
        await self.db.refresh(obj)
        return obj
    
    async def update(self, obj: ModelType) -> ModelType:
        """
        Update an existing record
        
        Args:
            obj: Model instance to update
            
        Returns:
            Updated model instance
        """
        await self.db.flush()
        await self.db.refresh(obj)
        return obj
    
    async def delete(self, obj: ModelType) -> None:
        """
        Delete a record
        
        Args:
            obj: Model instance to delete
        """
        await self.db.delete(obj)
        await self.db.flush()
    
    async def delete_by_id(self, id: UUID) -> bool:
        """
        Delete a record by ID
        
        Args:
            id: Record UUID
            
        Returns:
            True if deleted, False if not found
        """
        obj = await self.get_by_id(id)
        if obj:
            await self.delete(obj)
            return True
        return False
    
    async def exists(self, id: UUID) -> bool:
        """
        Check if a record exists
        
        Args:
            id: Record UUID
            
        Returns:
            True if exists, False otherwise
        """
        result = await self.db.execute(
            select(self.model.id).where(self.model.id == id)
        )
        return result.scalar_one_or_none() is not None
    
    async def count(self) -> int:
        """
        Count total records
        
        Returns:
            Total number of records
        """
        from sqlalchemy import func
        result = await self.db.execute(
            select(func.count()).select_from(self.model)
        )
        return result.scalar_one()
