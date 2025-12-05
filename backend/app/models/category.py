"""
Category model for product categorization
"""
from sqlalchemy import Column, String, Integer, Boolean, ForeignKey, Index
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID

from app.models.base import BaseModel


class Category(BaseModel):
    """Category model for hierarchical product categorization"""
    __tablename__ = "categories"
    
    name = Column(String(255), nullable=False, index=True)
    icon_url = Column(String(500), nullable=True)
    parent_id = Column(UUID(as_uuid=True), ForeignKey("categories.id", ondelete="CASCADE"), nullable=True, index=True)
    level = Column(Integer, default=0, nullable=False)
    sort_order = Column(Integer, default=0, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False, index=True)
    
    # Self-referential relationship
    parent = relationship("Category", remote_side="Category.id", back_populates="subcategories")
    subcategories = relationship("Category", back_populates="parent", cascade="all, delete-orphan")
    
    # Relationship to products (will be defined in Product model)
    # products = relationship("Product", back_populates="category")
    
    def __repr__(self):
        return f"<Category {self.name} (level={self.level})>"


# Create composite indexes
Index('idx_category_parent_active', Category.parent_id, Category.is_active)
Index('idx_category_level_sort', Category.level, Category.sort_order)
