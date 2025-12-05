"""
Integration tests for Review API endpoints
"""
from datetime import datetime
from decimal import Decimal
import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User, UserRole
from app.models.shop import Shop, ShopStatus
from app.models.product import Product, ProductCondition
from app.models.category import Category
from app.models.order import Order, OrderItem, OrderStatus, PaymentMethod, PaymentStatus
from app.models.review import Review


# Fixtures
@pytest.fixture
async def category(db: AsyncSession) -> Category:
    """Create a test category"""
    cat = Category(name="Electronics", description="Test category")
    db.add(cat)
    await db.commit()
    await db.refresh(cat)
    return cat


@pytest.fixture
async def seller_user(db: AsyncSession) -> User:
    """Create a seller user"""
    user = User(
        phone_number="+1234567890",
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
        phone_number="+0987654321",
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
        status=ShopStatus.ACTIVE,
        shipping_fee=Decimal("5.00")
    )
    db.add(shop)
    await db.commit()
    await db.refresh(shop)
    return shop


@pytest.fixture
async def test_product(db: AsyncSession, test_shop: Shop, category: Category) -> Product:
    """Create a test product"""
    product = Product(
        shop_id=test_shop.id,
        category_id=category.id,
        title="Test Product",
        description="Test description",
        price=Decimal("100.00"),
        condition=ProductCondition.NEW,
        stock=10,
        rating=0.0,
        total_ratings=0
    )
    db.add(product)
    await db.commit()
    await db.refresh(product)
    return product


@pytest.fixture
async def delivered_order(
    db: AsyncSession,
    buyer_user: User,
    test_shop: Shop,
    test_product: Product
) -> Order:
    """Create a delivered order"""
    order = Order(
        buyer_id=buyer_user.id,
        shop_id=test_shop.id,
        order_number="ORD-20251205-TEST01",
        status=OrderStatus.DELIVERED,
        payment_method=PaymentMethod.COD,
        payment_status=PaymentStatus.PAID,
        subtotal=Decimal("100.00"),
        shipping_fee=Decimal("5.00"),
        total=Decimal("105.00"),
        shipping_address={"address": "123 Test St"}
    )
    db.add(order)
    await db.flush()
    
    # Add order item
    item = OrderItem(
        order_id=order.id,
        product_id=test_product.id,
        quantity=1,
        price=Decimal("100.00"),
        product_snapshot={"title": "Test Product"}
    )
    db.add(item)
    await db.commit()
    await db.refresh(order)
    return order


