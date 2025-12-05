"""
Unit tests for Review service
"""
from datetime import datetime
from uuid import uuid4

import pytest
from fastapi import HTTPException
from unittest.mock import AsyncMock

from app.models.review import Review
from app.models.order import Order, OrderStatus, PaymentMethod, PaymentStatus
from app.models.product import Product, ProductCondition
from app.models.user import User, UserRole
from app.schemas.review import ReviewCreate, ReviewUpdate
from app.services.review import ReviewService


# Fixtures
@pytest.fixture
def mock_review_repo():
    """Mock review repository"""
    return AsyncMock()


@pytest.fixture
def mock_order_repo():
    """Mock order repository"""
    return AsyncMock()


@pytest.fixture
def mock_product_repo():
    """Mock product repository"""
    return AsyncMock()


@pytest.fixture
def review_service(mock_review_repo, mock_order_repo, mock_product_repo):
    """Review service instance"""
    return ReviewService(
        review_repo=mock_review_repo,
        order_repo=mock_order_repo,
        product_repo=mock_product_repo
    )


@pytest.fixture
def test_user():
    """Test user"""
    return User(
        id=uuid4(),
        phone_number="+1234567890",
        username="testuser",
        full_name="Test User",
        hashed_password="hashed",
        role=UserRole.BUYER
    )


@pytest.fixture
def test_product():
    """Test product"""
    return Product(
        id=uuid4(),
        shop_id=uuid4(),
        category_id=uuid4(),
        title="Test Product",
        description="Test description",
        price=100.00,
        condition=ProductCondition.NEW,
        stock=10,
        rating=0.0,
        total_ratings=0
    )


@pytest.fixture
def test_order(test_user, test_product):
    """Test order"""
    from app.models.order import OrderItem
    
    order = Order(
        id=uuid4(),
        buyer_id=test_user.id,
        shop_id=uuid4(),
        order_number="ORD-20251205-ABC123",
        status=OrderStatus.DELIVERED,
        payment_method=PaymentMethod.COD,
        payment_status=PaymentStatus.PAID,
        subtotal=100.00,
        shipping_fee=5.00,
        total=105.00,
        shipping_address={}
    )
    
    # Add order item
    order.items = [
        OrderItem(
            order_id=order.id,
            product_id=test_product.id,
            quantity=1,
            price=100.00,
            product_snapshot={}
        )
    ]
    
    return order


@pytest.fixture
def test_review(test_user, test_product, test_order):
    """Test review"""
    return Review(
        id=uuid4(),
        user_id=test_user.id,
        product_id=test_product.id,
        order_id=test_order.id,
        rating=5,
        content="Great product!",
        images=None,
        is_verified_purchase=True,
        is_visible=True
    )


