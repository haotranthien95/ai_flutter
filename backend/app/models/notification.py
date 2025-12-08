"""
Notification model for the e-commerce application.
"""
import enum
from typing import Optional
from sqlalchemy import Column, String, Text, Boolean, ForeignKey, Enum as SQLEnum, Index
from sqlalchemy.dialects.postgresql import UUID, JSON
from sqlalchemy.orm import relationship
from app.models.base import BaseModel


class NotificationType(str, enum.Enum):
    """Notification type enumeration."""
    ORDER_UPDATE = "ORDER_UPDATE"
    MESSAGE = "MESSAGE"
    PROMOTION = "PROMOTION"
    SYSTEM = "SYSTEM"


class Notification(BaseModel):
    """Notification model."""
    __tablename__ = "notifications"

    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    type = Column(SQLEnum(NotificationType), nullable=False)
    title = Column(String(255), nullable=False)
    message = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False, nullable=False, index=True)
    data = Column(JSON, nullable=True)  # Additional metadata (order_id, shop_id, etc.)
    
    # Optional: Link to related entity
    related_entity_type = Column(String(50), nullable=True)  # e.g., "order", "product", "shop"
    related_entity_id = Column(UUID(as_uuid=True), nullable=True)

    # Relationships
    user = relationship("User", back_populates="notifications")

    # Create composite index for common queries
    __table_args__ = (
        Index("ix_notifications_user_read_created", "user_id", "is_read", "created_at"),
    )

    def __repr__(self) -> str:
        return f"<Notification(id={self.id}, user_id={self.user_id}, type={self.type}, is_read={self.is_read})>"