# Test Create Review
class TestCreateReview:
    """Tests for POST /reviews"""
    
    @pytest.mark.asyncio
    async def test_create_review_success(
        self,
        client: AsyncClient,
        buyer_user: User,
        buyer_token: str,
        test_product: Product,
        delivered_order: Order,
        db: AsyncSession
    ):
        """Test successful review creation"""
        review_data = {
            "product_id": str(test_product.id),
            "order_id": str(delivered_order.id),
            "rating": 5,
            "content": "Excellent product! Highly recommended.",
            "images": None
        }
        
        response = await client.post(
            "/api/v1/reviews",
            json=review_data,
            headers={"Authorization": f"Bearer {buyer_token}"}
        )
        
        assert response.status_code == 201
        data = response.json()
        assert data["rating"] == 5
        assert data["content"] == "Excellent product! Highly recommended."
        assert data["is_verified_purchase"] is True
        assert data["user"]["username"] == "buyer"
        
        # Verify product rating was updated
        await db.refresh(test_product)
        assert test_product.rating == 5.0
        assert test_product.total_ratings == 1
    
    @pytest.mark.asyncio
    async def test_create_review_with_images(
        self,
        client: AsyncClient,
        buyer_token: str,
        test_product: Product,
        delivered_order: Order
    ):
        """Test review creation with images"""
        review_data = {
            "product_id": str(test_product.id),
            "order_id": str(delivered_order.id),
            "rating": 4,
            "content": "Good product",
            "images": [
                "https://example.com/img1.jpg",
                "https://example.com/img2.jpg"
            ]
        }
        
        response = await client.post(
            "/api/v1/reviews",
            json=review_data,
            headers={"Authorization": f"Bearer {buyer_token}"}
        )
        
        assert response.status_code == 201
        data = response.json()
        assert len(data["images"]) == 2
    
    @pytest.mark.asyncio
    async def test_create_review_duplicate(
        self,
        client: AsyncClient,
        buyer_token: str,
        test_product: Product,
        delivered_order: Order
    ):
        """Test preventing duplicate reviews"""
        review_data = {
            "product_id": str(test_product.id),
            "order_id": str(delivered_order.id),
            "rating": 5,
            "content": "First review"
        }
        
        # Create first review
        response1 = await client.post(
            "/api/v1/reviews",
            json=review_data,
            headers={"Authorization": f"Bearer {buyer_token}"}
        )
        assert response1.status_code == 201
        
        # Try to create duplicate
        review_data["content"] = "Second review (should fail)"
        response2 = await client.post(
            "/api/v1/reviews",
            json=review_data,
            headers={"Authorization": f"Bearer {buyer_token}"}
        )
        
        assert response2.status_code == 400
        assert "already reviewed" in response2.json()["detail"]
    
    @pytest.mark.asyncio
    async def test_create_review_order_not_delivered(
        self,
        client: AsyncClient,
        buyer_user: User,
        buyer_token: str,
        test_shop: Shop,
        test_product: Product,
        db: AsyncSession
    ):
        """Test review creation for order not yet delivered"""
        # Create pending order
        pending_order = Order(
            buyer_id=buyer_user.id,
            shop_id=test_shop.id,
            order_number="ORD-20251205-PEND",
            status=OrderStatus.PENDING,
            payment_method=PaymentMethod.COD,
            payment_status=PaymentStatus.PENDING,
            subtotal=Decimal("100.00"),
            shipping_fee=Decimal("5.00"),
            total=Decimal("105.00"),
            shipping_address={}
        )
        db.add(pending_order)
        await db.flush()
        
        item = OrderItem(
            order_id=pending_order.id,
            product_id=test_product.id,
            quantity=1,
            price=Decimal("100.00"),
            product_snapshot={}
        )
        db.add(item)
        await db.commit()
        
        review_data = {
            "product_id": str(test_product.id),
            "order_id": str(pending_order.id),
            "rating": 5,
            "content": "Too early"
        }
        
        response = await client.post(
            "/api/v1/reviews",
            json=review_data,
            headers={"Authorization": f"Bearer {buyer_token}"}
        )
        
        assert response.status_code == 400
        assert "delivered or completed" in response.json()["detail"]
    
    @pytest.mark.asyncio
    async def test_create_review_unauthorized(
        self,
        client: AsyncClient,
        test_product: Product,
        delivered_order: Order
    ):
        """Test review creation without authentication"""
        review_data = {
            "product_id": str(test_product.id),
            "order_id": str(delivered_order.id),
            "rating": 5,
            "content": "Test"
        }
        
        response = await client.post(
            "/api/v1/reviews",
            json=review_data
        )
        
        assert response.status_code == 403


