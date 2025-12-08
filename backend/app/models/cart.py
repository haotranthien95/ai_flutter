"""
Cart models for shopping cart functionality
"""
from sqlalchemy import Column, String, Integer, ForeignKey, UniqueConstraint, Index
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID

from app.models.base import BaseModel


class CartItem(BaseModel):
    """
    Cart item model representing products in user's shopping cart
    """
    __tablename__ = "cart_items"
    
    # Foreign keys
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), nullable=False)
    variant_id = Column(UUID(as_uuid=True), ForeignKey("product_variants.id", ondelete="CASCADE"), nullable=True)
    
    # Cart item data
    quantity = Column(Integer, nullable=False, default=1)
    
    # Relationships
    user = relationship("User", back_populates="cart_items")
    product = relationship("Product")
    variant = relationship("ProductVariant")
    
    # Unique constraint: one item per user-product-variant combination
    __table_args__ = (
        UniqueConstraint('user_id', 'product_id', 'variant_id', name='uq_cart_user_product_variant'),
        Index('ix_cart_items_user_id', 'user_id'),
    )
