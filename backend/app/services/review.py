"""
Review service for business logic
"""
from typing import Optional
from uuid import UUID

from fastapi import HTTPException, status

from app.models.review import Review
from app.models.order import OrderStatus
from app.repositories.review import ReviewRepository
from app.repositories.order import OrderRepository
from app.repositories.product import ProductRepository
from app.schemas.review import (
    ReviewCreate,
    ReviewUpdate,
    ReviewResponse,
    ReviewUserInfo,
    ReviewListResponse,
    ReviewStats,
)


class ReviewService:
    """Service for review business logic"""
    
    def __init__(
        self,
        review_repo: ReviewRepository,
        order_repo: OrderRepository,
        product_repo: ProductRepository
    ):
        self.review_repo = review_repo
        self.order_repo = order_repo
        self.product_repo = product_repo
    
    async def create_review(
        self,
        user_id: UUID,
        review_data: ReviewCreate
    ) -> ReviewResponse:
        """
        Create a new review for a product
        
        Args:
            user_id: User ID creating the review
            review_data: Review creation data
        
        Returns:
            Created review response
        
        Raises:
            HTTPException: If validation fails
        """
        # Check if product exists
        product = await self.product_repo.get(review_data.product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
        
        # Check if order exists and belongs to user
        order = await self.order_repo.get(review_data.order_id)
        if not order:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found"
            )
        
        if order.buyer_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to review this order"
            )
        
        # Check if order is delivered or completed
        if order.status not in [OrderStatus.DELIVERED, OrderStatus.COMPLETED]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Can only review delivered or completed orders"
            )
        
        # Verify product is in the order
        product_in_order = any(
            item.product_id == review_data.product_id
            for item in order.items
        )
        if not product_in_order:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Product not found in this order"
            )
        
        # Check for duplicate review
        existing_review = await self.review_repo.find_user_review(
            user_id=user_id,
            product_id=review_data.product_id
        )
        if existing_review:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="You have already reviewed this product"
            )
        
        # Create review
        review = Review(
            user_id=user_id,
            product_id=review_data.product_id,
            order_id=review_data.order_id,
            rating=review_data.rating,
            content=review_data.content,
            images=review_data.images,
            is_verified_purchase=True,
            is_visible=True
        )
        
        review = await self.review_repo.create(review)
        
        # Update product rating
        await self.update_product_rating(review_data.product_id)
        
        # Load user relationship for response
        review = await self.review_repo.get_with_user(review.id)
        
        return self._build_review_response(review)
    
    async def get_review(self, review_id: UUID) -> ReviewResponse:
        """Get review by ID"""
        review = await self.review_repo.get_with_user(review_id)
        if not review:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Review not found"
            )
        
        return self._build_review_response(review)
    
    async def get_product_reviews(
        self,
        product_id: UUID,
        page: int = 1,
        page_size: int = 20,
        rating_filter: Optional[int] = None,
        verified_only: bool = False
    ) -> ReviewListResponse:
        """
        Get reviews for a product with pagination and filters
        
        Args:
            product_id: Product ID
            page: Page number (1-indexed)
            page_size: Items per page
            rating_filter: Filter by specific rating (1-5)
            verified_only: Show only verified purchases
        
        Returns:
            Paginated review list with statistics
        """
        # Check if product exists
        product = await self.product_repo.get(product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
        
        skip = (page - 1) * page_size
        reviews, total = await self.review_repo.list_by_product(
            product_id=product_id,
            skip=skip,
            limit=page_size,
            rating_filter=rating_filter,
            verified_only=verified_only
        )
        
        # Get review statistics
        stats = await self.review_repo.get_product_stats(product_id)
        
        total_pages = (total + page_size - 1) // page_size
        
        return ReviewListResponse(
            items=[self._build_review_response(r) for r in reviews],
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages,
            average_rating=stats['average_rating'],
            rating_distribution=stats['rating_distribution']
        )
    
    async def get_user_reviews(
        self,
        user_id: UUID,
        page: int = 1,
        page_size: int = 20
    ) -> ReviewListResponse:
        """Get reviews created by a user"""
        skip = (page - 1) * page_size
        reviews, total = await self.review_repo.list_by_user(
            user_id=user_id,
            skip=skip,
            limit=page_size
        )
        
        total_pages = (total + page_size - 1) // page_size
        
        return ReviewListResponse(
            items=[self._build_review_response(r) for r in reviews],
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )
    
    async def update_review(
        self,
        user_id: UUID,
        review_id: UUID,
        review_data: ReviewUpdate
    ) -> ReviewResponse:
        """
        Update an existing review
        
        Args:
            user_id: User ID requesting the update
            review_id: Review ID to update
            review_data: Update data
        
        Returns:
            Updated review response
        
        Raises:
            HTTPException: If validation fails or unauthorized
        """
        review = await self.review_repo.get(review_id)
        if not review:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Review not found"
            )
        
        # Check ownership
        if review.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update this review"
            )
        
        # Update fields
        update_data = review_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(review, field, value)
        
        review = await self.review_repo.update(review)
        
        # Update product rating if rating changed
        if 'rating' in update_data:
            await self.update_product_rating(review.product_id)
        
        # Load user relationship
        review = await self.review_repo.get_with_user(review.id)
        
        return self._build_review_response(review)
    
    async def delete_review(self, user_id: UUID, review_id: UUID) -> None:
        """
        Delete a review
        
        Args:
            user_id: User ID requesting deletion
            review_id: Review ID to delete
        
        Raises:
            HTTPException: If review not found or unauthorized
        """
        review = await self.review_repo.get(review_id)
        if not review:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Review not found"
            )
        
        # Check ownership
        if review.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this review"
            )
        
        product_id = review.product_id
        
        await self.review_repo.delete(review_id)
        
        # Update product rating
        await self.update_product_rating(product_id)
    
    async def update_product_rating(self, product_id: UUID) -> None:
        """
        Recalculate and update product's average rating
        
        Args:
            product_id: Product ID to update
        """
        stats = await self.review_repo.get_product_stats(product_id)
        
        product = await self.product_repo.get(product_id)
        if product:
            product.rating = stats['average_rating']
            product.total_ratings = stats['total_reviews']
            await self.product_repo.update(product)
    
    async def get_product_stats(self, product_id: UUID) -> ReviewStats:
        """Get review statistics for a product"""
        product = await self.product_repo.get(product_id)
        if not product:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found"
            )
        
        stats = await self.review_repo.get_product_stats(product_id)
        
        return ReviewStats(
            total_reviews=stats['total_reviews'],
            average_rating=stats['average_rating'],
            rating_distribution=stats['rating_distribution']
        )
    
    def _build_review_response(self, review: Review) -> ReviewResponse:
        """Build review response with user info"""
        response_data = ReviewResponse.model_validate(review)
        
        # Add user info if available
        if review.user:
            response_data.user = ReviewUserInfo.model_validate(review.user)
        
        return response_data
