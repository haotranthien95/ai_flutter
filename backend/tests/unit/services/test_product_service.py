"""
Unit tests for Product Service
"""
import pytest
from uuid import uuid4
from unittest.mock import AsyncMock, MagicMock
from fastapi import HTTPException
from decimal import Decimal
from datetime import datetime, timezone

from app.models.product import Product, ProductVariant, ProductCondition
from app.models.shop import Shop, ShopStatus
from app.models.category import Category
from app.schemas.product import ProductCreate, ProductUpdate, ProductVariantCreate
from app.services.product import ProductService


# Mark all tests in this module as asyncio
pytestmark = pytest.mark.asyncio


@pytest.fixture
def mock_product_repo():
    """Mock product repository"""
    repo = AsyncMock()
    return repo


@pytest.fixture
def mock_variant_repo():
    """Mock variant repository"""
    repo = AsyncMock()
    return repo


@pytest.fixture
def mock_category_repo():
    """Mock category repository"""
    repo = AsyncMock()
    return repo


@pytest.fixture
def mock_shop_repo():
    """Mock shop repository"""
    repo = AsyncMock()
    return repo


@pytest.fixture
def product_service(mock_product_repo, mock_variant_repo, mock_category_repo, mock_shop_repo):
    """Create product service with mocked repositories"""
    return ProductService(
        product_repo=mock_product_repo,
        variant_repo=mock_variant_repo,
        category_repo=mock_category_repo,
        shop_repo=mock_shop_repo,
    )


@pytest.fixture
def sample_shop():
    """Sample shop object"""
    return Shop(
        id=uuid4(),
        owner_id=uuid4(),
        shop_name="Test Shop",
        user_id=uuid4(),
        status=ShopStatus.ACTIVE,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )


@pytest.fixture
def sample_category():
    """Sample category object"""
    return Category(
        id=uuid4(),
        name="Electronics",
        is_active=True,
        level=0,
        sort_order=0,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )


@pytest.fixture
def sample_product(sample_shop, sample_category):
    """Sample product object"""
    return Product(
        id=uuid4(),
        shop_id=sample_shop.id,
        category_id=sample_category.id,
        title="Test Product",
        description="Test description",
        base_price=Decimal("100000"),
        currency="VND",
        total_stock=10,
        images=["image1.jpg", "image2.jpg"],
        condition=ProductCondition.NEW,
        average_rating=4.5,
        total_reviews=10,
        sold_count=5,
        is_active=True,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )


@pytest.fixture
def sample_variant(sample_product):
    """Sample product variant"""
    return ProductVariant(
        id=uuid4(),
        product_id=sample_product.id,
        name="Red - Large",
        attributes={"color": "red", "size": "L"},
        sku="PROD-RED-L",
        price=Decimal("110000"),
        stock=5,
        is_active=True,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )


class TestListProducts:
    """Tests for list_products method"""
    
    async def test_list_products_success(
        self,
        product_service,
        mock_product_repo,
        sample_product
    ):
        """Test successful product listing"""
        mock_product_repo.list_with_filters.return_value = ([sample_product], 1)
        
        products, total, total_pages = await product_service.list_products(
            page=1,
            page_size=20
        )
        
        assert len(products) == 1
        assert total == 1
        assert total_pages == 1
        assert products[0].id == sample_product.id
        mock_product_repo.list_with_filters.assert_called_once()
    
    async def test_list_products_with_filters(
        self,
        product_service,
        mock_product_repo,
        sample_product,
        sample_category
    ):
        """Test product listing with filters"""
        mock_product_repo.list_with_filters.return_value = ([sample_product], 1)
        
        products, total, total_pages = await product_service.list_products(
            category_id=sample_category.id,
            min_price=Decimal("50000"),
            max_price=Decimal("200000"),
            condition=ProductCondition.NEW,
            min_rating=4.0,
            page=1,
            page_size=20
        )
        
        assert len(products) == 1
        mock_product_repo.list_with_filters.assert_called_once_with(
            shop_id=None,
            category_id=sample_category.id,
            min_price=Decimal("50000"),
            max_price=Decimal("200000"),
            condition=ProductCondition.NEW,
            min_rating=4.0,
            is_active=True,
            search_query=None,
            sort_by="created_at",
            sort_order="desc",
            skip=0,
            limit=20
        )
    
    async def test_list_products_pagination(
        self,
        product_service,
        mock_product_repo
    ):
        """Test pagination calculations"""
        mock_product_repo.list_with_filters.return_value = ([], 45)
        
        products, total, total_pages = await product_service.list_products(
            page=2,
            page_size=20
        )
        
        assert total == 45
        assert total_pages == 3  # ceil(45 / 20)
        mock_product_repo.list_with_filters.assert_called_once_with(
            shop_id=None,
            category_id=None,
            min_price=None,
            max_price=None,
            condition=None,
            min_rating=None,
            is_active=True,
            search_query=None,
            sort_by="created_at",
            sort_order="desc",
            skip=20,  # (page - 1) * page_size = (2 - 1) * 20
            limit=20
        )


