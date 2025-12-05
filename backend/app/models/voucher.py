"""
Voucher models for discount system
"""
from enum import Enum as PyEnum
from datetime import datetime
from decimal import Decimal
from sqlalchemy import Column, String, Text, Enum, ForeignKey, Integer, DECIMAL, DateTime, Boolean, Index
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class VoucherType(str, PyEnum):
    """Voucher type enum"""
    PERCENTAGE = "percentage"
    FIXED_AMOUNT = "fixed_amount"


class Voucher(BaseModel):
    """Voucher model for shop discounts"""
    __tablename__ = "vouchers"
    
    # Shop relationship
    shop_id = Column(ForeignKey("shops.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Voucher identification
    code = Column(String(50), unique=True, nullable=False, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    
    # Discount configuration
    type = Column(Enum(VoucherType), nullable=False)
    value = Column(DECIMAL(15, 2), nullable=False)  # Percentage (0-100) or fixed amount
    
    # Conditions
    min_order_value = Column(DECIMAL(15, 2), nullable=True)  # Minimum order value to apply
    max_discount = Column(DECIMAL(15, 2), nullable=True)  # Maximum discount for percentage type
    
    # Usage tracking
    usage_limit = Column(Integer, nullable=True)  # Total usage limit (null = unlimited)
    usage_count = Column(Integer, default=0, nullable=False)
    
    # Validity period
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=False)
    
    # Status
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Relationships
    shop = relationship("Shop", back_populates="vouchers")
    
    # Indexes
    __table_args__ = (
        Index("ix_vouchers_shop_active", "shop_id", "is_active"),
        Index("ix_vouchers_code_active", "code", "is_active"),
    )
    
    def __repr__(self):
        return f"<Voucher {self.code} - {self.type.value}>"
    
    def is_valid(self) -> bool:
        """Check if voucher is currently valid"""
        now = datetime.utcnow()
        return (
            self.is_active
            and self.start_date <= now <= self.end_date
            and (self.usage_limit is None or self.usage_count < self.usage_limit)
        )
    
    def can_apply_to_order(self, subtotal: Decimal) -> bool:
        """Check if voucher can be applied to order with given subtotal"""
        if not self.is_valid():
            return False
        
        if self.min_order_value and subtotal < self.min_order_value:
            return False
        
        return True
    
    def calculate_discount(self, subtotal: Decimal) -> Decimal:
        """Calculate discount amount for given subtotal"""
        if not self.can_apply_to_order(subtotal):
            return Decimal('0')
        
        if self.type == VoucherType.PERCENTAGE:
            discount = (subtotal * self.value) / Decimal('100')
            
            # Apply max discount cap if set
            if self.max_discount and discount > self.max_discount:
                discount = self.max_discount
            
            return discount
        else:  # FIXED_AMOUNT
            # Don't discount more than the subtotal
            return min(self.value, subtotal)