# Test Create Review
class TestCreateReview:
    """Tests for creating reviews"""
    
    @pytest.mark.asyncio
    async def test_create_review_success(
        self,
        review_service,
        mock_review_repo,
        mock_order_repo,
        mock_product_repo,
        test_user,
        test_product,
        test_order
    ):
        """Test successful review creation"""
        review_data = ReviewCreate(
            product_id=test_product.id,
            order_id=test_order.id,
            rating=5,
            content="Excellent product!",
            images=None
        )
        
        # Mock product exists
        mock_product_repo.get.return_value = test_product
        
        # Mock order exists and belongs to user
        mock_order_repo.get.return_value = test_order
        
        # Mock no existing review
        mock_review_repo.find_user_review.return_value = None
        
        # Mock review creation
        created_review = Review(
            id=uuid4(),
            user_id=test_user.id,
            product_id=review_data.product_id,
            order_id=review_data.order_id,
            rating=review_data.rating,
            content=review_data.content,
            is_verified_purchase=True,
            is_visible=True
        )
        created_review.user = test_user
        mock_review_repo.create.return_value = created_review
        mock_review_repo.get_with_user.return_value = created_review
        
        # Mock product stats for rating update
        mock_review_repo.get_product_stats.return_value = {
            'average_rating': 5.0,
            'total_reviews': 1,
            'rating_distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 1}
        }
        mock_product_repo.update.return_value = test_product
        
        # Create review
        result = await review_service.create_review(
            user_id=test_user.id,
            review_data=review_data
        )
        
        assert result.rating == 5
        assert result.content == "Excellent product!"
        assert result.is_verified_purchase is True
        mock_review_repo.create.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_create_review_product_not_found(
        self,
        review_service,
        mock_product_repo,
        test_user,
        test_order
    ):
        """Test review creation with non-existent product"""
        review_data = ReviewCreate(
            product_id=uuid4(),
            order_id=test_order.id,
            rating=5,
            content="Test"
        )
        
        mock_product_repo.get.return_value = None
        
        with pytest.raises(HTTPException) as exc_info:
            await review_service.create_review(
                user_id=test_user.id,
                review_data=review_data
            )
        
        assert exc_info.value.status_code == 404
        assert "Product not found" in exc_info.value.detail
    
    @pytest.mark.asyncio
    async def test_create_review_order_not_found(
        self,
        review_service,
        mock_product_repo,
        mock_order_repo,
        test_user,
        test_product
    ):
        """Test review creation with non-existent order"""
        review_data = ReviewCreate(
            product_id=test_product.id,
            order_id=uuid4(),
            rating=5,
            content="Test"
        )
        
        mock_product_repo.get.return_value = test_product
        mock_order_repo.get.return_value = None
        
        with pytest.raises(HTTPException) as exc_info:
            await review_service.create_review(
                user_id=test_user.id,
                review_data=review_data
            )
        
        assert exc_info.value.status_code == 404
        assert "Order not found" in exc_info.value.detail
    
    @pytest.mark.asyncio
    async def test_create_review_unauthorized_order(
        self,
        review_service,
        mock_product_repo,
        mock_order_repo,
        test_product,
        test_order
    ):
        """Test review creation for order not owned by user"""
        review_data = ReviewCreate(
            product_id=test_product.id,
            order_id=test_order.id,
            rating=5,
            content="Test"
        )
        
        mock_product_repo.get.return_value = test_product
        mock_order_repo.get.return_value = test_order
        
        # Different user ID
        wrong_user_id = uuid4()
        
        with pytest.raises(HTTPException) as exc_info:
            await review_service.create_review(
                user_id=wrong_user_id,
                review_data=review_data
            )
        
        assert exc_info.value.status_code == 403
        assert "Not authorized" in exc_info.value.detail
    
    @pytest.mark.asyncio
    async def test_create_review_order_not_delivered(
        self,
        review_service,
        mock_product_repo,
        mock_order_repo,
        test_user,
        test_product,
        test_order
    ):
        """Test review creation for order not yet delivered"""
        test_order.status = OrderStatus.SHIPPING
        
        review_data = ReviewCreate(
            product_id=test_product.id,
            order_id=test_order.id,
            rating=5,
            content="Test"
        )
        
        mock_product_repo.get.return_value = test_product
        mock_order_repo.get.return_value = test_order
        
        with pytest.raises(HTTPException) as exc_info:
            await review_service.create_review(
                user_id=test_user.id,
                review_data=review_data
            )
        
        assert exc_info.value.status_code == 400
        assert "delivered or completed" in exc_info.value.detail
    
    @pytest.mark.asyncio
    async def test_create_review_product_not_in_order(
        self,
        review_service,
        mock_product_repo,
        mock_order_repo,
        test_user,
        test_order
    ):
        """Test review creation for product not in order"""
        different_product = Product(
            id=uuid4(),
            shop_id=uuid4(),
            category_id=uuid4(),
            title="Different Product",
            price=50.00,
            condition=ProductCondition.NEW,
            stock=5
        )
        
        review_data = ReviewCreate(
            product_id=different_product.id,
            order_id=test_order.id,
            rating=5,
            content="Test"
        )
        
        mock_product_repo.get.return_value = different_product
        mock_order_repo.get.return_value = test_order
        
        with pytest.raises(HTTPException) as exc_info:
            await review_service.create_review(
                user_id=test_user.id,
                review_data=review_data
            )
        
        assert exc_info.value.status_code == 400
        assert "not found in this order" in exc_info.value.detail
    
    @pytest.mark.asyncio
    async def test_create_review_duplicate(
        self,
        review_service,
        mock_review_repo,
        mock_product_repo,
        mock_order_repo,
        test_user,
        test_product,
        test_order,
        test_review
    ):
        """Test preventing duplicate reviews"""
        review_data = ReviewCreate(
            product_id=test_product.id,
            order_id=test_order.id,
            rating=5,
            content="Test"
        )
        
        mock_product_repo.get.return_value = test_product
        mock_order_repo.get.return_value = test_order
        mock_review_repo.find_user_review.return_value = test_review
        
        with pytest.raises(HTTPException) as exc_info:
            await review_service.create_review(
                user_id=test_user.id,
                review_data=review_data
            )
        
        assert exc_info.value.status_code == 400
        assert "already reviewed" in exc_info.value.detail


