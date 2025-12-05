"""
Product and ProductVariant models
"""
from sqlalchemy import Column, String, Text, Integer, Float, Boolean, ForeignKey, Index, Numeric, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID, JSON
import enum

from app.models.base import BaseModel


class ProductCondition(enum.Enum):
    """Product condition enum"""
    NEW = "new"
    USED = "used"
    REFURBISHED = "refurbished"


class Product(BaseModel):
    """Product model for items sold in shops"""
    __tablename__ = "products"
    
    shop_id = Column(UUID(as_uuid=True), ForeignKey("shops.id", ondelete="CASCADE"), nullable=False, index=True)
    category_id = Column(UUID(as_uuid=True), ForeignKey("categories.id", ondelete="SET NULL"), nullable=True, index=True)
    
    title = Column(String(500), nullable=False, index=True)
    description = Column(Text, nullable=True)
    base_price = Column(Numeric(15, 2), nullable=False)
    currency = Column(String(3), default="VND", nullable=False)
    total_stock = Column(Integer, default=0, nullable=False)
    images = Column(JSON, nullable=True, default=list)  # Array of image URLs
    condition = Column(SQLEnum(ProductCondition), default=ProductCondition.NEW, nullable=False)
    
    # Statistics
    average_rating = Column(Float, default=0.0, nullable=False)
    total_reviews = Column(Integer, default=0, nullable=False)
    sold_count = Column(Integer, default=0, nullable=False, index=True)
    
    # Status
    is_active = Column(Boolean, default=True, nullable=False, index=True)
    
    # Relationships
    shop = relationship("Shop", backref="products")
    category = relationship("Category", backref="products")
    variants = relationship("ProductVariant", back_populates="product", cascade="all, delete-orphan")
    # cart_items = relationship("CartItem", back_populates="product", cascade="all, delete-orphan")
    # order_items = relationship("OrderItem", back_populates="product")
    # reviews = relationship("Review", back_populates="product", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<Product {self.title} (shop_id={self.shop_id})>"


class ProductVariant(BaseModel):
    """Product variant model for different options of a product"""
    __tablename__ = "product_variants"
    
    product_id = Column(UUID(as_uuid=True), ForeignKey("products.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    attributes = Column(JSON, nullable=True, default=dict)  # e.g., {"color": "red", "size": "L"}
    sku = Column(String(100), unique=True, nullable=True, index=True)
    price = Column(Numeric(15, 2), nullable=False)
    stock = Column(Integer, default=0, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Relationships
    product = relationship("Product", back_populates="variants")
    # cart_items = relationship("CartItem", back_populates="variant")
    # order_items = relationship("OrderItem", back_populates="variant")
    
    def __repr__(self):
        return f"<ProductVariant {self.name} of product {self.product_id}>"


# Create composite indexes for Product
Index('idx_product_shop_active', Product.shop_id, Product.is_active)
Index('idx_product_category_active', Product.category_id, Product.is_active)
Index('idx_product_rating_sold', Product.average_rating, Product.sold_count)
Index('idx_product_active_rating', Product.is_active, Product.average_rating)

# Create composite indexes for ProductVariant
Index('idx_variant_product_active', ProductVariant.product_id, ProductVariant.is_active)
