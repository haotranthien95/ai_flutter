"""
Integration tests for Cart API endpoints
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from decimal import Decimal
from uuid import uuid4

from app.models.user import User, UserRole
from app.models.shop import Shop, ShopStatus
from app.models.category import Category
from app.models.product import Product, ProductVariant, ProductCondition
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
        images=["image1.jpg", "image2.jpg"],
        condition=ProductCondition.NEW,
        is_active=True
    )
    db_session.add(product)
    await db_session.commit()
    await db_session.refresh(product)
    return product


@pytest.fixture
async def test_variant(db_session: AsyncSession, test_product):
    """Create a test product variant"""
    variant = ProductVariant(
        product_id=test_product.id,
        name="Red - Large",
        attributes={"color": "red", "size": "L"},
        sku="TEST-CART-RED-L",
        price=Decimal("110000"),
        stock=5,
        is_active=True
    )
    db_session.add(variant)
    await db_session.commit()
    await db_session.refresh(variant)
    return variant


class TestGetCart:
    """Tests for GET /cart"""
    
    async def test_get_cart_empty(
        self,
        client: AsyncClient,
        buyer_auth_headers
    ):
        """Test getting empty cart"""
        response = await client.get(
            "/api/v1/cart",
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total_items"] == 0
        assert data["total_quantity"] == 0
        assert data["total_price"] == "0"
        assert len(data["items"]) == 0
    
    async def test_get_cart_with_items(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product
    ):
        """Test getting cart with items"""
        # Add item to cart first
        add_data = {
            "product_id": str(test_product.id),
            "quantity": 2
        }
        await client.post(
            "/api/v1/cart",
            json=add_data,
            headers=buyer_auth_headers
        )
        
        # Get cart
        response = await client.get(
            "/api/v1/cart",
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total_items"] == 1
        assert data["total_quantity"] == 2
        assert len(data["items"]) == 1
        assert data["items"][0]["product_id"] == str(test_product.id)
    
    async def test_get_cart_unauthorized(
        self,
        client: AsyncClient
    ):
        """Test getting cart without authentication"""
        response = await client.get("/api/v1/cart")
        
        assert response.status_code == 403


class TestAddToCart:
    """Tests for POST /cart"""
    
    async def test_add_to_cart_success(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product
    ):
        """Test successfully adding item to cart"""
        add_data = {
            "product_id": str(test_product.id),
            "quantity": 2
        }
        
        response = await client.post(
            "/api/v1/cart",
            json=add_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["product_id"] == str(test_product.id)
        assert data["quantity"] == 2
        assert "id" in data
        assert "unit_price" in data
        assert "total_price" in data
    
    async def test_add_to_cart_with_variant(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product,
        test_variant
    ):
        """Test adding item with variant"""
        add_data = {
            "product_id": str(test_product.id),
            "variant_id": str(test_variant.id),
            "quantity": 1
        }
        
        response = await client.post(
            "/api/v1/cart",
            json=add_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["variant_id"] == str(test_variant.id)
        assert data["unit_price"] == "110000"  # Variant price
    
    async def test_add_to_cart_increment_existing(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product
    ):
        """Test adding existing item increments quantity"""
        add_data = {
            "product_id": str(test_product.id),
            "quantity": 2
        }
        
        # Add first time
        response1 = await client.post(
            "/api/v1/cart",
            json=add_data,
            headers=buyer_auth_headers
        )
        assert response1.status_code == 201
        
        # Add again
        response2 = await client.post(
            "/api/v1/cart",
            json=add_data,
            headers=buyer_auth_headers
        )
        assert response2.status_code == 201
        data = response2.json()
        assert data["quantity"] == 4  # 2 + 2
    
    async def test_add_to_cart_insufficient_stock(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product
    ):
        """Test adding more than available stock"""
        add_data = {
            "product_id": str(test_product.id),
            "quantity": 100  # More than available
        }
        
        response = await client.post(
            "/api/v1/cart",
            json=add_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 400
        assert "stock" in response.json()["detail"].lower()
    
    async def test_add_to_cart_product_not_found(
        self,
        client: AsyncClient,
        buyer_auth_headers
    ):
        """Test adding non-existent product"""
        add_data = {
            "product_id": str(uuid4()),
            "quantity": 1
        }
        
        response = await client.post(
            "/api/v1/cart",
            json=add_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 404
    
    async def test_add_to_cart_unauthorized(
        self,
        client: AsyncClient,
        test_product
    ):
        """Test adding to cart without authentication"""
        add_data = {
            "product_id": str(test_product.id),
            "quantity": 1
        }
        
        response = await client.post(
            "/api/v1/cart",
            json=add_data
        )
        
        assert response.status_code == 403


class TestUpdateCartItem:
    """Tests for PATCH /cart/items/{cart_item_id}"""
    
    async def test_update_cart_item_success(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product
    ):
        """Test successfully updating cart item quantity"""
        # Add item first
        add_data = {
            "product_id": str(test_product.id),
            "quantity": 2
        }
        add_response = await client.post(
            "/api/v1/cart",
            json=add_data,
            headers=buyer_auth_headers
        )
        cart_item_id = add_response.json()["id"]
        
        # Update quantity
        update_data = {"quantity": 5}
        response = await client.patch(
            f"/api/v1/cart/items/{cart_item_id}",
            json=update_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["quantity"] == 5
    
    async def test_update_cart_item_not_found(
        self,
        client: AsyncClient,
        buyer_auth_headers
    ):
        """Test updating non-existent cart item"""
        update_data = {"quantity": 5}
        
        response = await client.patch(
            f"/api/v1/cart/items/{uuid4()}",
            json=update_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 404
    
    async def test_update_cart_item_insufficient_stock(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product
    ):
        """Test updating quantity beyond stock"""
        # Add item first
        add_data = {
            "product_id": str(test_product.id),
            "quantity": 2
        }
        add_response = await client.post(
            "/api/v1/cart",
            json=add_data,
            headers=buyer_auth_headers
        )
        cart_item_id = add_response.json()["id"]
        
        # Try to update to more than stock
        update_data = {"quantity": 100}
        response = await client.patch(
            f"/api/v1/cart/items/{cart_item_id}",
            json=update_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 400
        assert "stock" in response.json()["detail"].lower()


class TestRemoveFromCart:
    """Tests for DELETE /cart/items/{cart_item_id}"""
    
    async def test_remove_from_cart_success(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product
    ):
        """Test successfully removing item from cart"""
        # Add item first
        add_data = {
            "product_id": str(test_product.id),
            "quantity": 2
        }
        add_response = await client.post(
            "/api/v1/cart",
            json=add_data,
            headers=buyer_auth_headers
        )
        cart_item_id = add_response.json()["id"]
        
        # Remove item
        response = await client.delete(
            f"/api/v1/cart/items/{cart_item_id}",
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 204
        
        # Verify cart is empty
        cart_response = await client.get(
            "/api/v1/cart",
            headers=buyer_auth_headers
        )
        assert cart_response.json()["total_items"] == 0
    
    async def test_remove_from_cart_not_found(
        self,
        client: AsyncClient,
        buyer_auth_headers
    ):
        """Test removing non-existent cart item"""
        response = await client.delete(
            f"/api/v1/cart/items/{uuid4()}",
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 404


class TestSyncCart:
    """Tests for POST /cart/sync"""
    
    async def test_sync_cart_success(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product
    ):
        """Test successfully syncing cart"""
        sync_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 3
                }
            ]
        }
        
        response = await client.post(
            "/api/v1/cart/sync",
            json=sync_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total_items"] == 1
        assert data["total_quantity"] == 3
    
    async def test_sync_cart_replaces_existing(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product,
        db_session: AsyncSession,
        test_shop,
        test_category
    ):
        """Test sync cart replaces existing items"""
        # Add an item first
        add_data = {
            "product_id": str(test_product.id),
            "quantity": 2
        }
        await client.post(
            "/api/v1/cart",
            json=add_data,
            headers=buyer_auth_headers
        )
        
        # Create another product
        product2 = Product(
            shop_id=test_shop.id,
            category_id=test_category.id,
            title="Product 2",
            description="Description 2",
            base_price=Decimal("150000"),
            currency="VND",
            total_stock=20,
            images=["image.jpg"],
            condition=ProductCondition.NEW,
            is_active=True
        )
        db_session.add(product2)
        await db_session.commit()
        await db_session.refresh(product2)
        
        # Sync with different items
        sync_data = {
            "items": [
                {
                    "product_id": str(product2.id),
                    "quantity": 5
                }
            ]
        }
        
        response = await client.post(
            "/api/v1/cart/sync",
            json=sync_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        # Should only have the synced item
        assert data["total_items"] == 1
        assert data["items"][0]["product_id"] == str(product2.id)
    
    async def test_sync_cart_skip_invalid_items(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product
    ):
        """Test sync cart skips invalid items"""
        sync_data = {
            "items": [
                {
                    "product_id": str(test_product.id),
                    "quantity": 2
                },
                {
                    "product_id": str(uuid4()),  # Non-existent product
                    "quantity": 1
                }
            ]
        }
        
        response = await client.post(
            "/api/v1/cart/sync",
            json=sync_data,
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        # Should only have the valid item
        assert data["total_items"] == 1
        assert data["items"][0]["product_id"] == str(test_product.id)


class TestClearCart:
    """Tests for DELETE /cart"""
    
    async def test_clear_cart_success(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product
    ):
        """Test successfully clearing cart"""
        # Add items first
        add_data = {
            "product_id": str(test_product.id),
            "quantity": 2
        }
        await client.post(
            "/api/v1/cart",
            json=add_data,
            headers=buyer_auth_headers
        )
        
        # Clear cart
        response = await client.delete(
            "/api/v1/cart",
            headers=buyer_auth_headers
        )
        
        assert response.status_code == 204
        
        # Verify cart is empty
        cart_response = await client.get(
            "/api/v1/cart",
            headers=buyer_auth_headers
        )
        assert cart_response.json()["total_items"] == 0


class TestCartFlow:
    """Tests for complete cart flow"""
    
    async def test_complete_cart_flow(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product,
        test_variant
    ):
        """Test complete cart workflow"""
        # 1. Get empty cart
        response = await client.get(
            "/api/v1/cart",
            headers=buyer_auth_headers
        )
        assert response.json()["total_items"] == 0
        
        # 2. Add product without variant
        add_data1 = {
            "product_id": str(test_product.id),
            "quantity": 2
        }
        response = await client.post(
            "/api/v1/cart",
            json=add_data1,
            headers=buyer_auth_headers
        )
        assert response.status_code == 201
        item1_id = response.json()["id"]
        
        # 3. Add product with variant
        add_data2 = {
            "product_id": str(test_product.id),
            "variant_id": str(test_variant.id),
            "quantity": 1
        }
        response = await client.post(
            "/api/v1/cart",
            json=add_data2,
            headers=buyer_auth_headers
        )
        assert response.status_code == 201
        item2_id = response.json()["id"]
        
        # 4. Get cart with items
        response = await client.get(
            "/api/v1/cart",
            headers=buyer_auth_headers
        )
        data = response.json()
        assert data["total_items"] == 2
        assert data["total_quantity"] == 3
        
        # 5. Update first item quantity
        update_data = {"quantity": 3}
        response = await client.patch(
            f"/api/v1/cart/items/{item1_id}",
            json=update_data,
            headers=buyer_auth_headers
        )
        assert response.status_code == 200
        
        # 6. Remove second item
        response = await client.delete(
            f"/api/v1/cart/items/{item2_id}",
            headers=buyer_auth_headers
        )
        assert response.status_code == 204
        
        # 7. Verify final state
        response = await client.get(
            "/api/v1/cart",
            headers=buyer_auth_headers
        )
        data = response.json()
        assert data["total_items"] == 1
        assert data["total_quantity"] == 3
        
        # 8. Clear cart
        response = await client.delete(
            "/api/v1/cart",
            headers=buyer_auth_headers
        )
        assert response.status_code == 204
        
        # 9. Verify empty
        response = await client.get(
            "/api/v1/cart",
            headers=buyer_auth_headers
        )
        assert response.json()["total_items"] == 0


class TestCartShopGrouping:
    """Tests for cart shop grouping"""
    
    async def test_cart_grouped_by_shop(
        self,
        client: AsyncClient,
        buyer_auth_headers,
        test_product,
        db_session: AsyncSession,
        test_category
    ):
        """Test cart items are grouped by shop"""
        # Create a second seller and shop
        seller2 = User(
            email="seller2@example.com",
            phone_number="0999999999",
            full_name="Seller 2",
            password_hash="$2b$12$test.hash",
            role=UserRole.SELLER,
            is_verified=True
        )
        db_session.add(seller2)
        await db_session.commit()
        await db_session.refresh(seller2)
        
        shop2 = Shop(
            owner_id=seller2.id,
            user_id=seller2.id,
            shop_name="Shop 2",
            description="Shop 2 description",
            business_address="456 Test Ave",
            shipping_fee=Decimal("25000"),
            status=ShopStatus.ACTIVE
        )
        db_session.add(shop2)
        await db_session.commit()
        await db_session.refresh(shop2)
        
        # Create product from second shop
        product2 = Product(
            shop_id=shop2.id,
            category_id=test_category.id,
            title="Product from Shop 2",
            description="Description",
            base_price=Decimal("200000"),
            currency="VND",
            total_stock=15,
            images=["image.jpg"],
            condition=ProductCondition.NEW,
            is_active=True
        )
        db_session.add(product2)
        await db_session.commit()
        await db_session.refresh(product2)
        
        # Add products from both shops
        await client.post(
            "/api/v1/cart",
            json={"product_id": str(test_product.id), "quantity": 2},
            headers=buyer_auth_headers
        )
        await client.post(
            "/api/v1/cart",
            json={"product_id": str(product2.id), "quantity": 1},
            headers=buyer_auth_headers
        )
        
        # Get cart
        response = await client.get(
            "/api/v1/cart",
            headers=buyer_auth_headers
        )
        
        data = response.json()
        assert data["total_items"] == 2
        assert len(data["shops"]) == 2
        
        # Verify shop grouping
        shop_ids = [shop["shop_id"] for shop in data["shops"]]
        assert str(test_product.shop_id) in shop_ids
        assert str(shop2.id) in shop_ids
