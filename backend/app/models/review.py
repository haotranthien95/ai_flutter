"""
Review models for product reviews and ratings
"""
from sqlalchemy import Column, ForeignKey, Integer, Text, Boolean, JSON, Index, UniqueConstraint, CheckConstraint
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class Review(BaseModel):
    """Review model for product reviews"""
    __tablename__ = "reviews"
    
    # Foreign keys
    product_id = Column(ForeignKey("products.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    order_id = Column(ForeignKey("orders.id", ondelete="SET NULL"), nullable=True)
    
    # Review content
    rating = Column(Integer, nullable=False)
    content = Column(Text, nullable=True)
    images = Column(JSON, nullable=True)  # Array of image URLs
    
    # Status flags
    is_verified_purchase = Column(Boolean, default=True, nullable=False)
    is_visible = Column(Boolean, default=True, nullable=False)
    
    # Relationships
    product = relationship("Product", back_populates="reviews")
    user = relationship("User", back_populates="reviews")
    order = relationship("Order")
    
    # Constraints
    __table_args__ = (
        UniqueConstraint("user_id", "product_id", name="uq_user_product_review"),
        CheckConstraint("rating >= 1 AND rating <= 5", name="ck_rating_range"),
        Index("ix_reviews_product_rating", "product_id", "rating"),
        Index("ix_reviews_product_visible", "product_id", "is_visible"),
    )
    
    def __repr__(self):
        return f"<Review {self.id} - Product {self.product_id} by User {self.user_id}: {self.rating}★>"
