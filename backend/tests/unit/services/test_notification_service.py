"""
Unit tests for NotificationService.
"""
import pytest
from unittest.mock import AsyncMock, MagicMock
from uuid import uuid4, UUID
from datetime import datetime

from fastapi import HTTPException

from app.models.notification import Notification, NotificationType
from app.services.notification import NotificationService
from app.schemas.notification import (
    NotificationResponse,
    NotificationListResponse,
    NotificationUnreadCountResponse,
)


@pytest.fixture
def mock_notification_repo():
    """Mock NotificationRepository."""
    return AsyncMock()


@pytest.fixture
def notification_service(mock_notification_repo):
    """NotificationService with mocked repository."""
    return NotificationService(notification_repo=mock_notification_repo)


@pytest.fixture
def user_id():
    """Test user ID."""
    return uuid4()


@pytest.fixture
def order_id():
    """Test order ID."""
    return uuid4()


@pytest.fixture
def shop_id():
    """Test shop ID."""
    return uuid4()


@pytest.fixture
def notification_data(user_id):
    """Sample notification data."""
    return {
        "id": uuid4(),
        "user_id": user_id,
        "type": NotificationType.ORDER_UPDATE,
        "title": "Order Updated",
        "message": "Your order has been shipped",
        "is_read": False,
        "data": {"order_id": str(uuid4()), "status": "SHIPPED"},
        "related_entity_type": "order",
        "related_entity_id": uuid4(),
        "created_at": datetime.utcnow(),
        "updated_at": datetime.utcnow(),
    }


def create_notification_mock(data: dict) -> Notification:
    """Create a mock Notification object."""
    notification = MagicMock(spec=Notification)
    for key, value in data.items():
        setattr(notification, key, value)
    return notification


class TestCreateNotification:
    """Tests for creating notifications."""

    @pytest.mark.asyncio
    async def test_create_notification_success(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
        order_id,
    ):
        """Test creating a notification successfully."""
        # Arrange
        notification_data = {
            "id": uuid4(),
            "user_id": user_id,
            "type": NotificationType.ORDER_UPDATE,
            "title": "Order Updated",
            "message": "Your order status has changed",
            "is_read": False,
            "data": {"order_id": str(order_id), "status": "SHIPPED"},
            "related_entity_type": "order",
            "related_entity_id": order_id,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
        }
        
        mock_notification = create_notification_mock(notification_data)
        mock_notification_repo.create.return_value = mock_notification

        # Act
        result = await notification_service.create_notification(
            user_id=user_id,
            notification_type=NotificationType.ORDER_UPDATE,
            title="Order Updated",
            message="Your order status has changed",
            data={"order_id": str(order_id), "status": "SHIPPED"},
            related_entity_type="order",
            related_entity_id=order_id,
        )

        # Assert
        assert isinstance(result, NotificationResponse)
        assert result.user_id == user_id
        assert result.type == NotificationType.ORDER_UPDATE
        assert result.title == "Order Updated"
        mock_notification_repo.create.assert_called_once()

    @pytest.mark.asyncio
    async def test_notify_order_update(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
        order_id,
    ):
        """Test creating an order update notification."""
        # Arrange
        notification_data = {
            "id": uuid4(),
            "user_id": user_id,
            "type": NotificationType.ORDER_UPDATE,
            "title": "Order ORD-12345 Updated",
            "message": "Your order has been updated to: SHIPPED",
            "is_read": False,
            "data": {"order_id": str(order_id), "status": "SHIPPED"},
            "related_entity_type": "order",
            "related_entity_id": order_id,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
        }
        
        mock_notification = create_notification_mock(notification_data)
        mock_notification_repo.create.return_value = mock_notification

        # Act
        result = await notification_service.notify_order_update(
            user_id=user_id,
            order_id=order_id,
            order_status="SHIPPED",
            order_code="ORD-12345",
        )

        # Assert
        assert isinstance(result, NotificationResponse)
        assert result.type == NotificationType.ORDER_UPDATE
        assert "ORD-12345" in result.title
        assert "SHIPPED" in result.message
        mock_notification_repo.create.assert_called_once()

    @pytest.mark.asyncio
    async def test_notify_message(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
        shop_id,
    ):
        """Test creating a message notification."""
        # Arrange
        notification_data = {
            "id": uuid4(),
            "user_id": user_id,
            "type": NotificationType.MESSAGE,
            "title": "New message from Test Shop",
            "message": "Hello, how can we help?",
            "is_read": False,
            "data": {"sender_name": "Test Shop", "shop_id": str(shop_id)},
            "related_entity_type": "shop",
            "related_entity_id": shop_id,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
        }
        
        mock_notification = create_notification_mock(notification_data)
        mock_notification_repo.create.return_value = mock_notification

        # Act
        result = await notification_service.notify_message(
            user_id=user_id,
            sender_name="Test Shop",
            message_preview="Hello, how can we help?",
            shop_id=shop_id,
        )

        # Assert
        assert isinstance(result, NotificationResponse)
        assert result.type == NotificationType.MESSAGE
        assert "Test Shop" in result.title
        mock_notification_repo.create.assert_called_once()

    @pytest.mark.asyncio
    async def test_notify_promotion(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
        shop_id,
    ):
        """Test creating a promotion notification."""
        # Arrange
        notification_data = {
            "id": uuid4(),
            "user_id": user_id,
            "type": NotificationType.PROMOTION,
            "title": "50% Off Sale!",
            "message": "Use code SAVE50 for 50% off",
            "is_read": False,
            "data": {"voucher_code": "SAVE50", "shop_id": str(shop_id)},
            "related_entity_type": "shop",
            "related_entity_id": shop_id,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
        }
        
        mock_notification = create_notification_mock(notification_data)
        mock_notification_repo.create.return_value = mock_notification

        # Act
        result = await notification_service.notify_promotion(
            user_id=user_id,
            promotion_title="50% Off Sale!",
            promotion_message="Use code SAVE50 for 50% off",
            voucher_code="SAVE50",
            shop_id=shop_id,
        )

        # Assert
        assert isinstance(result, NotificationResponse)
        assert result.type == NotificationType.PROMOTION
        assert result.title == "50% Off Sale!"
        mock_notification_repo.create.assert_called_once()

    @pytest.mark.asyncio
    async def test_notify_system(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
    ):
        """Test creating a system notification."""
        # Arrange
        notification_data = {
            "id": uuid4(),
            "user_id": user_id,
            "type": NotificationType.SYSTEM,
            "title": "System Maintenance",
            "message": "Scheduled maintenance on Sunday",
            "is_read": False,
            "data": None,
            "related_entity_type": None,
            "related_entity_id": None,
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
        }
        
        mock_notification = create_notification_mock(notification_data)
        mock_notification_repo.create.return_value = mock_notification

        # Act
        result = await notification_service.notify_system(
            user_id=user_id,
            system_title="System Maintenance",
            system_message="Scheduled maintenance on Sunday",
        )

        # Assert
        assert isinstance(result, NotificationResponse)
        assert result.type == NotificationType.SYSTEM
        assert result.title == "System Maintenance"
        mock_notification_repo.create.assert_called_once()