# Test Update Review
class TestUpdateReview:
    """Tests for updating reviews"""
    
    @pytest.mark.asyncio
    async def test_update_review_success(
        self,
        review_service,
        mock_review_repo,
        mock_product_repo,
        test_user,
        test_review
    ):
        """Test successful review update"""
        update_data = ReviewUpdate(
            rating=4,
            content="Updated content"
        )
        
        mock_review_repo.get.return_value = test_review
        mock_review_repo.update.return_value = test_review
        mock_review_repo.get_with_user.return_value = test_review
        
        # Mock product stats for rating update
        mock_review_repo.get_product_stats.return_value = {
            'average_rating': 4.0,
            'total_reviews': 1,
            'rating_distribution': {1: 0, 2: 0, 3: 0, 4: 1, 5: 0}
        }
        mock_product_repo.get.return_value = Product(
            id=test_review.product_id,
            shop_id=uuid4(),
            category_id=uuid4(),
            title="Test",
            price=100,
            condition=ProductCondition.NEW,
            stock=10
        )
        mock_product_repo.update.return_value = mock_product_repo.get.return_value
        
        result = await review_service.update_review(
            user_id=test_user.id,
            review_id=test_review.id,
            review_data=update_data
        )
        
        assert result is not None
        mock_review_repo.update.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_update_review_not_found(
        self,
        review_service,
        mock_review_repo,
        test_user
    ):
        """Test updating non-existent review"""
        mock_review_repo.get.return_value = None
        
        update_data = ReviewUpdate(content="New content")
        
        with pytest.raises(HTTPException) as exc_info:
            await review_service.update_review(
                user_id=test_user.id,
                review_id=uuid4(),
                review_data=update_data
            )
        
        assert exc_info.value.status_code == 404
    
    @pytest.mark.asyncio
    async def test_update_review_unauthorized(
        self,
        review_service,
        mock_review_repo,
        test_review
    ):
        """Test updating review by non-owner"""
        mock_review_repo.get.return_value = test_review
        
        update_data = ReviewUpdate(content="Hacked!")
        wrong_user_id = uuid4()
        
        with pytest.raises(HTTPException) as exc_info:
            await review_service.update_review(
                user_id=wrong_user_id,
                review_id=test_review.id,
                review_data=update_data
            )
        
        assert exc_info.value.status_code == 403


# Test Delete Review
class TestDeleteReview:
    """Tests for deleting reviews"""
    
    @pytest.mark.asyncio
    async def test_delete_review_success(
        self,
        review_service,
        mock_review_repo,
        mock_product_repo,
        test_user,
        test_review
    ):
        """Test successful review deletion"""
        mock_review_repo.get.return_value = test_review
        mock_review_repo.delete.return_value = None
        
        # Mock product stats for rating update
        mock_review_repo.get_product_stats.return_value = {
            'average_rating': 0.0,
            'total_reviews': 0,
            'rating_distribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
        }
        mock_product_repo.get.return_value = Product(
            id=test_review.product_id,
            shop_id=uuid4(),
            category_id=uuid4(),
            title="Test",
            price=100,
            condition=ProductCondition.NEW,
            stock=10
        )
        mock_product_repo.update.return_value = mock_product_repo.get.return_value
        
        await review_service.delete_review(
            user_id=test_user.id,
            review_id=test_review.id
        )
        
        mock_review_repo.delete.assert_called_once_with(test_review.id)
    
    @pytest.mark.asyncio
    async def test_delete_review_not_found(
        self,
        review_service,
        mock_review_repo,
        test_user
    ):
        """Test deleting non-existent review"""
        mock_review_repo.get.return_value = None
        
        with pytest.raises(HTTPException) as exc_info:
            await review_service.delete_review(
                user_id=test_user.id,
                review_id=uuid4()
            )
        
        assert exc_info.value.status_code == 404
    
    @pytest.mark.asyncio
    async def test_delete_review_unauthorized(
        self,
        review_service,
        mock_review_repo,
        test_review
    ):
        """Test deleting review by non-owner"""
        mock_review_repo.get.return_value = test_review
        
        wrong_user_id = uuid4()
        
        with pytest.raises(HTTPException) as exc_info:
            await review_service.delete_review(
                user_id=wrong_user_id,
                review_id=test_review.id
            )
        
        assert exc_info.value.status_code == 403


# Test Product Rating Update
class TestUpdateProductRating:
    """Tests for product rating aggregation"""
    
    @pytest.mark.asyncio
    async def test_update_product_rating(
        self,
        review_service,
        mock_review_repo,
        mock_product_repo,
        test_product
    ):
        """Test product rating calculation and update"""
        mock_review_repo.get_product_stats.return_value = {
            'average_rating': 4.5,
            'total_reviews': 10,
            'rating_distribution': {1: 0, 2: 1, 3: 2, 4: 3, 5: 4}
        }
        
        mock_product_repo.get.return_value = test_product
        mock_product_repo.update.return_value = test_product
        
        await review_service.update_product_rating(test_product.id)
        
        # Verify product was updated
        assert mock_product_repo.update.called
        call_args = mock_product_repo.update.call_args[0][0]
        assert call_args.rating == 4.5
        assert call_args.total_ratings == 10
