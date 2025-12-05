"""
Review repository for database operations
"""
from typing import Optional
from uuid import UUID

from sqlalchemy import select, and_, func, desc
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.models.review import Review
from app.repositories.base import BaseRepository


class ReviewRepository(BaseRepository[Review]):
    """Repository for review database operations"""
    
    def __init__(self, db: AsyncSession):
        super().__init__(Review, db)
    
    async def find_user_review(self, user_id: UUID, product_id: UUID) -> Optional[Review]:
        """Find existing review by user for a product"""
        result = await self.db.execute(
            select(Review).where(
                and_(
                    Review.user_id == user_id,
                    Review.product_id == product_id
                )
            )
        )
        return result.scalar_one_or_none()
    
    async def list_by_product(
        self,
        product_id: UUID,
        skip: int = 0,
        limit: int = 20,
        rating_filter: Optional[int] = None,
        verified_only: bool = False
    ) -> tuple[list[Review], int]:
        """
        List reviews for a product with pagination and filters
        
        Args:
            product_id: Product ID
            skip: Number of records to skip
            limit: Maximum number of records to return
            rating_filter: Filter by specific rating (1-5)
            verified_only: Show only verified purchases
        
        Returns:
            Tuple of (reviews list, total count)
        """
        conditions = [
            Review.product_id == product_id,
            Review.is_visible == True
        ]
        
        if rating_filter:
            conditions.append(Review.rating == rating_filter)
        
        if verified_only:
            conditions.append(Review.is_verified_purchase == True)
        
        # Count query
        count_result = await self.db.execute(
            select(func.count(Review.id)).where(and_(*conditions))
        )
        total = count_result.scalar_one()
        
        # Data query with user info
        result = await self.db.execute(
            select(Review)
            .options(joinedload(Review.user))
            .where(and_(*conditions))
            .order_by(desc(Review.created_at))
            .offset(skip)
            .limit(limit)
        )
        reviews = result.unique().scalars().all()
        
        return list(reviews), total
    
    async def list_by_user(
        self,
        user_id: UUID,
        skip: int = 0,
        limit: int = 20
    ) -> tuple[list[Review], int]:
        """List reviews created by a user"""
        # Count query
        count_result = await self.db.execute(
            select(func.count(Review.id)).where(Review.user_id == user_id)
        )
        total = count_result.scalar_one()
        
        # Data query
        result = await self.db.execute(
            select(Review)
            .where(Review.user_id == user_id)
            .order_by(desc(Review.created_at))
            .offset(skip)
            .limit(limit)
        )
        reviews = result.scalars().all()
        
        return list(reviews), total
    
    async def get_product_stats(self, product_id: UUID) -> dict:
        """
        Get review statistics for a product
        
        Returns:
            Dict with average_rating, total_reviews, and rating_distribution
        """
        # Get average rating and total count
        result = await self.db.execute(
            select(
                func.avg(Review.rating).label('avg_rating'),
                func.count(Review.id).label('total')
            ).where(
                and_(
                    Review.product_id == product_id,
                    Review.is_visible == True
                )
            )
        )
        row = result.one()
        
        avg_rating = float(row.avg_rating) if row.avg_rating else 0.0
        total_reviews = row.total
        
        # Get rating distribution
        distribution_result = await self.db.execute(
            select(
                Review.rating,
                func.count(Review.id).label('count')
            ).where(
                and_(
                    Review.product_id == product_id,
                    Review.is_visible == True
                )
            ).group_by(Review.rating)
        )
        
        rating_distribution = {i: 0 for i in range(1, 6)}
        for row in distribution_result:
            rating_distribution[row.rating] = row.count
        
        return {
            'average_rating': avg_rating,
            'total_reviews': total_reviews,
            'rating_distribution': rating_distribution
        }
    
    async def get_with_user(self, review_id: UUID) -> Optional[Review]:
        """Get review with user relationship loaded"""
        result = await self.db.execute(
            select(Review)
            .options(joinedload(Review.user))
            .where(Review.id == review_id)
        )
        return result.unique().scalar_one_or_none()
