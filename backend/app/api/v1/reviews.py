"""
Review API routes
"""
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status

from app.dependencies import get_current_user, get_review_service
from app.models.user import User
from app.schemas.review import (
    ReviewCreate,
    ReviewUpdate,
    ReviewResponse,
    ReviewListResponse,
    ReviewStats,
)
from app.services.review import ReviewService

router = APIRouter(prefix="/reviews", tags=["reviews"])


@router.post("", response_model=ReviewResponse, status_code=status.HTTP_201_CREATED)
async def create_review(
    review_data: ReviewCreate,
    current_user: User = Depends(get_current_user),
    review_service: ReviewService = Depends(get_review_service)
):
    """
    Create a new review for a product
    
    Requirements:
    - Order must be delivered or completed
    - Product must be in the order
    - User can only review once per product
    - Must be authenticated
    """
    return await review_service.create_review(
        user_id=current_user.id,
        review_data=review_data
    )


@router.get("/my-reviews", response_model=ReviewListResponse)
async def get_my_reviews(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_user),
    review_service: ReviewService = Depends(get_review_service)
):
    """
    Get current user's reviews with pagination
    """
    return await review_service.get_user_reviews(
        user_id=current_user.id,
        page=page,
        page_size=page_size
    )


@router.get("/{review_id}", response_model=ReviewResponse)
async def get_review(
    review_id: UUID,
    review_service: ReviewService = Depends(get_review_service)
):
    """
    Get review by ID (public endpoint)
    """
    return await review_service.get_review(review_id=review_id)


@router.patch("/{review_id}", response_model=ReviewResponse)
async def update_review(
    review_id: UUID,
    review_data: ReviewUpdate,
    current_user: User = Depends(get_current_user),
    review_service: ReviewService = Depends(get_review_service)
):
    """
    Update a review
    
    Only the review author can update their review.
    """
    return await review_service.update_review(
        user_id=current_user.id,
        review_id=review_id,
        review_data=review_data
    )


@router.delete("/{review_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_review(
    review_id: UUID,
    current_user: User = Depends(get_current_user),
    review_service: ReviewService = Depends(get_review_service)
):
    """
    Delete a review
    
    Only the review author can delete their review.
    """
    await review_service.delete_review(
        user_id=current_user.id,
        review_id=review_id
    )
    return None
