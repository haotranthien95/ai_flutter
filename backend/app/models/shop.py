"""
Shop model
"""
from sqlalchemy import Column, String, Text, Float, Integer, Numeric, Enum as SQLEnum, ForeignKey, Index
from sqlalchemy.orm import relationship
import enum

from app.models.base import BaseModel


class ShopStatus(enum.Enum):
    """Shop status enum"""
    PENDING = "pending"
    ACTIVE = "active"
    SUSPENDED = "suspended"


class Shop(BaseModel):
    """Shop model for seller stores"""
    __tablename__ = "shops"
    
    owner_id = Column(ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    shop_name = Column(String(255), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    logo_url = Column(String(500), nullable=True)
    cover_image_url = Column(String(500), nullable=True)
    business_address = Column(Text, nullable=True)
    rating = Column(Float, default=0.0, nullable=False)
    total_ratings = Column(Integer, default=0, nullable=False)
    follower_count = Column(Integer, default=0, nullable=False)
    status = Column(SQLEnum(ShopStatus), default=ShopStatus.PENDING, nullable=False, index=True)
    shipping_fee = Column(Numeric(10, 2), nullable=False, default=0)
    free_shipping_threshold = Column(Numeric(10, 2), nullable=True)
    
    # Relationships
    owner = relationship("User", back_populates="shop")
    orders = relationship("Order", back_populates="shop")
    vouchers = relationship("Voucher", back_populates="shop", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Shop {self.shop_name}: {self.status.value}>"