class TestGetProductDetail:
    """Tests for get_product_detail method"""
    
    async def test_get_product_detail_success(
        self,
        product_service,
        mock_product_repo,
        sample_product
    ):
        """Test successful product detail retrieval"""
        sample_product.variants = []
        mock_product_repo.get_with_variants.return_value = sample_product
        
        product = await product_service.get_product_detail(sample_product.id)
        
        assert product.id == sample_product.id
        assert product.title == "Test Product"
        mock_product_repo.get_with_variants.assert_called_once_with(sample_product.id)
    
    async def test_get_product_detail_not_found(
        self,
        product_service,
        mock_product_repo
    ):
        """Test product not found"""
        mock_product_repo.get_with_variants.return_value = None
        
        with pytest.raises(HTTPException) as exc_info:
            await product_service.get_product_detail(uuid4())
        
        assert exc_info.value.status_code == 404
        assert "not found" in str(exc_info.value.detail).lower()
    
    async def test_get_product_detail_inactive(
        self,
        product_service,
        mock_product_repo,
        sample_product
    ):
        """Test inactive product returns 404"""
        sample_product.is_active = False
        mock_product_repo.get_with_variants.return_value = sample_product
        
        with pytest.raises(HTTPException) as exc_info:
            await product_service.get_product_detail(sample_product.id)
        
        assert exc_info.value.status_code == 404
        assert "not available" in str(exc_info.value.detail).lower()


class TestSearchAutocomplete:
    """Tests for search_autocomplete method"""
    
    async def test_search_autocomplete_success(
        self,
        product_service,
        mock_product_repo
    ):
        """Test successful autocomplete"""
        mock_product_repo.search_autocomplete.return_value = [
            "iPhone 15", "iPhone 14", "iPhone 13"
        ]
        
        results = await product_service.search_autocomplete("iPhone")
        
        assert len(results) == 3
        assert "iPhone 15" in results
        mock_product_repo.search_autocomplete.assert_called_once_with("iPhone", 10)
    
    async def test_search_autocomplete_short_query(
        self,
        product_service,
        mock_product_repo
    ):
        """Test autocomplete with short query returns empty"""
        results = await product_service.search_autocomplete("i")
        
        assert results == []
        mock_product_repo.search_autocomplete.assert_not_called()


