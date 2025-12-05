"""
Integration tests for Order API endpoints
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from decimal import Decimal
from uuid import uuid4

from app.models.user import User, UserRole
from app.models.shop import Shop, ShopStatus
from app.models.address import Address
from app.models.category import Category
from app.models.product import Product, ProductCondition
from app.models.cart import CartItem
from app.models.order import OrderStatus
from app.core.security import create_access_token


@pytest.fixture
async def test_buyer(db_session: AsyncSession):
    """Create a test buyer user"""
    user = User(
        email="buyer@example.com",
        phone_number="0912345678",
        full_name="Test Buyer",
        password_hash="$2b$12$test.hashed.password",
        role=UserRole.BUYER,
        is_verified=True,
        is_suspended=False
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
def buyer_auth_headers(test_buyer):
    """Create authentication headers for buyer"""
    token = create_access_token({"sub": str(test_buyer.id)})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
async def test_seller(db_session: AsyncSession):
    """Create a test seller user"""
    user = User(
        email="seller@example.com",
        phone_number="0987654321",
        full_name="Test Seller",
        password_hash="$2b$12$test.hashed.password",
        role=UserRole.SELLER,
        is_verified=True,
        is_suspended=False
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
def seller_auth_headers(test_seller):
    """Create authentication headers for seller"""
    token = create_access_token({"sub": str(test_seller.id)})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
async def test_shop(db_session: AsyncSession, test_seller):
    """Create a test shop"""
    shop = Shop(
        owner_id=test_seller.id,
        user_id=test_seller.id,
        shop_name="Test Shop",
        description="Test shop description",
        business_address="123 Test St",
        shipping_fee=Decimal("20000"),
        status=ShopStatus.ACTIVE
    )
    db_session.add(shop)
    await db_session.commit()
    await db_session.refresh(shop)
    return shop


@pytest.fixture
async def test_address(db_session: AsyncSession, test_buyer):
    """Create a test address"""
    address = Address(
        user_id=test_buyer.id,
        full_name="John Doe",
        phone_number="0912345678",
        address_line1="123 Main St",
        address_line2="Apt 4",
        ward="Ward 1",
        district="District 1",
        city="Ho Chi Minh",
        postal_code="700000",
        is_default=True
    )
    db_session.add(address)
    await db_session.commit()
    await db_session.refresh(address)
    return address


@pytest.fixture
async def test_category(db_session: AsyncSession):
    """Create a test category"""
    category = Category(
        name="Electronics",
        is_active=True,
        level=0,
        sort_order=0
    )
    db_session.add(category)
    await db_session.commit()
    await db_session.refresh(category)
    return category


@pytest.fixture
async def test_product(db_session: AsyncSession, test_shop, test_category):
    """Create a test product"""
    product = Product(
        shop_id=test_shop.id,
        category_id=test_category.id,
        title="Test Product",
        description="Test product description",
        base_price=Decimal("100000"),
        currency="VND",
        total_stock=10,
        images=["image1.jpg"],
        condition=ProductCondition.NEW,
        is_active=True
    )
    db_session.add(product)
    await db_session.commit()
    await db_session.refresh(product)
    return product


class TestCreateOrders:
    """Tests for POST /orders"""
    
    async def test_create_orders_success(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_buyer,
        test_product,
        test_address,
    ):
        """Test successful order creation"""
        order_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 2
                }
            ],
            "address_id": str(test_address.id),
            "payment_method": "cod",
            "notes": "Please deliver in the morning"
        }
        
        response = await client.post(
            "/api/v1/orders",
            json=order_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert len(data) == 1  # One order per shop
        
        order = data[0]
        assert order["status"] == "pending"
        assert order["payment_method"] == "cod"
        assert "order_number" in order
        assert len(order["items"]) == 1
        assert order["notes"] == "Please deliver in the morning"
    
    async def test_create_orders_invalid_address(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product,
    ):
        """Test order creation with invalid address"""
        order_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 1
                }
            ],
            "address_id": str(uuid4()),  # Non-existent address
            "payment_method": "cod"
        }
        
        response = await client.post(
            "/api/v1/orders",
            json=order_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 404
        assert "address" in response.json()["detail"].lower()
    
    async def test_create_orders_insufficient_stock(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product,
        test_address,
    ):
        """Test order creation with insufficient stock"""
        order_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 100  # More than available
                }
            ],
            "address_id": str(test_address.id),
            "payment_method": "cod"
        }
        
        response = await client.post(
            "/api/v1/orders",
            json=order_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 400
        assert "stock" in response.json()["detail"].lower()
    
    async def test_create_orders_unauthorized(
        self,
        client: AsyncClient,
        test_product,
        test_address,
    ):
        """Test order creation without authentication"""
        order_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 1
                }
            ],
            "address_id": str(test_address.id),
            "payment_method": "cod"
        }
        
        response = await client.post(
            "/api/v1/orders",
            json=order_data
        )
        
        assert response.status_code == 403


class TestListOrders:
    """Tests for GET /orders"""
    
    async def test_list_orders_empty(
        self,
        client: AsyncClient,
        buyer_auth_headers,
    ):
        """Test listing orders when none exist"""
        response = await client.get(
            "/api/v1/orders",
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 0
        assert len(data["orders"]) == 0
    
    async def test_list_orders_with_orders(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product,
        test_address,
    ):
        """Test listing orders"""
        # Create an order first
        order_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 1
                }
            ],
            "address_id": str(test_address.id),
            "payment_method": "cod"
        }
        
        await client.post(
            "/api/v1/orders",
            json=order_data,
            headers=buyer_auth_headers
        )
        
        # List orders
        response = await client.get(
            "/api/v1/orders",
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1
        assert len(data["orders"]) >= 1
        assert "order_number" in data["orders"][0]
        assert "status" in data["orders"][0]
    
    async def test_list_orders_with_status_filter(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product,
        test_address,
    ):
        """Test listing orders with status filter"""
        # Create an order
        order_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 1
                }
            ],
            "address_id": str(test_address.id),
            "payment_method": "cod"
        }
        
        await client.post(
            "/api/v1/orders",
            json=order_data,
            headers=buyer_auth_headers
        )
        
        # List with filter
        response = await client.get(
            "/api/v1/orders?status_filter=pending",
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        for order in data["orders"]:
            assert order["status"] == "pending"


class TestGetOrderDetail:
    """Tests for GET /orders/{order_id}"""
    
    async def test_get_order_detail_success(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product,
        test_address,
    ):
        """Test successful order detail retrieval"""
        # Create order
        order_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 2
                }
            ],
            "address_id": str(test_address.id),
            "payment_method": "cod"
        }
        
        create_response = await client.post(
            "/api/v1/orders",
            json=order_data,
            headers=buyer_auth_headers
        )
        order_id = create_response.json()[0]["id"]
        
        # Get detail
        response = await client.get(
            f"/api/v1/orders/{order_id}",
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == order_id
        assert "order_number" in data
        assert len(data["items"]) == 1
        assert data["items"][0]["quantity"] == 2
    
    async def test_get_order_detail_not_found(
        self,
        client: AsyncClient,
        buyer_auth_headers,
    ):
        """Test order detail with non-existent order"""
        response = await client.get(
            f"/api/v1/orders/{uuid4()}",
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 404


class TestCancelOrder:
    """Tests for POST /orders/{order_id}/cancel"""
    
    async def test_cancel_order_success(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product,
        test_address,
        db_session: AsyncSession,
    ):
        """Test successful order cancellation"""
        # Get initial stock
        await db_session.refresh(test_product)
        initial_stock = test_product.total_stock
        
        # Create order
        order_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 2
                }
            ],
            "address_id": str(test_address.id),
            "payment_method": "cod"
        }
        
        create_response = await client.post(
            "/api/v1/orders",
            json=order_data,
            headers=buyer_auth_headers
        )
        order_id = create_response.json()[0]["id"]
        
        # Cancel order
        cancel_data = {
            "reason": "Changed my mind about the purchase"
        }
        
        response = await client.post(
            f"/api/v1/orders/{order_id}/cancel",
            json=cancel_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "cancelled"
        assert data["cancellation_reason"] == "Changed my mind about the purchase"
        
        # Verify stock was restored
        await db_session.refresh(test_product)
        assert test_product.total_stock == initial_stock
    
    async def test_cancel_order_invalid_status(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        seller_auth_headers,
        test_product,
        test_address,
    ):
        """Test cannot cancel order with invalid status"""
        # Create order
        order_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 1
                }
            ],
            "address_id": str(test_address.id),
            "payment_method": "cod"
        }
        
        create_response = await client.post(
            "/api/v1/orders",
            json=order_data,
            headers=buyer_auth_headers
        )
        order_id = create_response.json()[0]["id"]
        
        # Update order to SHIPPING status (as seller)
        await client.patch(
            f"/api/v1/seller/orders/{order_id}/status",
            json={"status": "confirmed"},
            headers=seller_auth_headers
        )
        await client.patch(
            f"/api/v1/seller/orders/{order_id}/status",
            json={"status": "packed"},
            headers=seller_auth_headers
        )
        await client.patch(
            f"/api/v1/seller/orders/{order_id}/status",
            json={"status": "shipping"},
            headers=seller_auth_headers
        )
        
        # Try to cancel
        cancel_data = {
            "reason": "Want to cancel"
        }
        
        response = await client.post(
            f"/api/v1/orders/{order_id}/cancel",
            json=cancel_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 400
        assert "cannot cancel" in response.json()["detail"].lower()


class TestSellerListOrders:
    """Tests for GET /seller/orders"""
    
    async def test_list_shop_orders_success(
        self,
        client: AsyncClient,
        seller_auth_headers,
        buyer_auth_headers,
        test_product,
        test_address,
    ):
        """Test seller listing shop orders"""
        # Create order as buyer
        order_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 1
                }
            ],
            "address_id": str(test_address.id),
            "payment_method": "cod"
        }
        
        await client.post(
            "/api/v1/orders",
            json=order_data,
            headers=buyer_auth_headers
        )
        
        # List orders as seller
        response = await client.get(
            "/api/v1/seller/orders",
            headers=seller_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1
        assert len(data["orders"]) >= 1


class TestSellerUpdateOrderStatus:
    """Tests for PATCH /seller/orders/{order_id}/status"""
    
    async def test_update_order_status_success(
        self,
        client: AsyncClient,
        seller_auth_headers,
        buyer_auth_headers,
        test_product,
        test_address,
    ):
        """Test successful order status update"""
        # Create order
        order_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 1
                }
            ],
            "address_id": str(test_address.id),
            "payment_method": "cod"
        }
        
        create_response = await client.post(
            "/api/v1/orders",
            json=order_data,
            headers=buyer_auth_headers
        )
        order_id = create_response.json()[0]["id"]
        
        # Update status
        response = await client.patch(
            f"/api/v1/seller/orders/{order_id}/status",
            json={"status": "confirmed"},
            headers=seller_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "confirmed"
    
    async def test_update_order_status_invalid_transition(
        self,
        client: AsyncClient,
        seller_auth_headers,
        buyer_auth_headers,
        test_product,
        test_address,
    ):
        """Test invalid status transition"""
        # Create order
        order_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 1
                }
            ],
            "address_id": str(test_address.id),
            "payment_method": "cod"
        }
        
        create_response = await client.post(
            "/api/v1/orders",
            json=order_data,
            headers=buyer_auth_headers
        )
        order_id = create_response.json()[0]["id"]
        
        # Try invalid transition (PENDING to SHIPPING)
        response = await client.patch(
            f"/api/v1/seller/orders/{order_id}/status",
            json={"status": "shipping"},
            headers=seller_auth_headers
        )
        
        assert response.status_code == 400
        assert "transition" in response.json()["detail"].lower()


class TestOrderWorkflow:
    """Tests for complete order workflow"""
    
    async def test_complete_order_workflow(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        seller_auth_headers,
        test_product,
        test_address,
    ):
        """Test complete order lifecycle"""
        # 1. Create order
        order_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 1
                }
            ],
            "address_id": str(test_address.id),
            "payment_method": "cod",
            "notes": "Test order"
        }
        
        create_response = await client.post(
            "/api/v1/orders",
            json=order_data,
            headers=buyer_auth_headers
        )
        assert create_response.status_code == 201
        order_id = create_response.json()[0]["id"]
        
        # 2. Buyer views order
        detail_response = await client.get(
            f"/api/v1/orders/{order_id}",
            headers=buyer_auth_headers
        )
        assert detail_response.status_code == 200
        assert detail_response.json()["status"] == "pending"
        
        # 3. Seller confirms order
        response = await client.patch(
            f"/api/v1/seller/orders/{order_id}/status",
            json={"status": "confirmed"},
            headers=seller_auth_headers
        )
        assert response.status_code == 200
        
        # 4. Seller packs order
        response = await client.patch(
            f"/api/v1/seller/orders/{order_id}/status",
            json={"status": "packed"},
            headers=seller_auth_headers
        )
        assert response.status_code == 200
        
        # 5. Seller ships order
        response = await client.patch(
            f"/api/v1/seller/orders/{order_id}/status",
            json={"status": "shipping"},
            headers=seller_auth_headers
        )
        assert response.status_code == 200
        
        # 6. Seller marks as delivered
        response = await client.patch(
            f"/api/v1/seller/orders/{order_id}/status",
            json={"status": "delivered"},
            headers=seller_auth_headers
        )
        assert response.status_code == 200
        
        # 7. Seller completes order
        response = await client.patch(
            f"/api/v1/seller/orders/{order_id}/status",
            json={"status": "completed"},
            headers=seller_auth_headers
        )
        assert response.status_code == 200
        assert response.json()["status"] == "completed"
        assert response.json()["payment_status"] == "paid"
