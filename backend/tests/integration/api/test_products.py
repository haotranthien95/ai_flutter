"""
Integration tests for Product API endpoints
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
async def test_user(db_session: AsyncSession):
    """Create a test user"""
    user = User(
        email="seller@example.com",
        phone_number="0912345678",
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
def auth_headers(test_user):
    """Create authentication headers"""
    token = create_access_token({"sub": str(test_user.id)})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
async def test_shop(db_session: AsyncSession, test_user):
    """Create a test shop"""
    shop = Shop(
        owner_id=test_user.id,
        user_id=test_user.id,
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
        sku="TEST-PROD-RED-L",
        price=Decimal("110000"),
        stock=5,
        is_active=True
    )
    db_session.add(variant)
    await db_session.commit()
    await db_session.refresh(variant)
    return variant


class TestListProducts:
    """Tests for GET /products"""
    
    async def test_list_products_success(
        self,
        client: AsyncClient,
        test_product
    ):
        """Test successful product listing (public endpoint)"""
        response = await client.get("/api/v1/products")
        
        assert response.status_code == 200
        data = response.json()
        assert "products" in data
        assert "total" in data
        assert "page" in data
        assert "page_size" in data
        assert "total_pages" in data
        assert len(data["products"]) >= 1
        
        # Check product structure
        product = data["products"][0]
        assert "id" in product
        assert "title" in product
        assert "base_price" in product
        assert "images" in product
    
    async def test_list_products_with_category_filter(
        self,
        client: AsyncClient,
        test_product,
        test_category
    ):
        """Test product listing with category filter"""
        response = await client.get(
            f"/api/v1/products?category_id={test_category.id}"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert len(data["products"]) >= 1
        assert data["products"][0]["category_id"] == str(test_category.id)
    
    async def test_list_products_with_price_filter(
        self,
        client: AsyncClient,
        test_product
    ):
        """Test product listing with price range filter"""
        response = await client.get(
            "/api/v1/products?min_price=50000&max_price=150000"
        )
        
        assert response.status_code == 200
        data = response.json()
        
        for product in data["products"]:
            price = float(product["base_price"])
            assert 50000 <= price <= 150000
    
    async def test_list_products_with_search(
        self,
        client: AsyncClient,
        test_product
    ):
        """Test product listing with search query"""
        response = await client.get(
            "/api/v1/products?search=Test"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert len(data["products"]) >= 1
    
    async def test_list_products_pagination(
        self,
        client: AsyncClient,
        test_product
    ):
        """Test product listing pagination"""
        response = await client.get(
            "/api/v1/products?page=1&page_size=5"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 1
        assert data["page_size"] == 5
        assert len(data["products"]) <= 5
    
    async def test_list_products_sorting(
        self,
        client: AsyncClient,
        test_product
    ):
        """Test product listing with sorting"""
        response = await client.get(
            "/api/v1/products?sort_by=base_price&sort_order=asc"
        )
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify sorting if multiple products
        if len(data["products"]) > 1:
            prices = [float(p["base_price"]) for p in data["products"]]
            assert prices == sorted(prices)


class TestGetProductDetail:
    """Tests for GET /products/{id}"""
    
    async def test_get_product_detail_success(
        self,
        client: AsyncClient,
        test_product,
        test_variant
    ):
        """Test successful product detail retrieval"""
        response = await client.get(f"/api/v1/products/{test_product.id}")
        
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(test_product.id)
        assert data["title"] == "Test Product"
        assert data["description"] == "Test product description"
        assert "variants" in data
        assert len(data["variants"]) >= 1
    
    async def test_get_product_detail_not_found(
        self,
        client: AsyncClient
    ):
        """Test product detail with non-existent product"""
        fake_id = uuid4()
        response = await client.get(f"/api/v1/products/{fake_id}")
        
        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()


class TestGetProductVariants:
    """Tests for GET /products/{id}/variants"""
    
    async def test_get_product_variants_success(
        self,
        client: AsyncClient,
        test_product,
        test_variant
    ):
        """Test successful variant listing"""
        response = await client.get(
            f"/api/v1/products/{test_product.id}/variants"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        assert len(data) >= 1
        assert data[0]["id"] == str(test_variant.id)
        assert data[0]["name"] == "Red - Large"
        assert data[0]["sku"] == "TEST-PROD-RED-L"


class TestSearchAutocomplete:
    """Tests for GET /products/search/autocomplete"""
    
    async def test_search_autocomplete_success(
        self,
        client: AsyncClient,
        test_product
    ):
        """Test successful autocomplete"""
        response = await client.get(
            "/api/v1/products/search/autocomplete?q=Test"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "suggestions" in data
        assert isinstance(data["suggestions"], list)
    
    async def test_search_autocomplete_short_query(
        self,
        client: AsyncClient
    ):
        """Test autocomplete rejects short query"""
        response = await client.get(
            "/api/v1/products/search/autocomplete?q=T"
        )
        
        # Should reject query shorter than 2 chars
        assert response.status_code == 422


class TestSellerCreateProduct:
    """Tests for POST /seller/products"""
    
    async def test_create_product_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_shop,
        test_category
    ):
        """Test successful product creation"""
        product_data = {
            "title": "New Test Product",
            "description": "New product description",
            "category_id": str(test_category.id),
            "base_price": "150000",
            "currency": "VND",
            "total_stock": 20,
            "images": ["new1.jpg", "new2.jpg"],
            "condition": "new",
            "is_active": True
        }
        
        response = await client.post(
            "/api/v1/seller/products",
            json=product_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "New Test Product"
        assert data["base_price"] == "150000"
        assert "id" in data
    
    async def test_create_product_unauthorized(
        self,
        client: AsyncClient,
        test_category
    ):
        """Test product creation without authentication"""
        product_data = {
            "title": "New Product",
            "base_price": "100000"
        }
        
        response = await client.post(
            "/api/v1/seller/products",
            json=product_data
        )
        
        assert response.status_code == 403  # No auth header
    
    async def test_create_product_with_variants(
        self,
        client: AsyncClient,
        auth_headers,
        test_shop,
        test_category
    ):
        """Test product creation with variants"""
        product_data = {
            "title": "Product with Variants",
            "base_price": "100000",
            "total_stock": 0,
            "variants": [
                {
                    "name": "Small",
                    "sku": "PROD-SMALL",
                    "price": "95000",
                    "stock": 5
                },
                {
                    "name": "Large",
                    "sku": "PROD-LARGE",
                    "price": "105000",
                    "stock": 3
                }
            ]
        }
        
        response = await client.post(
            "/api/v1/seller/products",
            json=product_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert len(data["variants"]) == 2
    
    async def test_create_product_invalid_category(
        self,
        client: AsyncClient,
        auth_headers,
        test_shop
    ):
        """Test product creation with invalid category"""
        product_data = {
            "title": "New Product",
            "category_id": str(uuid4()),  # Non-existent category
            "base_price": "100000"
        }
        
        response = await client.post(
            "/api/v1/seller/products",
            json=product_data,
            headers=auth_headers
        )
        
        assert response.status_code == 404
        assert "category" in response.json()["detail"].lower()


class TestSellerListProducts:
    """Tests for GET /seller/products"""
    
    async def test_list_seller_products_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_product
    ):
        """Test successful seller product listing"""
        response = await client.get(
            "/api/v1/seller/products",
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "products" in data
        assert "total" in data
        assert len(data["products"]) >= 1
    
    async def test_list_seller_products_unauthorized(
        self,
        client: AsyncClient
    ):
        """Test seller product listing without authentication"""
        response = await client.get("/api/v1/seller/products")
        
        assert response.status_code == 403


class TestSellerUpdateProduct:
    """Tests for PUT /seller/products/{id}"""
    
    async def test_update_product_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_product
    ):
        """Test successful product update"""
        update_data = {
            "title": "Updated Product Title",
            "base_price": "200000"
        }
        
        response = await client.put(
            f"/api/v1/seller/products/{test_product.id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Product Title"
        assert data["base_price"] == "200000"
    
    async def test_update_product_not_found(
        self,
        client: AsyncClient,
        auth_headers
    ):
        """Test update non-existent product"""
        fake_id = uuid4()
        update_data = {"title": "Updated"}
        
        response = await client.put(
            f"/api/v1/seller/products/{fake_id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 404
    
    async def test_update_product_unauthorized(
        self,
        client: AsyncClient,
        test_product
    ):
        """Test product update without authentication"""
        update_data = {"title": "Updated"}
        
        response = await client.put(
            f"/api/v1/seller/products/{test_product.id}",
            json=update_data
        )
        
        assert response.status_code == 403


class TestSellerDeleteProduct:
    """Tests for DELETE /seller/products/{id}"""
    
    async def test_delete_product_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_product
    ):
        """Test successful product deletion"""
        response = await client.delete(
            f"/api/v1/seller/products/{test_product.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 204
        
        # Verify product is deleted
        get_response = await client.get(
            f"/api/v1/products/{test_product.id}"
        )
        assert get_response.status_code == 404
    
    async def test_delete_product_unauthorized(
        self,
        client: AsyncClient,
        test_product
    ):
        """Test product deletion without authentication"""
        response = await client.delete(
            f"/api/v1/seller/products/{test_product.id}"
        )
        
        assert response.status_code == 403


class TestSellerVariantManagement:
    """Tests for variant CRUD operations"""
    
    async def test_create_variant_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_product
    ):
        """Test successful variant creation"""
        variant_data = {
            "name": "Blue - Medium",
            "sku": "TEST-BLUE-M",
            "price": "105000",
            "stock": 7,
            "attributes": {"color": "blue", "size": "M"}
        }
        
        response = await client.post(
            f"/api/v1/seller/products/{test_product.id}/variants",
            json=variant_data,
            headers=auth_headers
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "Blue - Medium"
        assert data["sku"] == "TEST-BLUE-M"
    
    async def test_update_variant_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_variant
    ):
        """Test successful variant update"""
        update_data = {
            "price": "115000",
            "stock": 10
        }
        
        response = await client.put(
            f"/api/v1/seller/variants/{test_variant.id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["price"] == "115000"
        assert data["stock"] == 10
    
    async def test_delete_variant_success(
        self,
        client: AsyncClient,
        auth_headers,
        test_variant
    ):
        """Test successful variant deletion"""
        response = await client.delete(
            f"/api/v1/seller/variants/{test_variant.id}",
            headers=auth_headers
        )
        
        assert response.status_code == 204


class TestProductOwnership:
    """Tests for product ownership validation"""
    
    async def test_update_other_seller_product(
        self,
        client: AsyncClient,
        db_session: AsyncSession,
        test_product
    ):
        """Test cannot update another seller's product"""
        # Create a different seller
        other_seller = User(
            email="other@example.com",
            phone_number="0987654321",
            full_name="Other Seller",
            password_hash="$2b$12$test.hash",
            role=UserRole.SELLER,
            is_verified=True
        )
        db_session.add(other_seller)
        await db_session.commit()
        await db_session.refresh(other_seller)
        
        # Create auth headers for other seller
        token = create_access_token({"sub": str(other_seller.id)})
        other_headers = {"Authorization": f"Bearer {token}"}
        
        # Try to update the product
        update_data = {"title": "Hacked Product"}
        response = await client.put(
            f"/api/v1/seller/products/{test_product.id}",
            json=update_data,
            headers=other_headers
        )
        
        assert response.status_code == 403
        assert "your own" in response.json()["detail"].lower()
