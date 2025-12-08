"""
Notification repository for database operations.
"""
from typing import Optional
from uuid import UUID
from sqlalchemy import select, func, update, and_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.notification import Notification, NotificationType
from app.repositories.base import BaseRepository


class NotificationRepository(BaseRepository[Notification]):
    """Repository for notification database operations."""

    def __init__(self, db: AsyncSession):
        super().__init__(Notification, db)

    async def list_by_user(
        self,
        user_id: UUID,
        skip: int = 0,
        limit: int = 20,
        is_read: Optional[bool] = None,
        notification_type: Optional[NotificationType] = None
    ) -> list[Notification]:
        """
        Get notifications for a user with optional filters.
        
        Args:
            user_id: User's UUID
            skip: Number of records to skip
            limit: Number of records to return
            is_read: Filter by read status (None = all)
            notification_type: Filter by notification type
            
        Returns:
            List of notifications
        """
        query = select(Notification).where(Notification.user_id == user_id)
        
        if is_read is not None:
            query = query.where(Notification.is_read == is_read)
            
        if notification_type is not None:
            query = query.where(Notification.type == notification_type)
        
        query = query.order_by(Notification.created_at.desc()).offset(skip).limit(limit)
        
        result = await self.db.execute(query)
        return list(result.scalars().all())

    async def count_by_user(
        self,
        user_id: UUID,
        is_read: Optional[bool] = None,
        notification_type: Optional[NotificationType] = None
    ) -> int:
        """
        Count notifications for a user with optional filters.
        
        Args:
            user_id: User's UUID
            is_read: Filter by read status (None = all)
            notification_type: Filter by notification type
            
        Returns:
            Count of notifications
        """
        query = select(func.count(Notification.id)).where(Notification.user_id == user_id)
        
        if is_read is not None:
            query = query.where(Notification.is_read == is_read)
            
        if notification_type is not None:
            query = query.where(Notification.type == notification_type)
        
        result = await self.db.execute(query)
        return result.scalar_one()

    async def get_unread_count(self, user_id: UUID) -> int:
        """
        Get count of unread notifications for a user.
        
        Args:
            user_id: User's UUID
            
        Returns:
            Count of unread notifications
        """
        return await self.count_by_user(user_id, is_read=False)

    async def mark_as_read(self, notification_id: UUID, user_id: UUID) -> bool:
        """
        Mark a notification as read.
        
        Args:
            notification_id: Notification's UUID
            user_id: User's UUID (for authorization)
            
        Returns:
            True if updated, False if not found or not authorized
        """
        query = (
            update(Notification)
            .where(
                and_(
                    Notification.id == notification_id,
                    Notification.user_id == user_id
                )
            )
            .values(is_read=True)
        )
        
        result = await self.db.execute(query)
        await self.db.commit()
        
        return result.rowcount > 0

    async def mark_all_as_read(self, user_id: UUID) -> int:
        """
        Mark all notifications as read for a user.
        
        Args:
            user_id: User's UUID
            
        Returns:
            Number of notifications marked as read
        """
        query = (
            update(Notification)
            .where(
                and_(
                    Notification.user_id == user_id,
                    Notification.is_read == False
                )
            )
            .values(is_read=True)
        )
        
        result = await self.db.execute(query)
        await self.db.commit()
        
        return result.rowcount

    async def mark_multiple_as_read(self, notification_ids: list[UUID], user_id: UUID) -> int:
        """
        Mark multiple notifications as read.
        
        Args:
            notification_ids: List of notification UUIDs
            user_id: User's UUID (for authorization)
            
        Returns:
            Number of notifications marked as read
        """
        query = (
            update(Notification)
            .where(
                and_(
                    Notification.id.in_(notification_ids),
                    Notification.user_id == user_id
                )
            )
            .values(is_read=True)
        )
        
        result = await self.db.execute(query)
        await self.db.commit()
        
        return result.rowcount

    async def delete_old_notifications(self, user_id: UUID, keep_count: int = 100) -> int:
        """
        Delete old notifications for a user, keeping only the most recent ones.
        
        Args:
            user_id: User's UUID
            keep_count: Number of most recent notifications to keep
            
        Returns:
            Number of notifications deleted
        """
        # Get IDs of notifications to keep
        subquery = (
            select(Notification.id)
            .where(Notification.user_id == user_id)
            .order_by(Notification.created_at.desc())
            .limit(keep_count)
        )
        
        result = await self.db.execute(subquery)
        keep_ids = [row[0] for row in result.all()]
        
        if not keep_ids:
            return 0
        
        # Delete notifications not in keep list
        from sqlalchemy import delete
        query = delete(Notification).where(
            and_(
                Notification.user_id == user_id,
                Notification.id.notin_(keep_ids)
            )
        )
        
        result = await self.db.execute(query)
        await self.db.commit()
        
        return result.rowcount
