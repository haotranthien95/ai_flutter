"""
Notification service for business logic.
"""
from typing import Optional, Any, Dict
from uuid import UUID
from fastapi import HTTPException, status
from app.models.notification import Notification, NotificationType
from app.repositories.notification import NotificationRepository
from app.schemas.notification import (
    NotificationCreate,
    NotificationResponse,
    NotificationListResponse,
    NotificationUnreadCountResponse,
)


class NotificationService:
    """Service for notification business logic."""

    def __init__(self, notification_repo: NotificationRepository):
        self.notification_repo = notification_repo

    async def create_notification(
        self,
        user_id: UUID,
        notification_type: NotificationType,
        title: str,
        message: str,
        data: Optional[Dict[str, Any]] = None,
        related_entity_type: Optional[str] = None,
        related_entity_id: Optional[UUID] = None,
    ) -> NotificationResponse:
        """
        Create a new notification for a user.
        
        Args:
            user_id: User's UUID
            notification_type: Type of notification
            title: Notification title
            message: Notification message
            data: Additional metadata
            related_entity_type: Type of related entity (e.g., "order", "product")
            related_entity_id: UUID of related entity
            
        Returns:
            Created notification
        """
        notification_data = NotificationCreate(
            user_id=user_id,
            type=notification_type,
            title=title,
            message=message,
            data=data,
            related_entity_type=related_entity_type,
            related_entity_id=related_entity_id,
        )
        
        notification = Notification(**notification_data.model_dump())
        created = await self.notification_repo.create(notification)
        
        return NotificationResponse.model_validate(created)

    async def get_user_notifications(
        self,
        user_id: UUID,
        page: int = 1,
        page_size: int = 20,
        is_read: Optional[bool] = None,
        notification_type: Optional[NotificationType] = None,
    ) -> NotificationListResponse:
        """
        Get paginated notifications for a user.
        
        Args:
            user_id: User's UUID
            page: Page number (1-indexed)
            page_size: Items per page
            is_read: Filter by read status
            notification_type: Filter by notification type
            
        Returns:
            Paginated notification list with unread count
        """
        skip = (page - 1) * page_size
        
        notifications = await self.notification_repo.list_by_user(
            user_id=user_id,
            skip=skip,
            limit=page_size,
            is_read=is_read,
            notification_type=notification_type,
        )
        
        total = await self.notification_repo.count_by_user(
            user_id=user_id,
            is_read=is_read,
            notification_type=notification_type,
        )
        
        unread_count = await self.notification_repo.get_unread_count(user_id)
        
        return NotificationListResponse(
            items=[NotificationResponse.model_validate(n) for n in notifications],
            total=total,
            page=page,
            page_size=page_size,
            unread_count=unread_count,
        )

    async def get_unread_count(self, user_id: UUID) -> NotificationUnreadCountResponse:
        """
        Get unread notification count for a user.
        
        Args:
            user_id: User's UUID
            
        Returns:
            Unread notification count
        """
        count = await self.notification_repo.get_unread_count(user_id)
        return NotificationUnreadCountResponse(unread_count=count)

    async def mark_as_read(self, user_id: UUID, notification_id: UUID) -> None:
        """
        Mark a notification as read.
        
        Args:
            user_id: User's UUID
            notification_id: Notification's UUID
            
        Raises:
            HTTPException: If notification not found or user not authorized
        """
        updated = await self.notification_repo.mark_as_read(notification_id, user_id)
        
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notification not found or you don't have permission to access it"
            )

    async def mark_all_as_read(self, user_id: UUID) -> int:
        """
        Mark all notifications as read for a user.
        
        Args:
            user_id: User's UUID
            
        Returns:
            Number of notifications marked as read
        """
        return await self.notification_repo.mark_all_as_read(user_id)

    async def mark_multiple_as_read(self, user_id: UUID, notification_ids: list[UUID]) -> int:
        """
        Mark multiple notifications as read.
        
        Args:
            user_id: User's UUID
            notification_ids: List of notification UUIDs
            
        Returns:
            Number of notifications marked as read
        """
        return await self.notification_repo.mark_multiple_as_read(notification_ids, user_id)

    async def delete_notification(self, user_id: UUID, notification_id: UUID) -> None:
        """
        Delete a notification.
        
        Args:
            user_id: User's UUID
            notification_id: Notification's UUID
            
        Raises:
            HTTPException: If notification not found or user not authorized
        """
        notification = await self.notification_repo.get(notification_id)
        
        if not notification:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Notification not found"
            )
        
        if notification.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to delete this notification"
            )
        
        await self.notification_repo.delete(notification_id)

    # Helper methods for creating specific notification types

    async def notify_order_update(
        self,
        user_id: UUID,
        order_id: UUID,
        order_status: str,
        order_code: str,
    ) -> NotificationResponse:
        """
        Create an order update notification.
        
        Args:
            user_id: User's UUID
            order_id: Order's UUID
            order_status: New order status
            order_code: Order code for display
            
        Returns:
            Created notification
        """
        title = f"Order {order_code} Updated"
        message = f"Your order has been updated to: {order_status}"
        
        return await self.create_notification(
            user_id=user_id,
            notification_type=NotificationType.ORDER_UPDATE,
            title=title,
            message=message,
            data={"order_id": str(order_id), "status": order_status},
            related_entity_type="order",
            related_entity_id=order_id,
        )

    async def notify_message(
        self,
        user_id: UUID,
        sender_name: str,
        message_preview: str,
        shop_id: Optional[UUID] = None,
    ) -> NotificationResponse:
        """
        Create a message notification.
        
        Args:
            user_id: User's UUID
            sender_name: Name of message sender
            message_preview: Preview of the message
            shop_id: Shop UUID if from a shop
            
        Returns:
            Created notification
        """
        title = f"New message from {sender_name}"
        message = message_preview[:100]  # Truncate preview
        
        data = {"sender_name": sender_name}
        if shop_id:
            data["shop_id"] = str(shop_id)
        
        return await self.create_notification(
            user_id=user_id,
            notification_type=NotificationType.MESSAGE,
            title=title,
            message=message,
            data=data,
            related_entity_type="shop" if shop_id else None,
            related_entity_id=shop_id,
        )

    async def notify_promotion(
        self,
        user_id: UUID,
        promotion_title: str,
        promotion_message: str,
        voucher_code: Optional[str] = None,
        shop_id: Optional[UUID] = None,
    ) -> NotificationResponse:
        """
        Create a promotion notification.
        
        Args:
            user_id: User's UUID
            promotion_title: Promotion title
            promotion_message: Promotion message
            voucher_code: Voucher code if applicable
            shop_id: Shop UUID if shop-specific promotion
            
        Returns:
            Created notification
        """
        data = {}
        if voucher_code:
            data["voucher_code"] = voucher_code
        if shop_id:
            data["shop_id"] = str(shop_id)
        
        return await self.create_notification(
            user_id=user_id,
            notification_type=NotificationType.PROMOTION,
            title=promotion_title,
            message=promotion_message,
            data=data,
            related_entity_type="shop" if shop_id else None,
            related_entity_id=shop_id,
        )

    async def notify_system(
        self,
        user_id: UUID,
        system_title: str,
        system_message: str,
    ) -> NotificationResponse:
        """
        Create a system notification.
        
        Args:
            user_id: User's UUID
            system_title: System notification title
            system_message: System notification message
            
        Returns:
            Created notification
        """
        return await self.create_notification(
            user_id=user_id,
            notification_type=NotificationType.SYSTEM,
            title=system_title,
            message=system_message,
        )