class TestGetUserNotifications:
    """Tests for getting user notifications."""

    @pytest.mark.asyncio
    async def test_get_user_notifications_success(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
        notification_data,
    ):
        """Test getting user notifications successfully."""
        # Arrange
        mock_notification = create_notification_mock(notification_data)
        mock_notification_repo.list_by_user.return_value = [mock_notification]
        mock_notification_repo.count_by_user.return_value = 1
        mock_notification_repo.get_unread_count.return_value = 1

        # Act
        result = await notification_service.get_user_notifications(
            user_id=user_id,
            page=1,
            page_size=20,
        )

        # Assert
        assert isinstance(result, NotificationListResponse)
        assert len(result.items) == 1
        assert result.total == 1
        assert result.unread_count == 1
        assert result.page == 1
        assert result.page_size == 20
        mock_notification_repo.list_by_user.assert_called_once_with(
            user_id=user_id,
            skip=0,
            limit=20,
            is_read=None,
            notification_type=None,
        )

    @pytest.mark.asyncio
    async def test_get_user_notifications_with_filters(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
    ):
        """Test getting user notifications with filters."""
        # Arrange
        mock_notification_repo.list_by_user.return_value = []
        mock_notification_repo.count_by_user.return_value = 0
        mock_notification_repo.get_unread_count.return_value = 5

        # Act
        result = await notification_service.get_user_notifications(
            user_id=user_id,
            page=2,
            page_size=10,
            is_read=False,
            notification_type=NotificationType.ORDER_UPDATE,
        )

        # Assert
        assert isinstance(result, NotificationListResponse)
        assert len(result.items) == 0
        assert result.total == 0
        assert result.unread_count == 5
        assert result.page == 2
        assert result.page_size == 10
        mock_notification_repo.list_by_user.assert_called_once_with(
            user_id=user_id,
            skip=10,
            limit=10,
            is_read=False,
            notification_type=NotificationType.ORDER_UPDATE,
        )


