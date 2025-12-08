"""
Address model
"""
from datetime import datetime
from uuid import uuid4

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.models.base import Base


class Address(Base):
    """Address model for user delivery addresses"""
    
    __tablename__ = "addresses"
    
    # Primary Key
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4, index=True)
    
    # Foreign Key
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Address Information
    recipient_name = Column(String(255), nullable=False)
    phone_number = Column(String(20), nullable=False)
    street_address = Column(Text, nullable=False)
    ward = Column(String(100), nullable=False)
    district = Column(String(100), nullable=False)
    city = Column(String(100), nullable=False)
    
    # Flags
    is_default = Column(Boolean, default=False, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    user = relationship("User", back_populates="addresses")
    
    def __repr__(self):
        return f"<Address {self.id}: {self.recipient_name} in {self.city}>"
    
    @property
    def full_address(self) -> str:
        """Get formatted full address"""
        return f"{self.street_address}, {self.ward}, {self.district}, {self.city}"
