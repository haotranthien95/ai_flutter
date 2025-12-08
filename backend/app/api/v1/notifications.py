"""
Notification API routes.
"""
from typing import Optional
from uuid import UUID
from fastapi import APIRouter, Depends, Query
from app.dependencies import get_current_user, get_notification_service
from app.models.user import User
from app.models.notification import NotificationType
from app.services.notification import NotificationService
from app.schemas.notification import (
    NotificationListResponse,
    NotificationUnreadCountResponse,
    MarkAsReadRequest,
)

router = APIRouter()


@router.get("", response_model=NotificationListResponse)
async def get_notifications(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    is_read: Optional[bool] = Query(None, description="Filter by read status"),
    notification_type: Optional[NotificationType] = Query(None, description="Filter by notification type"),
    current_user: User = Depends(get_current_user),
    notification_service: NotificationService = Depends(get_notification_service),
):
    """
    Get notifications for the current user.
    
    - **page**: Page number (default: 1)
    - **page_size**: Items per page (default: 20, max: 100)
    - **is_read**: Filter by read status (optional)
    - **notification_type**: Filter by notification type (optional)
    """
    return await notification_service.get_user_notifications(
        user_id=current_user.id,
        page=page,
        page_size=page_size,
        is_read=is_read,
        notification_type=notification_type,
    )


@router.get("/unread-count", response_model=NotificationUnreadCountResponse)
async def get_unread_count(
    current_user: User = Depends(get_current_user),
    notification_service: NotificationService = Depends(get_notification_service),
):
    """
    Get unread notification count for the current user.
    """
    return await notification_service.get_unread_count(current_user.id)


@router.patch("/{notification_id}/read")
async def mark_notification_as_read(
    notification_id: UUID,
    current_user: User = Depends(get_current_user),
    notification_service: NotificationService = Depends(get_notification_service),
):
    """
    Mark a specific notification as read.
    """
    await notification_service.mark_as_read(current_user.id, notification_id)
    return {"message": "Notification marked as read"}


@router.post("/mark-all-read")
async def mark_all_notifications_as_read(
    current_user: User = Depends(get_current_user),
    notification_service: NotificationService = Depends(get_notification_service),
):
    """
    Mark all notifications as read for the current user.
    """
    count = await notification_service.mark_all_as_read(current_user.id)
    return {"message": f"Marked {count} notifications as read"}


@router.post("/mark-read")
async def mark_multiple_as_read(
    request: MarkAsReadRequest,
    current_user: User = Depends(get_current_user),
    notification_service: NotificationService = Depends(get_notification_service),
):
    """
    Mark multiple notifications as read.
    
    If notification_ids is empty or not provided, marks all as read.
    """
    if not request.notification_ids:
        count = await notification_service.mark_all_as_read(current_user.id)
    else:
        count = await notification_service.mark_multiple_as_read(
            current_user.id, 
            request.notification_ids
        )
    
    return {"message": f"Marked {count} notifications as read"}


@router.delete("/{notification_id}")
async def delete_notification(
    notification_id: UUID,
    current_user: User = Depends(get_current_user),
    notification_service: NotificationService = Depends(get_notification_service),
):
    """
    Delete a specific notification.
    """
    await notification_service.delete_notification(current_user.id, notification_id)
    return {"message": "Notification deleted"}
