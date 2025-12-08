"""
Notification schemas for request/response validation.
"""
from datetime import datetime
from typing import Optional, Any, Dict
from uuid import UUID
from pydantic import BaseModel, Field, ConfigDict
from app.models.notification import NotificationType


class NotificationBase(BaseModel):
    """Base notification schema."""
    type: NotificationType
    title: str = Field(..., min_length=1, max_length=255)
    message: str = Field(..., min_length=1)
    data: Optional[Dict[str, Any]] = None
    related_entity_type: Optional[str] = Field(None, max_length=50)
    related_entity_id: Optional[UUID] = None


class NotificationCreate(NotificationBase):
    """Schema for creating a notification."""
    user_id: UUID


class NotificationResponse(NotificationBase):
    """Schema for notification response."""
    id: UUID
    user_id: UUID
    is_read: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class NotificationListResponse(BaseModel):
    """Schema for paginated notification list response."""
    items: list[NotificationResponse]
    total: int
    page: int
    page_size: int
    unread_count: int


class NotificationUnreadCountResponse(BaseModel):
    """Schema for unread notification count response."""
    unread_count: int


class MarkAsReadRequest(BaseModel):
    """Schema for marking notification(s) as read."""
    notification_ids: Optional[list[UUID]] = Field(
        None, 
        description="List of notification IDs to mark as read. If empty, marks all as read."
    )


class NotificationPreferences(BaseModel):
    """Schema for user notification preferences."""
    order_updates: bool = True
    messages: bool = True
    promotions: bool = True
    system: bool = True

    model_config = ConfigDict(from_attributes=True)
