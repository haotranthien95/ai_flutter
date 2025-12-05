"""
Order models for e-commerce system
"""
from enum import Enum as PyEnum
from datetime import datetime
from decimal import Decimal
from sqlalchemy import Column, String, Text, Enum, ForeignKey, Integer, Index, DECIMAL, DateTime, JSON
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class OrderStatus(str, PyEnum):
    """Order status enum"""
    PENDING = "pending"
    CONFIRMED = "confirmed"
    PACKED = "packed"
    SHIPPING = "shipping"
    DELIVERED = "delivered"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class PaymentMethod(str, PyEnum):
    """Payment method enum"""
    COD = "cod"  # Cash on Delivery
    BANK_TRANSFER = "bank_transfer"
    E_WALLET = "e_wallet"


class PaymentStatus(str, PyEnum):
    """Payment status enum"""
    PENDING = "pending"
    PAID = "paid"
    FAILED = "failed"
    REFUNDED = "refunded"


class Order(BaseModel):
    """Order model - one order per shop"""
    __tablename__ = "orders"
    
    # Order identification
    order_number = Column(String(50), unique=True, nullable=False, index=True)
    
    # Relationships
    buyer_id = Column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    shop_id = Column(ForeignKey("shops.id", ondelete="CASCADE"), nullable=False, index=True)
    address_id = Column(ForeignKey("addresses.id", ondelete="SET NULL"), nullable=True)
    
    # Address snapshot (immutable copy)
    shipping_address = Column(JSON, nullable=False)
    
    # Status
    status = Column(Enum(OrderStatus), default=OrderStatus.PENDING, nullable=False, index=True)
    payment_method = Column(Enum(PaymentMethod), nullable=False)
    payment_status = Column(Enum(PaymentStatus), default=PaymentStatus.PENDING, nullable=False)
    
    # Pricing
    subtotal = Column(DECIMAL(15, 2), nullable=False)
    shipping_fee = Column(DECIMAL(15, 2), default=Decimal('0'), nullable=False)
    discount = Column(DECIMAL(15, 2), default=Decimal('0'), nullable=False)
    total = Column(DECIMAL(15, 2), nullable=False)
    currency = Column(String(3), default="VND", nullable=False)
    
    # Optional fields
    voucher_code = Column(String(50), nullable=True)
    notes = Column(Text, nullable=True)
    cancellation_reason = Column(Text, nullable=True)
    
    # Timestamps
    completed_at = Column(DateTime, nullable=True)
    
    # Relationships
    buyer = relationship("User", foreign_keys=[buyer_id], back_populates="orders")
    shop = relationship("Shop", back_populates="orders")
    address = relationship("Address")
    items = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")
    
    # Indexes
    __table_args__ = (
        Index("ix_orders_buyer_status", "buyer_id", "status"),
        Index("ix_orders_shop_status", "shop_id", "status"),
    )
    
    def __repr__(self):
        return f"<Order {self.order_number} - {self.status}>"


class OrderItem(BaseModel):
    """Order item model - products in an order"""
    __tablename__ = "order_items"
    
    # Relationships
    order_id = Column(ForeignKey("orders.id", ondelete="CASCADE"), nullable=False, index=True)
    product_id = Column(ForeignKey("products.id", ondelete="SET NULL"), nullable=True)
    variant_id = Column(ForeignKey("product_variants.id", ondelete="SET NULL"), nullable=True)
    
    # Product snapshots (immutable copy at time of order)
    product_snapshot = Column(JSON, nullable=False)
    variant_snapshot = Column(JSON, nullable=True)
    
    # Quantity and pricing
    quantity = Column(Integer, nullable=False, default=1)
    unit_price = Column(DECIMAL(15, 2), nullable=False)
    subtotal = Column(DECIMAL(15, 2), nullable=False)
    currency = Column(String(3), default="VND", nullable=False)
    
    # Relationships
    order = relationship("Order", back_populates="items")
    product = relationship("Product")
    variant = relationship("ProductVariant")
    
    def __repr__(self):
        return f"<OrderItem {self.id} - Qty: {self.quantity}>"
