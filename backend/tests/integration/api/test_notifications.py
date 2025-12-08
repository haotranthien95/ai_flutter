"""
Integration tests for Notification API endpoints.
"""
import pytest
from httpx import AsyncClient, ASGITransport
from uuid import uuid4

from app.main import app
from app.models.notification import NotificationType
from tests.conftest import get_auth_headers


@pytest.fixture
async def buyer_user(async_client: AsyncClient):
    """Create and return a buyer user."""
    user_data = {
        "phone_number": f"+8490{uuid4().hex[:8]}",
        "password": "TestPass123!",
        "full_name": "Test Buyer",
        "role": "BUYER"
    }
    
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post("/api/v1/auth/register", json=user_data)
        assert response.status_code == 201
        
        user = response.json()
        user["password"] = user_data["password"]
        return user


@pytest.fixture
async def buyer_headers(buyer_user):
    """Get authentication headers for buyer."""
    return await get_auth_headers(buyer_user["phone_number"], buyer_user["password"])


class TestGetNotifications:
    """Tests for getting notifications."""

    @pytest.mark.asyncio
    async def test_get_notifications_empty(self, async_client: AsyncClient, buyer_headers):
        """Test getting notifications when user has none."""
        response = await async_client.get(
            "/api/v1/notifications",
            headers=buyer_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["items"] == []
        assert data["total"] == 0
        assert data["unread_count"] == 0
        assert data["page"] == 1
        assert data["page_size"] == 20

    @pytest.mark.asyncio
    async def test_get_notifications_with_pagination(self, async_client: AsyncClient, buyer_headers):
        """Test getting notifications with pagination."""
        response = await async_client.get(
            "/api/v1/notifications?page=2&page_size=10",
            headers=buyer_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 2
        assert data["page_size"] == 10

    @pytest.mark.asyncio
    async def test_get_notifications_with_filters(self, async_client: AsyncClient, buyer_headers):
        """Test getting notifications with filters."""
        response = await async_client.get(
            "/api/v1/notifications?is_read=false&notification_type=ORDER_UPDATE",
            headers=buyer_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "unread_count" in data

    @pytest.mark.asyncio
    async def test_get_notifications_unauthorized(self, async_client: AsyncClient):
        """Test getting notifications without authentication."""
        response = await async_client.get("/api/v1/notifications")
        
        assert response.status_code == 403


class TestGetUnreadCount:
    """Tests for getting unread notification count."""

    @pytest.mark.asyncio
    async def test_get_unread_count_success(self, async_client: AsyncClient, buyer_headers):
        """Test getting unread count successfully."""
        response = await async_client.get(
            "/api/v1/notifications/unread-count",
            headers=buyer_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "unread_count" in data
        assert isinstance(data["unread_count"], int)
        assert data["unread_count"] >= 0

    @pytest.mark.asyncio
    async def test_get_unread_count_unauthorized(self, async_client: AsyncClient):
        """Test getting unread count without authentication."""
        response = await async_client.get("/api/v1/notifications/unread-count")
        
        assert response.status_code == 403


class TestMarkAsRead:
    """Tests for marking notifications as read."""

    @pytest.mark.asyncio
    async def test_mark_notification_as_read_not_found(
        self, 
        async_client: AsyncClient, 
        buyer_headers
    ):
        """Test marking non-existent notification as read."""
        fake_notification_id = uuid4()
        
        response = await async_client.patch(
            f"/api/v1/notifications/{fake_notification_id}/read",
            headers=buyer_headers
        )
        
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_mark_notification_as_read_unauthorized(self, async_client: AsyncClient):
        """Test marking notification as read without authentication."""
        fake_notification_id = uuid4()
        
        response = await async_client.patch(
            f"/api/v1/notifications/{fake_notification_id}/read"
        )
        
        assert response.status_code == 403


class TestMarkAllAsRead:
    """Tests for marking all notifications as read."""

    @pytest.mark.asyncio
    async def test_mark_all_as_read_success(self, async_client: AsyncClient, buyer_headers):
        """Test marking all notifications as read."""
        response = await async_client.post(
            "/api/v1/notifications/mark-all-read",
            headers=buyer_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "message" in data
        assert "marked" in data["message"].lower()

    @pytest.mark.asyncio
    async def test_mark_all_as_read_unauthorized(self, async_client: AsyncClient):
        """Test marking all as read without authentication."""
        response = await async_client.post("/api/v1/notifications/mark-all-read")
        
        assert response.status_code == 403


class TestMarkMultipleAsRead:
    """Tests for marking multiple notifications as read."""

    @pytest.mark.asyncio
    async def test_mark_multiple_as_read_with_ids(
        self, 
        async_client: AsyncClient, 
        buyer_headers
    ):
        """Test marking multiple specific notifications as read."""
        notification_ids = [str(uuid4()), str(uuid4())]
        
        response = await async_client.post(
            "/api/v1/notifications/mark-read",
            json={"notification_ids": notification_ids},
            headers=buyer_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "message" in data

    @pytest.mark.asyncio
    async def test_mark_multiple_as_read_empty_list(
        self, 
        async_client: AsyncClient, 
        buyer_headers
    ):
        """Test marking with empty list marks all as read."""
        response = await async_client.post(
            "/api/v1/notifications/mark-read",
            json={"notification_ids": []},
            headers=buyer_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "message" in data

    @pytest.mark.asyncio
    async def test_mark_multiple_as_read_no_ids(
        self, 
        async_client: AsyncClient, 
        buyer_headers
    ):
        """Test marking with no IDs provided marks all as read."""
        response = await async_client.post(
            "/api/v1/notifications/mark-read",
            json={},
            headers=buyer_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "message" in data

    @pytest.mark.asyncio
    async def test_mark_multiple_as_read_unauthorized(self, async_client: AsyncClient):
        """Test marking multiple as read without authentication."""
        response = await async_client.post(
            "/api/v1/notifications/mark-read",
            json={"notification_ids": [str(uuid4())]}
        )
        
        assert response.status_code == 403


class TestDeleteNotification:
    """Tests for deleting notifications."""

    @pytest.mark.asyncio
    async def test_delete_notification_not_found(
        self, 
        async_client: AsyncClient, 
        buyer_headers
    ):
        """Test deleting non-existent notification."""
        fake_notification_id = uuid4()
        
        response = await async_client.delete(
            f"/api/v1/notifications/{fake_notification_id}",
            headers=buyer_headers
        )
        
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_notification_unauthorized(self, async_client: AsyncClient):
        """Test deleting notification without authentication."""
        fake_notification_id = uuid4()
        
        response = await async_client.delete(
            f"/api/v1/notifications/{fake_notification_id}"
        )
        
        assert response.status_code == 403


class TestNotificationWorkflow:
    """Integration tests for complete notification workflow."""

    @pytest.mark.asyncio
    async def test_notification_lifecycle(
        self, 
        async_client: AsyncClient, 
        buyer_user,
        buyer_headers
    ):
        """Test complete notification lifecycle: create, read, mark as read, delete."""
        # Since we don't have a direct create endpoint (notifications are created by system events),
        # we'll test the read-only operations
        
        # 1. Get initial state
        response = await async_client.get(
            "/api/v1/notifications",
            headers=buyer_headers
        )
        assert response.status_code == 200
        initial_data = response.json()
        initial_count = initial_data["total"]
        
        # 2. Check unread count
        response = await async_client.get(
            "/api/v1/notifications/unread-count",
            headers=buyer_headers
        )
        assert response.status_code == 200
        unread_data = response.json()
        assert unread_data["unread_count"] >= 0
        
        # 3. Mark all as read (even if empty)
        response = await async_client.post(
            "/api/v1/notifications/mark-all-read",
            headers=buyer_headers
        )
        assert response.status_code == 200
        
        # 4. Verify unread count is now 0
        response = await async_client.get(
            "/api/v1/notifications/unread-count",
            headers=buyer_headers
        )
        assert response.status_code == 200
        unread_data = response.json()
        assert unread_data["unread_count"] == 0
        
        # 5. Test pagination
        response = await async_client.get(
            "/api/v1/notifications?page=1&page_size=5",
            headers=buyer_headers
        )
        assert response.status_code == 200
        page_data = response.json()
        assert page_data["page"] == 1
        assert page_data["page_size"] == 5
        
        # 6. Test filtering by type
        response = await async_client.get(
            "/api/v1/notifications?notification_type=ORDER_UPDATE",
            headers=buyer_headers
        )
        assert response.status_code == 200
        
        # 7. Test filtering by read status
        response = await async_client.get(
            "/api/v1/notifications?is_read=true",
            headers=buyer_headers
        )
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_notification_authorization(
        self, 
        async_client: AsyncClient, 
        buyer_user
    ):
        """Test that notifications require authentication."""
        # Test all endpoints without auth
        endpoints = [
            ("GET", "/api/v1/notifications"),
            ("GET", "/api/v1/notifications/unread-count"),
            ("PATCH", f"/api/v1/notifications/{uuid4()}/read"),
            ("POST", "/api/v1/notifications/mark-all-read"),
            ("POST", "/api/v1/notifications/mark-read"),
            ("DELETE", f"/api/v1/notifications/{uuid4()}"),
        ]
        
        for method, endpoint in endpoints:
            if method == "GET":
                response = await async_client.get(endpoint)
            elif method == "POST":
                response = await async_client.post(endpoint, json={})
            elif method == "PATCH":
                response = await async_client.patch(endpoint)
            elif method == "DELETE":
                response = await async_client.delete(endpoint)
            
            assert response.status_code == 403, f"Expected 403 for {method} {endpoint}"
