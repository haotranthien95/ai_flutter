"""
Integration tests for Admin API endpoints.
"""
import pytest
from httpx import AsyncClient, ASGITransport
from uuid import uuid4

from app.main import app
from app.models.user import UserRole
from tests.conftest import get_auth_headers


@pytest.fixture
async def admin_user(async_client: AsyncClient):
    """Create and return an admin user."""
    user_data = {
        "phone_number": f"+8499{uuid4().hex[:8]}",
        "password": "AdminPass123!",
        "full_name": "Admin User",
        "role": "ADMIN"
    }
    
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post("/api/v1/auth/register", json=user_data)
        assert response.status_code == 201
        
        user = response.json()
        user["password"] = user_data["password"]
        return user


@pytest.fixture
async def buyer_user(async_client: AsyncClient):
    """Create and return a buyer user."""
    user_data = {
        "phone_number": f"+8490{uuid4().hex[:8]}",
        "password": "BuyerPass123!",
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
async def admin_headers(admin_user):
    """Get authentication headers for admin."""
    return await get_auth_headers(admin_user["phone_number"], admin_user["password"])


@pytest.fixture
async def buyer_headers(buyer_user):
    """Get authentication headers for buyer."""
    return await get_auth_headers(buyer_user["phone_number"], buyer_user["password"])


class TestAdminDashboard:
    """Tests for admin dashboard metrics."""

    @pytest.mark.asyncio
    async def test_get_dashboard_metrics_success(self, async_client: AsyncClient, admin_headers):
        """Test getting dashboard metrics as admin."""
        response = await async_client.get(
            "/api/v1/admin/dashboard",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "users" in data
        assert "shops" in data
        assert "products" in data
        assert "orders" in data
        assert "revenue" in data
        
        # Check user metrics structure
        assert "total" in data["users"]
        assert "active" in data["users"]
        assert "suspended" in data["users"]
        
        # Check revenue metrics
        assert "total" in data["revenue"]
        assert "last_30_days" in data["revenue"]

    @pytest.mark.asyncio
    async def test_get_dashboard_metrics_non_admin(self, async_client: AsyncClient, buyer_headers):
        """Test that non-admin cannot access dashboard."""
        response = await async_client.get(
            "/api/v1/admin/dashboard",
            headers=buyer_headers
        )
        
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_get_dashboard_metrics_unauthorized(self, async_client: AsyncClient):
        """Test that unauthenticated user cannot access dashboard."""
        response = await async_client.get("/api/v1/admin/dashboard")
        
        assert response.status_code == 403


class TestUserManagement:
    """Tests for user management endpoints."""

    @pytest.mark.asyncio
    async def test_list_users_success(self, async_client: AsyncClient, admin_headers):
        """Test listing users as admin."""
        response = await async_client.get(
            "/api/v1/admin/users",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "page" in data
        assert "page_size" in data
        assert isinstance(data["items"], list)

    @pytest.mark.asyncio
    async def test_list_users_with_filters(self, async_client: AsyncClient, admin_headers):
        """Test listing users with filters."""
        response = await async_client.get(
            "/api/v1/admin/users?role=BUYER&page=1&page_size=10",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 1
        assert data["page_size"] == 10

    @pytest.mark.asyncio
    async def test_list_users_non_admin(self, async_client: AsyncClient, buyer_headers):
        """Test that non-admin cannot list users."""
        response = await async_client.get(
            "/api/v1/admin/users",
            headers=buyer_headers
        )
        
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_suspend_user_not_found(self, async_client: AsyncClient, admin_headers):
        """Test suspending non-existent user."""
        fake_user_id = uuid4()
        
        response = await async_client.patch(
            f"/api/v1/admin/users/{fake_user_id}/suspend",
            headers=admin_headers,
            json={"reason": "Test reason"}
        )
        
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_suspend_user_non_admin(self, async_client: AsyncClient, buyer_headers):
        """Test that non-admin cannot suspend users."""
        fake_user_id = uuid4()
        
        response = await async_client.patch(
            f"/api/v1/admin/users/{fake_user_id}/suspend",
            headers=buyer_headers,
            json={"reason": "Test"}
        )
        
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_unsuspend_user_not_found(self, async_client: AsyncClient, admin_headers):
        """Test unsuspending non-existent user."""
        fake_user_id = uuid4()
        
        response = await async_client.patch(
            f"/api/v1/admin/users/{fake_user_id}/unsuspend",
            headers=admin_headers
        )
        
        assert response.status_code == 404


class TestShopManagement:
    """Tests for shop management endpoints."""

    @pytest.mark.asyncio
    async def test_list_shops_success(self, async_client: AsyncClient, admin_headers):
        """Test listing shops as admin."""
        response = await async_client.get(
            "/api/v1/admin/shops",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "page" in data
        assert "page_size" in data

    @pytest.mark.asyncio
    async def test_list_shops_with_filters(self, async_client: AsyncClient, admin_headers):
        """Test listing shops with filters."""
        response = await async_client.get(
            "/api/v1/admin/shops?is_active=true&search=test",
            headers=admin_headers
        )
        
        assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_list_shops_non_admin(self, async_client: AsyncClient, buyer_headers):
        """Test that non-admin cannot list shops."""
        response = await async_client.get(
            "/api/v1/admin/shops",
            headers=buyer_headers
        )
        
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_update_shop_status_not_found(self, async_client: AsyncClient, admin_headers):
        """Test updating status of non-existent shop."""
        fake_shop_id = uuid4()
        
        response = await async_client.patch(
            f"/api/v1/admin/shops/{fake_shop_id}/status",
            headers=admin_headers,
            json={"is_active": False, "reason": "Test"}
        )
        
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_update_shop_status_non_admin(self, async_client: AsyncClient, buyer_headers):
        """Test that non-admin cannot update shop status."""
        fake_shop_id = uuid4()
        
        response = await async_client.patch(
            f"/api/v1/admin/shops/{fake_shop_id}/status",
            headers=buyer_headers,
            json={"is_active": False}
        )
        
        assert response.status_code == 403


class TestProductModeration:
    """Tests for product moderation endpoints."""

    @pytest.mark.asyncio
    async def test_list_products_success(self, async_client: AsyncClient, admin_headers):
        """Test listing products as admin."""
        response = await async_client.get(
            "/api/v1/admin/products",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert "total" in data
        assert "page" in data
        assert "page_size" in data

    @pytest.mark.asyncio
    async def test_list_products_with_filters(self, async_client: AsyncClient, admin_headers):
        """Test listing products with filters."""
        response = await async_client.get(
            "/api/v1/admin/products?is_active=true&page=1&page_size=10",
            headers=admin_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 1
        assert data["page_size"] == 10

    @pytest.mark.asyncio
    async def test_list_products_non_admin(self, async_client: AsyncClient, buyer_headers):
        """Test that non-admin cannot list products."""
        response = await async_client.get(
            "/api/v1/admin/products",
            headers=buyer_headers
        )
        
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_moderate_product_not_found(self, async_client: AsyncClient, admin_headers):
        """Test moderating non-existent product."""
        fake_product_id = uuid4()
        
        response = await async_client.patch(
            f"/api/v1/admin/products/{fake_product_id}/status",
            headers=admin_headers,
            json={"is_active": False, "reason": "Violation"}
        )
        
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_moderate_product_non_admin(self, async_client: AsyncClient, buyer_headers):
        """Test that non-admin cannot moderate products."""
        fake_product_id = uuid4()
        
        response = await async_client.patch(
            f"/api/v1/admin/products/{fake_product_id}/status",
            headers=buyer_headers,
            json={"is_active": False}
        )
        
        assert response.status_code == 403


class TestCategoryManagement:
    """Tests for category management endpoints."""

    @pytest.mark.asyncio
    async def test_create_category_success(self, async_client: AsyncClient, admin_headers):
        """Test creating category as admin."""
        category_data = {
            "name": f"Test Category {uuid4().hex[:8]}",
            "description": "Test category description"
        }
        
        response = await async_client.post(
            "/api/v1/admin/categories",
            headers=admin_headers,
            json=category_data
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == category_data["name"]
        assert data["description"] == category_data["description"]

    @pytest.mark.asyncio
    async def test_create_category_non_admin(self, async_client: AsyncClient, buyer_headers):
        """Test that non-admin cannot create categories."""
        category_data = {
            "name": "Test Category",
            "description": "Test"
        }
        
        response = await async_client.post(
            "/api/v1/admin/categories",
            headers=buyer_headers,
            json=category_data
        )
        
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_update_category_not_found(self, async_client: AsyncClient, admin_headers):
        """Test updating non-existent category."""
        fake_category_id = uuid4()
        
        response = await async_client.put(
            f"/api/v1/admin/categories/{fake_category_id}",
            headers=admin_headers,
            json={"name": "Updated Name"}
        )
        
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_update_category_non_admin(self, async_client: AsyncClient, buyer_headers):
        """Test that non-admin cannot update categories."""
        fake_category_id = uuid4()
        
        response = await async_client.put(
            f"/api/v1/admin/categories/{fake_category_id}",
            headers=buyer_headers,
            json={"name": "Updated"}
        )
        
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_delete_category_not_found(self, async_client: AsyncClient, admin_headers):
        """Test deleting non-existent category."""
        fake_category_id = uuid4()
        
        response = await async_client.delete(
            f"/api/v1/admin/categories/{fake_category_id}",
            headers=admin_headers
        )
        
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_delete_category_non_admin(self, async_client: AsyncClient, buyer_headers):
        """Test that non-admin cannot delete categories."""
        fake_category_id = uuid4()
        
        response = await async_client.delete(
            f"/api/v1/admin/categories/{fake_category_id}",
            headers=buyer_headers
        )
        
        assert response.status_code == 403


class TestAdminAuthorization:
    """Tests for admin authorization."""

    @pytest.mark.asyncio
    async def test_all_admin_endpoints_require_auth(self, async_client: AsyncClient):
        """Test that all admin endpoints require authentication."""
        endpoints = [
            ("GET", "/api/v1/admin/dashboard"),
            ("GET", "/api/v1/admin/users"),
            ("GET", "/api/v1/admin/shops"),
            ("GET", "/api/v1/admin/products"),
        ]
        
        for method, endpoint in endpoints:
            if method == "GET":
                response = await async_client.get(endpoint)
            
            assert response.status_code == 403, f"Expected 403 for {method} {endpoint}"

    @pytest.mark.asyncio
    async def test_all_admin_endpoints_require_admin_role(
        self, 
        async_client: AsyncClient, 
        buyer_headers
    ):
        """Test that all admin endpoints require admin role."""
        endpoints = [
            ("GET", "/api/v1/admin/dashboard"),
            ("GET", "/api/v1/admin/users"),
            ("PATCH", f"/api/v1/admin/users/{uuid4()}/suspend", {"reason": "test"}),
            ("PATCH", f"/api/v1/admin/users/{uuid4()}/unsuspend", None),
            ("GET", "/api/v1/admin/shops"),
            ("PATCH", f"/api/v1/admin/shops/{uuid4()}/status", {"is_active": False}),
            ("GET", "/api/v1/admin/products"),
            ("PATCH", f"/api/v1/admin/products/{uuid4()}/status", {"is_active": False}),
            ("POST", "/api/v1/admin/categories", {"name": "Test"}),
            ("PUT", f"/api/v1/admin/categories/{uuid4()}", {"name": "Test"}),
            ("DELETE", f"/api/v1/admin/categories/{uuid4()}", None),
        ]
        
        for method, endpoint, *data in endpoints:
            json_data = data[0] if data else None
            
            if method == "GET":
                response = await async_client.get(endpoint, headers=buyer_headers)
            elif method == "POST":
                response = await async_client.post(endpoint, headers=buyer_headers, json=json_data)
            elif method == "PUT":
                response = await async_client.put(endpoint, headers=buyer_headers, json=json_data)
            elif method == "PATCH":
                response = await async_client.patch(endpoint, headers=buyer_headers, json=json_data)
            elif method == "DELETE":
                response = await async_client.delete(endpoint, headers=buyer_headers)
            
            assert response.status_code == 403, f"Expected 403 for {method} {endpoint}"