# Test Get Product Reviews
class TestGetProductReviews:
    """Tests for GET /products/{id}/reviews"""
    
    @pytest.mark.asyncio
    async def test_get_product_reviews_success(
        self,
        client: AsyncClient,
        buyer_user: User,
        test_product: Product,
        delivered_order: Order,
        db: AsyncSession
    ):
        """Test getting product reviews"""
        # Create a review
        review = Review(
            user_id=buyer_user.id,
            product_id=test_product.id,
            order_id=delivered_order.id,
            rating=5,
            content="Great product!",
            is_verified_purchase=True,
            is_visible=True
        )
        db.add(review)
        await db.commit()
        
        response = await client.get(
            f"/api/v1/products/{test_product.id}/reviews"
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert len(data["items"]) == 1
        assert data["items"][0]["rating"] == 5
        assert data["average_rating"] == 5.0
        assert data["rating_distribution"]["5"] == 1
    
    @pytest.mark.asyncio
    async def test_get_product_reviews_with_rating_filter(
        self,
        client: AsyncClient,
        buyer_user: User,
        test_product: Product,
        delivered_order: Order,
        db: AsyncSession
    ):
        """Test filtering reviews by rating"""
        # Create reviews with different ratings
        for rating in [3, 4, 5]:
            review = Review(
                user_id=buyer_user.id,
                product_id=test_product.id,
                order_id=delivered_order.id,
                rating=rating,
                content=f"Rating {rating}",
                is_verified_purchase=True,
                is_visible=True
            )
            db.add(review)
            # Modify user_id to avoid unique constraint
            review.user_id = buyer_user.id if rating == 5 else None
        
        await db.commit()
        
        # Filter by rating 5
        response = await client.get(
            f"/api/v1/products/{test_product.id}/reviews",
            params={"rating": 5}
        )
        
        assert response.status_code == 200
        data = response.json()
        # Should only return 5-star reviews
        assert all(item["rating"] == 5 for item in data["items"])
    
    @pytest.mark.asyncio
    async def test_get_product_reviews_pagination(
        self,
        client: AsyncClient,
        test_product: Product
    ):
        """Test reviews pagination"""
        response = await client.get(
            f"/api/v1/products/{test_product.id}/reviews",
            params={"page": 1, "page_size": 10}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 1
        assert data["page_size"] == 10


# Test Update Review
class TestUpdateReview:
    """Tests for PATCH /reviews/{id}"""
    
    @pytest.mark.asyncio
    async def test_update_review_success(
        self,
        client: AsyncClient,
        buyer_user: User,
        buyer_token: str,
        test_product: Product,
        delivered_order: Order,
        db: AsyncSession
    ):
        """Test successful review update"""
        # Create review
        review = Review(
            user_id=buyer_user.id,
            product_id=test_product.id,
            order_id=delivered_order.id,
            rating=4,
            content="Original content",
            is_verified_purchase=True,
            is_visible=True
        )
        db.add(review)
        await db.commit()
        await db.refresh(review)
        
        # Update review
        update_data = {
            "rating": 5,
            "content": "Updated content - even better!"
        }
        
        response = await client.patch(
            f"/api/v1/reviews/{review.id}",
            json=update_data,
            headers={"Authorization": f"Bearer {buyer_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["rating"] == 5
        assert data["content"] == "Updated content - even better!"
        
        # Verify in database
        await db.refresh(review)
        assert review.rating == 5
        assert review.content == "Updated content - even better!"
    
    @pytest.mark.asyncio
    async def test_update_review_unauthorized(
        self,
        client: AsyncClient,
        buyer_user: User,
        seller_user: User,
        seller_token: str,
        test_product: Product,
        delivered_order: Order,
        db: AsyncSession
    ):
        """Test updating review by non-owner"""
        # Create review by buyer
        review = Review(
            user_id=buyer_user.id,
            product_id=test_product.id,
            order_id=delivered_order.id,
            rating=5,
            content="Original",
            is_verified_purchase=True,
            is_visible=True
        )
        db.add(review)
        await db.commit()
        
        # Try to update with different user's token
        update_data = {"content": "Hacked!"}
        
        response = await client.patch(
            f"/api/v1/reviews/{review.id}",
            json=update_data,
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        
        assert response.status_code == 403


# Test Delete Review
class TestDeleteReview:
    """Tests for DELETE /reviews/{id}"""
    
    @pytest.mark.asyncio
    async def test_delete_review_success(
        self,
        client: AsyncClient,
        buyer_user: User,
        buyer_token: str,
        test_product: Product,
        delivered_order: Order,
        db: AsyncSession
    ):
        """Test successful review deletion"""
        # Create review
        review = Review(
            user_id=buyer_user.id,
            product_id=test_product.id,
            order_id=delivered_order.id,
            rating=5,
            content="Will delete this",
            is_verified_purchase=True,
            is_visible=True
        )
        db.add(review)
        await db.commit()
        review_id = review.id
        
        # Delete review
        response = await client.delete(
            f"/api/v1/reviews/{review_id}",
            headers={"Authorization": f"Bearer {buyer_token}"}
        )
        
        assert response.status_code == 204
        
        # Verify deletion
        result = await db.execute(
            select(Review).where(Review.id == review_id)
        )
        assert result.scalar_one_or_none() is None
    
    @pytest.mark.asyncio
    async def test_delete_review_unauthorized(
        self,
        client: AsyncClient,
        buyer_user: User,
        seller_token: str,
        test_product: Product,
        delivered_order: Order,
        db: AsyncSession
    ):
        """Test deleting review by non-owner"""
        # Create review
        review = Review(
            user_id=buyer_user.id,
            product_id=test_product.id,
            order_id=delivered_order.id,
            rating=5,
            content="My review",
            is_verified_purchase=True,
            is_visible=True
        )
        db.add(review)
        await db.commit()
        
        # Try to delete with wrong user
        response = await client.delete(
            f"/api/v1/reviews/{review.id}",
            headers={"Authorization": f"Bearer {seller_token}"}
        )
        
        assert response.status_code == 403


# Test Get User Reviews
class TestGetUserReviews:
    """Tests for GET /reviews/my-reviews"""
    
    @pytest.mark.asyncio
    async def test_get_my_reviews(
        self,
        client: AsyncClient,
        buyer_user: User,
        buyer_token: str,
        test_product: Product,
        delivered_order: Order,
        db: AsyncSession
    ):
        """Test getting current user's reviews"""
        # Create review
        review = Review(
            user_id=buyer_user.id,
            product_id=test_product.id,
            order_id=delivered_order.id,
            rating=5,
            content="My review",
            is_verified_purchase=True,
            is_visible=True
        )
        db.add(review)
        await db.commit()
        
        response = await client.get(
            "/api/v1/reviews/my-reviews",
            headers={"Authorization": f"Bearer {buyer_token}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert data["items"][0]["rating"] == 5


# Test Complete Workflow
class TestReviewWorkflow:
    """Tests for complete review lifecycle"""
    
    @pytest.mark.asyncio
    async def test_complete_review_lifecycle(
        self,
        client: AsyncClient,
        buyer_token: str,
        test_product: Product,
        delivered_order: Order,
        db: AsyncSession
    ):
        """Test complete review lifecycle: create → get → update → delete"""
        
        # 1. Create review
        create_data = {
            "product_id": str(test_product.id),
            "order_id": str(delivered_order.id),
            "rating": 4,
            "content": "Good product"
        }
        
        create_response = await client.post(
            "/api/v1/reviews",
            json=create_data,
            headers={"Authorization": f"Bearer {buyer_token}"}
        )
        assert create_response.status_code == 201
        review_id = create_response.json()["id"]
        
        # 2. Get product reviews
        get_response = await client.get(
            f"/api/v1/products/{test_product.id}/reviews"
        )
        assert get_response.status_code == 200
        assert get_response.json()["total"] == 1
        
        # 3. Update review
        update_response = await client.patch(
            f"/api/v1/reviews/{review_id}",
            json={"rating": 5, "content": "Actually excellent!"},
            headers={"Authorization": f"Bearer {buyer_token}"}
        )
        assert update_response.status_code == 200
        assert update_response.json()["rating"] == 5
        
        # 4. Verify product rating updated
        await db.refresh(test_product)
        assert test_product.rating == 5.0
        
        # 5. Delete review
        delete_response = await client.delete(
            f"/api/v1/reviews/{review_id}",
            headers={"Authorization": f"Bearer {buyer_token}"}
        )
        assert delete_response.status_code == 204
        
        # 6. Verify review deleted and product rating reset
        get_after_delete = await client.get(
            f"/api/v1/products/{test_product.id}/reviews"
        )
        assert get_after_delete.json()["total"] == 0
        
        await db.refresh(test_product)
        assert test_product.rating == 0.0
        assert test_product.total_ratings == 0