class TestCreateProduct:
    """Tests for create_product method (seller)"""
    
    async def test_create_product_success(
        self,
        product_service,
        mock_product_repo,
        mock_shop_repo,
        mock_category_repo,
        mock_variant_repo,
        sample_shop,
        sample_category
    ):
        """Test successful product creation"""
        user_id = sample_shop.user_id
        mock_shop_repo.get_by_user_id.return_value = sample_shop
        mock_category_repo.get.return_value = sample_category
        
        created_product = Product(
            id=uuid4(),
            shop_id=sample_shop.id,
            category_id=sample_category.id,
            title="New Product",
            base_price=Decimal("150000"),
            total_stock=20,
            is_active=True,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        created_product.variants = []
        
        mock_product_repo.create.return_value = created_product
        mock_product_repo.get_with_variants.return_value = created_product
        
        product_data = ProductCreate(
            title="New Product",
            category_id=sample_category.id,
            base_price=Decimal("150000"),
            total_stock=20
        )
        
        result = await product_service.create_product(user_id, product_data)
        
        assert result.id == created_product.id
        assert result.title == "New Product"
        mock_shop_repo.get_by_user_id.assert_called_once_with(user_id)
        mock_product_repo.create.assert_called_once()
    
    async def test_create_product_no_shop(
        self,
        product_service,
        mock_shop_repo
    ):
        """Test product creation fails without shop"""
        mock_shop_repo.get_by_user_id.return_value = None
        
        product_data = ProductCreate(
            title="New Product",
            base_price=Decimal("150000")
        )
        
        with pytest.raises(HTTPException) as exc_info:
            await product_service.create_product(uuid4(), product_data)
        
        assert exc_info.value.status_code == 403
        assert "shop" in str(exc_info.value.detail).lower()
    
    async def test_create_product_inactive_shop(
        self,
        product_service,
        mock_shop_repo,
        sample_shop
    ):
        """Test product creation fails with inactive shop"""
        sample_shop.status = ShopStatus.SUSPENDED
        mock_shop_repo.get_by_user_id.return_value = sample_shop
        
        product_data = ProductCreate(
            title="New Product",
            base_price=Decimal("150000")
        )
        
        with pytest.raises(HTTPException) as exc_info:
            await product_service.create_product(sample_shop.user_id, product_data)
        
        assert exc_info.value.status_code == 403
        assert "active" in str(exc_info.value.detail).lower()
    
    async def test_create_product_invalid_category(
        self,
        product_service,
        mock_shop_repo,
        mock_category_repo,
        sample_shop
    ):
        """Test product creation fails with invalid category"""
        mock_shop_repo.get_by_user_id.return_value = sample_shop
        mock_category_repo.get.return_value = None
        
        product_data = ProductCreate(
            title="New Product",
            category_id=uuid4(),
            base_price=Decimal("150000")
        )
        
        with pytest.raises(HTTPException) as exc_info:
            await product_service.create_product(sample_shop.user_id, product_data)
        
        assert exc_info.value.status_code == 404
        assert "category" in str(exc_info.value.detail).lower()


class TestUpdateProduct:
    """Tests for update_product method (seller)"""
    
    async def test_update_product_success(
        self,
        product_service,
        mock_product_repo,
        mock_shop_repo,
        sample_product,
        sample_shop
    ):
        """Test successful product update"""
        sample_shop.user_id = uuid4()
        mock_product_repo.get.return_value = sample_product
        mock_shop_repo.get.return_value = sample_shop
        
        update_data = ProductUpdate(
            title="Updated Product",
            base_price=Decimal("200000")
        )
        
        updated_product = Product(**sample_product.__dict__)
        updated_product.title = "Updated Product"
        updated_product.base_price = Decimal("200000")
        mock_product_repo.update.return_value = updated_product
        
        result = await product_service.update_product(
            sample_shop.user_id, sample_product.id, update_data
        )
        
        assert result.title == "Updated Product"
        mock_product_repo.update.assert_called_once()
    
    async def test_update_product_not_found(
        self,
        product_service,
        mock_product_repo
    ):
        """Test update fails with non-existent product"""
        mock_product_repo.get.return_value = None
        
        update_data = ProductUpdate(title="Updated")
        
        with pytest.raises(HTTPException) as exc_info:
            await product_service.update_product(uuid4(), uuid4(), update_data)
        
        assert exc_info.value.status_code == 404
    
    async def test_update_product_wrong_owner(
        self,
        product_service,
        mock_product_repo,
        mock_shop_repo,
        sample_product,
        sample_shop
    ):
        """Test update fails with wrong owner"""
        mock_product_repo.get.return_value = sample_product
        mock_shop_repo.get.return_value = sample_shop
        
        different_user_id = uuid4()
        update_data = ProductUpdate(title="Updated")
        
        with pytest.raises(HTTPException) as exc_info:
            await product_service.update_product(
                different_user_id, sample_product.id, update_data
            )
        
        assert exc_info.value.status_code == 403
        assert "your own" in str(exc_info.value.detail).lower()


class TestDeleteProduct:
    """Tests for delete_product method (seller)"""
    
    async def test_delete_product_success(
        self,
        product_service,
        mock_product_repo,
        mock_shop_repo,
        sample_product,
        sample_shop
    ):
        """Test successful product deletion"""
        sample_shop.user_id = uuid4()
        mock_product_repo.get.return_value = sample_product
        mock_shop_repo.get.return_value = sample_shop
        mock_product_repo.delete.return_value = None
        
        await product_service.delete_product(sample_shop.user_id, sample_product.id)
        
        mock_product_repo.delete.assert_called_once_with(sample_product.id)
    
    async def test_delete_product_wrong_owner(
        self,
        product_service,
        mock_product_repo,
        mock_shop_repo,
        sample_product,
        sample_shop
    ):
        """Test delete fails with wrong owner"""
        mock_product_repo.get.return_value = sample_product
        mock_shop_repo.get.return_value = sample_shop
        
        different_user_id = uuid4()
        
        with pytest.raises(HTTPException) as exc_info:
            await product_service.delete_product(different_user_id, sample_product.id)
        
        assert exc_info.value.status_code == 403


class TestListShopProducts:
    """Tests for list_shop_products method"""
    
    async def test_list_shop_products_success(
        self,
        product_service,
        mock_shop_repo,
        mock_product_repo,
        sample_shop,
        sample_product
    ):
        """Test successful shop product listing"""
        mock_shop_repo.get_by_user_id.return_value = sample_shop
        mock_product_repo.get_by_shop.return_value = ([sample_product], 1)
        
        products, total, total_pages = await product_service.list_shop_products(
            sample_shop.user_id, page=1, page_size=20
        )
        
        assert len(products) == 1
        assert total == 1
        assert total_pages == 1
        mock_shop_repo.get_by_user_id.assert_called_once_with(sample_shop.user_id)
        mock_product_repo.get_by_shop.assert_called_once_with(
            shop_id=sample_shop.id, skip=0, limit=20
        )
    
    async def test_list_shop_products_no_shop(
        self,
        product_service,
        mock_shop_repo
    ):
        """Test listing fails without shop"""
        mock_shop_repo.get_by_user_id.return_value = None
        
        with pytest.raises(HTTPException) as exc_info:
            await product_service.list_shop_products(uuid4())
        
        assert exc_info.value.status_code == 404
        assert "shop" in str(exc_info.value.detail).lower()


class TestVariantManagement:
    """Tests for variant CRUD operations"""
    
    async def test_create_variant_success(
        self,
        product_service,
        mock_product_repo,
        mock_shop_repo,
        mock_variant_repo,
        sample_product,
        sample_shop
    ):
        """Test successful variant creation"""
        sample_shop.user_id = uuid4()
        mock_product_repo.get.return_value = sample_product
        mock_shop_repo.get.return_value = sample_shop
        mock_variant_repo.get_by_sku.return_value = None
        
        created_variant = ProductVariant(
            id=uuid4(),
            product_id=sample_product.id,
            name="Blue - Small",
            sku="PROD-BLUE-S",
            price=Decimal("120000"),
            stock=3,
            is_active=True,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        mock_variant_repo.create.return_value = created_variant
        
        variant_data = ProductVariantCreate(
            name="Blue - Small",
            sku="PROD-BLUE-S",
            price=Decimal("120000"),
            stock=3
        )
        
        result = await product_service.create_variant(
            sample_shop.user_id, sample_product.id, variant_data
        )
        
        assert result.id == created_variant.id
        assert result.sku == "PROD-BLUE-S"
        mock_variant_repo.create.assert_called_once()
    
    async def test_create_variant_duplicate_sku(
        self,
        product_service,
        mock_product_repo,
        mock_shop_repo,
        mock_variant_repo,
        sample_product,
        sample_shop,
        sample_variant
    ):
        """Test variant creation fails with duplicate SKU"""
        sample_shop.user_id = uuid4()
        mock_product_repo.get.return_value = sample_product
        mock_shop_repo.get.return_value = sample_shop
        mock_variant_repo.get_by_sku.return_value = sample_variant
        
        variant_data = ProductVariantCreate(
            name="Blue - Small",
            sku=sample_variant.sku,  # Duplicate SKU
            price=Decimal("120000"),
            stock=3
        )
        
        with pytest.raises(HTTPException) as exc_info:
            await product_service.create_variant(
                sample_shop.user_id, sample_product.id, variant_data
            )
        
        assert exc_info.value.status_code == 400
        assert "sku" in str(exc_info.value.detail).lower()