class TestGetUnreadCount:
    """Tests for getting unread notification count."""

    @pytest.mark.asyncio
    async def test_get_unread_count_success(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
    ):
        """Test getting unread count successfully."""
        # Arrange
        mock_notification_repo.get_unread_count.return_value = 5

        # Act
        result = await notification_service.get_unread_count(user_id)

        # Assert
        assert isinstance(result, NotificationUnreadCountResponse)
        assert result.unread_count == 5
        mock_notification_repo.get_unread_count.assert_called_once_with(user_id)

    @pytest.mark.asyncio
    async def test_get_unread_count_zero(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
    ):
        """Test getting unread count when zero."""
        # Arrange
        mock_notification_repo.get_unread_count.return_value = 0

        # Act
        result = await notification_service.get_unread_count(user_id)

        # Assert
        assert isinstance(result, NotificationUnreadCountResponse)
        assert result.unread_count == 0


class TestMarkAsRead:
    """Tests for marking notifications as read."""

    @pytest.mark.asyncio
    async def test_mark_as_read_success(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
    ):
        """Test marking notification as read successfully."""
        # Arrange
        notification_id = uuid4()
        mock_notification_repo.mark_as_read.return_value = True

        # Act
        await notification_service.mark_as_read(user_id, notification_id)

        # Assert
        mock_notification_repo.mark_as_read.assert_called_once_with(notification_id, user_id)

    @pytest.mark.asyncio
    async def test_mark_as_read_not_found(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
    ):
        """Test marking notification as read when not found."""
        # Arrange
        notification_id = uuid4()
        mock_notification_repo.mark_as_read.return_value = False

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await notification_service.mark_as_read(user_id, notification_id)

        assert exc_info.value.status_code == 404
        assert "not found" in exc_info.value.detail.lower()

    @pytest.mark.asyncio
    async def test_mark_all_as_read_success(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
    ):
        """Test marking all notifications as read."""
        # Arrange
        mock_notification_repo.mark_all_as_read.return_value = 5

        # Act
        count = await notification_service.mark_all_as_read(user_id)

        # Assert
        assert count == 5
        mock_notification_repo.mark_all_as_read.assert_called_once_with(user_id)

    @pytest.mark.asyncio
    async def test_mark_multiple_as_read_success(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
    ):
        """Test marking multiple notifications as read."""
        # Arrange
        notification_ids = [uuid4(), uuid4(), uuid4()]
        mock_notification_repo.mark_multiple_as_read.return_value = 3

        # Act
        count = await notification_service.mark_multiple_as_read(user_id, notification_ids)

        # Assert
        assert count == 3
        mock_notification_repo.mark_multiple_as_read.assert_called_once_with(notification_ids, user_id)


class TestDeleteNotification:
    """Tests for deleting notifications."""

    @pytest.mark.asyncio
    async def test_delete_notification_success(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
        notification_data,
    ):
        """Test deleting notification successfully."""
        # Arrange
        notification_id = notification_data["id"]
        mock_notification = create_notification_mock(notification_data)
        mock_notification_repo.get.return_value = mock_notification
        mock_notification_repo.delete.return_value = None

        # Act
        await notification_service.delete_notification(user_id, notification_id)

        # Assert
        mock_notification_repo.get.assert_called_once_with(notification_id)
        mock_notification_repo.delete.assert_called_once_with(notification_id)

    @pytest.mark.asyncio
    async def test_delete_notification_not_found(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
    ):
        """Test deleting notification when not found."""
        # Arrange
        notification_id = uuid4()
        mock_notification_repo.get.return_value = None

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await notification_service.delete_notification(user_id, notification_id)

        assert exc_info.value.status_code == 404
        assert "not found" in exc_info.value.detail.lower()

    @pytest.mark.asyncio
    async def test_delete_notification_unauthorized(
        self,
        notification_service,
        mock_notification_repo,
        user_id,
        notification_data,
    ):
        """Test deleting notification when user is not authorized."""
        # Arrange
        notification_id = notification_data["id"]
        different_user_id = uuid4()
        mock_notification = create_notification_mock(notification_data)
        mock_notification_repo.get.return_value = mock_notification

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await notification_service.delete_notification(different_user_id, notification_id)

        assert exc_info.value.status_code == 403
        assert "permission" in exc_info.value.detail.lower()
