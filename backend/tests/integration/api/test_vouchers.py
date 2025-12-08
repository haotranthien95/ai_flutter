"""
Integration tests for Voucher API endpoints
"""
from datetime import datetime, timedelta
from decimal import Decimal
import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, UserRole
from app.models.shop import Shop, ShopStatus
from app.models.voucher import Voucher, VoucherType


# Fixtures
@pytest.fixture
async def seller_user(db: AsyncSession) -> User:
    """Create a seller user"""
    user = User(
        email="seller@example.com",
        username="seller",
        full_name="Seller User",
        hashed_password="hashed",
        role=UserRole.SELLER
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


@pytest.fixture
async def buyer_user(db: AsyncSession) -> User:
    """Create a buyer user"""
    user = User(
        email="buyer@example.com",
        username="buyer",
        full_name="Buyer User",
        hashed_password="hashed",
        role=UserRole.BUYER
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


@pytest.fixture
async def test_shop(db: AsyncSession, seller_user: User) -> Shop:
    """Create a test shop"""
    shop = Shop(
        owner_id=seller_user.id,
        shop_name="Test Shop",
        description="Test shop description",
        status=ShopStatus.ACTIVE,
        shipping_fee=Decimal("5.00")
    )
    db.add(shop)
    await db.commit()
    await db.refresh(shop)
    return shop


@pytest.fixture
async def active_percentage_voucher(db: AsyncSession, test_shop: Shop) -> Voucher:
    """Create an active percentage voucher"""
    voucher = Voucher(
        shop_id=test_shop.id,
        code="SAVE20",
        title="20% Off",
        description="Save 20% on your order",
        type=VoucherType.PERCENTAGE,
        value=Decimal("20"),
        min_order_value=Decimal("100"),
        max_discount=Decimal("50"),
        usage_limit=100,
        usage_count=0,
        start_date=datetime.utcnow() - timedelta(days=1),
        end_date=datetime.utcnow() + timedelta(days=30),
        is_active=True
    )
    db.add(voucher)
    await db.commit()
    await db.refresh(voucher)
    return voucher


@pytest.fixture
async def active_fixed_voucher(db: AsyncSession, test_shop: Shop) -> Voucher:
    """Create an active fixed amount voucher"""
    voucher = Voucher(
        shop_id=test_shop.id,
        code="FLAT50",
        title="$50 Off",
        description="Save $50 on your order",
        type=VoucherType.FIXED_AMOUNT,
        value=Decimal("50"),
        min_order_value=Decimal("200"),
        max_discount=None,
        usage_limit=None,
        usage_count=0,
        start_date=datetime.utcnow() - timedelta(days=1),
        end_date=datetime.utcnow() + timedelta(days=30),
        is_active=True
    )
    db.add(voucher)
    await db.commit()
    await db.refresh(voucher)
    return voucher


@pytest.fixture
async def inactive_voucher(db: AsyncSession, test_shop: Shop) -> Voucher:
    """Create an inactive voucher"""
    voucher = Voucher(
        shop_id=test_shop.id,
        code="INACTIVE",
        title="Inactive Voucher",
        type=VoucherType.PERCENTAGE,
        value=Decimal("10"),
        start_date=datetime.utcnow(),
        end_date=datetime.utcnow() + timedelta(days=30),
        is_active=False
    )
    db.add(voucher)
    await db.commit()
    await db.refresh(voucher)
    return voucher


# Test Buyer Endpoints
class TestValidateVoucher:
    """Tests for POST /vouchers/validate"""
    
    @pytest.mark.asyncio
    async def test_validate_percentage_voucher_success(
        self,
        client: AsyncClient,
        active_percentage_voucher: Voucher
    ):
        """Test successful validation of percentage voucher"""
        response = await client.post(
            "/api/v1/vouchers/validate",
            json={
                "code": "SAVE20",
                "shop_id": str(active_percentage_voucher.shop_id),
                "subtotal": "150.00"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["valid"] is True
        assert Decimal(data["discount_amount"]) == Decimal("30")  # 20% of 150
        assert data["voucher"]["code"] == "SAVE20"
    
    @pytest.mark.asyncio
    async def test_validate_fixed_voucher_success(
        self,
        client: AsyncClient,
        active_fixed_voucher: Voucher
    ):
        """Test successful validation of fixed voucher"""
        response = await client.post(
            "/api/v1/vouchers/validate",
            json={
                "code": "FLAT50",
                "shop_id": str(active_fixed_voucher.shop_id),
                "subtotal": "250.00"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["valid"] is True
        assert Decimal(data["discount_amount"]) == Decimal("50")
    
    @pytest.mark.asyncio
    async def test_validate_voucher_with_max_discount_cap(
        self,
        client: AsyncClient,
        active_percentage_voucher: Voucher
    ):
        """Test percentage voucher with max discount cap"""
        response = await client.post(
            "/api/v1/vouchers/validate",
            json={
                "code": "SAVE20",
                "shop_id": str(active_percentage_voucher.shop_id),
                "subtotal": "500.00"  # Would be 100, but capped at 50
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["valid"] is True
        assert Decimal(data["discount_amount"]) == Decimal("50")
    
    @pytest.mark.asyncio
    async def test_validate_voucher_not_found(
        self,
        client: AsyncClient,
        test_shop: Shop
    ):
        """Test validation with non-existent voucher"""
        response = await client.post(
            "/api/v1/vouchers/validate",
            json={
                "code": "NONEXISTENT",
                "shop_id": str(test_shop.id),
                "subtotal": "100.00"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["valid"] is False
        assert "not found" in data["message"]
    
    @pytest.mark.asyncio
    async def test_validate_inactive_voucher(
        self,
        client: AsyncClient,
        inactive_voucher: Voucher
    ):
        """Test validation with inactive voucher"""
        response = await client.post(
            "/api/v1/vouchers/validate",
            json={
                "code": "INACTIVE",
                "shop_id": str(inactive_voucher.shop_id),
                "subtotal": "100.00"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["valid"] is False
        assert "not active" in data["message"]
    
    @pytest.mark.asyncio
    async def test_validate_voucher_below_min_order(
        self,
        client: AsyncClient,
        active_percentage_voucher: Voucher
    ):
        """Test validation with order below minimum"""
        response = await client.post(
            "/api/v1/vouchers/validate",
            json={
                "code": "SAVE20",
                "shop_id": str(active_percentage_voucher.shop_id),
                "subtotal": "50.00"  # Below min_order_value of 100
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["valid"] is False
        assert "Minimum order value" in data["message"]


class TestGetAvailableVouchers:
    """Tests for GET /vouchers/available"""
    
    @pytest.mark.asyncio
    async def test_get_available_vouchers_success(
        self,
        client: AsyncClient,
        test_shop: Shop,
        active_percentage_voucher: Voucher,
        active_fixed_voucher: Voucher,
        inactive_voucher: Voucher
    ):
        """Test getting available vouchers"""
        response = await client.get(
            "/api/v1/vouchers/available",
            params={
                "shop_id": str(test_shop.id),
                "subtotal": "250.00"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 2  # Only active vouchers with min order met
        assert len(data["available_vouchers"]) == 2
        
        # Verify both active vouchers are returned
        codes = [v["code"] for v in data["available_vouchers"]]
        assert "SAVE20" in codes
        assert "FLAT50" in codes
    
    @pytest.mark.asyncio
    async def test_get_available_vouchers_below_min_order(
        self,
        client: AsyncClient,
        test_shop: Shop,
        active_percentage_voucher: Voucher,
        active_fixed_voucher: Voucher
    ):
        """Test getting available vouchers with low subtotal"""
        response = await client.get(
            "/api/v1/vouchers/available",
            params={
                "shop_id": str(test_shop.id),
                "subtotal": "150.00"  # Meets SAVE20 but not FLAT50 (min 200)
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert data["available_vouchers"][0]["code"] == "SAVE20"
    
    @pytest.mark.asyncio
    async def test_get_available_vouchers_none_available(
        self,
        client: AsyncClient,
        test_shop: Shop
    ):
        """Test getting available vouchers when none available"""
        response = await client.get(
            "/api/v1/vouchers/available",
            params={
                "shop_id": str(test_shop.id),
                "subtotal": "50.00"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 0
        assert len(data["available_vouchers"]) == 0


# Test Seller Endpoints
class TestCreateVoucher:
    """Tests for POST /seller/shops/{shop_id}/vouchers"""
    
    @pytest.mark.asyncio
    async def test_create_percentage_voucher_success(
        self,
        client: AsyncClient,
        seller_user: User,
        test_shop: Shop,
        seller_token: str
    ):
        """Test successful creation of percentage voucher"""
        voucher_data = {
            "code": "NEWCODE20",
            "title": "New 20% Off",
            "description": "Test voucher",
            "type": "percentage",
            "value": "20",
            "min_order_value": "100",
            "max_discount": "50",
            "usage_limit": 100,
            "start_date": datetime.utcnow().isoformat(),
            "end_date": (datetime.utcnow() + timedelta(days=30)).isoformat(),
            "is_active": True
        }
        
        response = await client.post(
            f"/api/v1/seller/shops/{test_shop.id}/vouchers",
            json=voucher_data,
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["code"] == "NEWCODE20"
        assert data["type"] == "percentage"
        assert Decimal(data["value"]) == Decimal("20")
    
    @pytest.mark.asyncio
    async def test_create_fixed_voucher_success(
        self,
        client: AsyncClient,
        test_shop: Shop,
        seller_token: str
    ):
        """Test successful creation of fixed amount voucher"""
        voucher_data = {
            "code": "NEWFIXED",
            "title": "New $30 Off",
            "type": "fixed_amount",
            "value": "30",
            "min_order_value": "100",
            "start_date": datetime.utcnow().isoformat(),
            "end_date": (datetime.utcnow() + timedelta(days=30)).isoformat(),
            "is_active": True
        }
        
        response = await client.post(
            f"/api/v1/seller/shops/{test_shop.id}/vouchers",
            json=voucher_data,
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["code"] == "NEWFIXED"
        assert data["type"] == "fixed_amount"
    
    @pytest.mark.asyncio
    async def test_create_voucher_duplicate_code(
        self,
        client: AsyncClient,
        test_shop: Shop,
        seller_token: str,
        active_percentage_voucher: Voucher
    ):
        """Test creating voucher with duplicate code"""
        voucher_data = {
            "code": "SAVE20",  # Already exists
            "title": "Duplicate",
            "type": "percentage",
            "value": "10",
            "start_date": datetime.utcnow().isoformat(),
            "end_date": (datetime.utcnow() + timedelta(days=30)).isoformat()
        }
        
        response = await client.post(
            f"/api/v1/seller/shops/{test_shop.id}/vouchers",
            json=voucher_data,
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        
        assert response.status_code == 400
        assert "already exists" in response.json()["detail"]
    
    @pytest.mark.asyncio
    async def test_create_voucher_unauthorized(
        self,
        client: AsyncClient,
        test_shop: Shop
    ):
        """Test creating voucher without authentication"""
        voucher_data = {
            "code": "TEST",
            "title": "Test",
            "type": "percentage",
            "value": "10",
            "start_date": datetime.utcnow().isoformat(),
            "end_date": (datetime.utcnow() + timedelta(days=1)).isoformat()
        }
        
        response = await client.post(
            f"/api/v1/seller/shops/{test_shop.id}/vouchers",
            json=voucher_data
        )
        
        assert response.status_code == 403  # No auth header


class TestListShopVouchers:
    """Tests for GET /seller/shops/{shop_id}/vouchers"""
    
    @pytest.mark.asyncio
    async def test_list_shop_vouchers_success(
        self,
        client: AsyncClient,
        test_shop: Shop,
        seller_token: str,
        active_percentage_voucher: Voucher,
        active_fixed_voucher: Voucher,
        inactive_voucher: Voucher
    ):
        """Test listing all shop vouchers"""
        response = await client.get(
            f"/api/v1/seller/shops/{test_shop.id}/vouchers",
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 3
        assert len(data["items"]) == 3
    
    @pytest.mark.asyncio
    async def test_list_shop_vouchers_active_filter(
        self,
        client: AsyncClient,
        test_shop: Shop,
        seller_token: str,
        active_percentage_voucher: Voucher,
        inactive_voucher: Voucher
    ):
        """Test listing vouchers with active filter"""
        response = await client.get(
            f"/api/v1/seller/shops/{test_shop.id}/vouchers",
            params={"is_active": True},
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1
        assert all(v["is_active"] for v in data["items"])
    
    @pytest.mark.asyncio
    async def test_list_shop_vouchers_pagination(
        self,
        client: AsyncClient,
        test_shop: Shop,
        seller_token: str,
        active_percentage_voucher: Voucher
    ):
        """Test voucher list pagination"""
        response = await client.get(
            f"/api/v1/seller/shops/{test_shop.id}/vouchers",
            params={"page": 1, "page_size": 2},
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 1
        assert data["page_size"] == 2


class TestUpdateVoucher:
    """Tests for PATCH /seller/vouchers/{voucher_id}"""
    
    @pytest.mark.asyncio
    async def test_update_voucher_success(
        self,
        client: AsyncClient,
        seller_token: str,
        active_percentage_voucher: Voucher,
        db: AsyncSession
    ):
        """Test successful voucher update"""
        update_data = {
            "title": "Updated Title",
            "value": "25"
        }
        
        response = await client.patch(
            f"/api/v1/seller/vouchers/{active_percentage_voucher.id}",
            json=update_data,
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["title"] == "Updated Title"
        assert Decimal(data["value"]) == Decimal("25")
        
        # Verify in database
        await db.refresh(active_percentage_voucher)
        assert active_percentage_voucher.title == "Updated Title"
    
    @pytest.mark.asyncio
    async def test_update_voucher_not_found(
        self,
        client: AsyncClient,
        seller_token: str,
        db: AsyncSession
    ):
        """Test updating non-existent voucher"""
        from uuid import uuid4
        
        response = await client.patch(
            f"/api/v1/seller/vouchers/{uuid4()}",
            json={"title": "New Title"},
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        
        assert response.status_code == 404


class TestDeleteVoucher:
    """Tests for DELETE /seller/vouchers/{voucher_id}"""
    
    @pytest.mark.asyncio
    async def test_delete_voucher_success(
        self,
        client: AsyncClient,
        seller_token: str,
        active_percentage_voucher: Voucher,
        db: AsyncSession
    ):
        """Test successful voucher deletion"""
        voucher_id = active_percentage_voucher.id
        
        response = await client.delete(
            f"/api/v1/seller/vouchers/{voucher_id}",
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        
        assert response.status_code == 204
        
        # Verify voucher is deleted
        result = await db.execute(
            select(Voucher).where(Voucher.id == voucher_id)
        )
        voucher = result.scalar_one_or_none()
        assert voucher is None
    
    @pytest.mark.asyncio
    async def test_delete_voucher_not_found(
        self,
        client: AsyncClient,
        seller_token: str
    ):
        """Test deleting non-existent voucher"""
        from uuid import uuid4
        
        response = await client.delete(
            f"/api/v1/seller/vouchers/{uuid4()}",
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        
        assert response.status_code == 404


# Test Complete Workflow
class TestVoucherWorkflow:
    """Tests for complete voucher workflow"""
    
    @pytest.mark.asyncio
    async def test_complete_voucher_lifecycle(
        self,
        client: AsyncClient,
        seller_token: str,
        test_shop: Shop,
        db: AsyncSession
    ):
        """Test complete voucher lifecycle: create, validate, apply, delete"""
        
        # 1. Create voucher
        create_data = {
            "code": "LIFECYCLE",
            "title": "Lifecycle Test",
            "type": "percentage",
            "value": "15",
            "min_order_value": "100",
            "usage_limit": 5,
            "start_date": datetime.utcnow().isoformat(),
            "end_date": (datetime.utcnow() + timedelta(days=30)).isoformat(),
            "is_active": True
        }
        
        response = await client.post(
            f"/api/v1/seller/shops/{test_shop.id}/vouchers",
            json=create_data,
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        assert response.status_code == 201
        voucher_id = response.json()["id"]
        
        # 2. Validate voucher
        validate_response = await client.post(
            "/api/v1/vouchers/validate",
            json={
                "code": "LIFECYCLE",
                "shop_id": str(test_shop.id),
                "subtotal": "150.00"
            }
        )
        assert validate_response.status_code == 200
        validate_data = validate_response.json()
        assert validate_data["valid"] is True
        assert Decimal(validate_data["discount_amount"]) == Decimal("22.5")  # 15% of 150
        
        # 3. Check available vouchers
        available_response = await client.get(
            "/api/v1/vouchers/available",
            params={"shop_id": str(test_shop.id), "subtotal": "150.00"}
        )
        assert available_response.status_code == 200
        available_data = available_response.json()
        codes = [v["code"] for v in available_data["available_vouchers"]]
        assert "LIFECYCLE" in codes
        
        # 4. Update voucher
        update_response = await client.patch(
            f"/api/v1/seller/vouchers/{voucher_id}",
            json={"is_active": False},
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        assert update_response.status_code == 200
        assert update_response.json()["is_active"] is False
        
        # 5. Verify voucher is now invalid
        validate_inactive = await client.post(
            "/api/v1/vouchers/validate",
            json={
                "code": "LIFECYCLE",
                "shop_id": str(test_shop.id),
                "subtotal": "150.00"
            }
        )
        assert validate_inactive.json()["valid"] is False
        
        # 6. Delete voucher
        delete_response = await client.delete(
            f"/api/v1/seller/vouchers/{voucher_id}",
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        assert delete_response.status_code == 204
