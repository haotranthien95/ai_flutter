"""
Voucher service for business logic
"""
from datetime import datetime
from decimal import Decimal
from typing import Optional
from uuid import UUID

from fastapi import HTTPException, status

from app.models.voucher import Voucher, VoucherType
from app.repositories.voucher import VoucherRepository
from app.repositories.shop import ShopRepository
from app.schemas.voucher import (
    VoucherCreate,
    VoucherUpdate,
    VoucherResponse,
    VoucherListResponse,
    VoucherValidateResponse,
    VoucherAvailableResponse,
)


class VoucherService:
    """Service for voucher business logic"""
    
    def __init__(
        self,
        voucher_repo: VoucherRepository,
        shop_repo: ShopRepository
    ):
        self.voucher_repo = voucher_repo
        self.shop_repo = shop_repo
    
    async def create_voucher(
        self,
        shop_id: UUID,
        voucher_data: VoucherCreate,
        seller_id: UUID
    ) -> VoucherResponse:
        """
        Create a new voucher for a shop
        
        Args:
            shop_id: Shop ID
            voucher_data: Voucher creation data
            seller_id: ID of the seller creating the voucher
        
        Returns:
            Created voucher response
        
        Raises:
            HTTPException: If validation fails
        """
        # Verify shop exists and belongs to seller
        shop = await self.shop_repo.get(shop_id)
        if not shop:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Shop not found"
            )
        
        if shop.owner_id != seller_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to create vouchers for this shop"
            )
        
        # Check if code already exists
        if await self.voucher_repo.code_exists(voucher_data.code):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Voucher code already exists"
            )
        
        # Validate percentage type
        if voucher_data.type == VoucherType.PERCENTAGE:
            if voucher_data.value > 100:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Percentage value cannot exceed 100"
                )
        
        # Validate date range
        if voucher_data.end_date <= voucher_data.start_date:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="End date must be after start date"
            )
        
        # Create voucher
        voucher = Voucher(
            shop_id=shop_id,
            **voucher_data.model_dump()
        )
        
        voucher = await self.voucher_repo.create(voucher)
        
        return VoucherResponse.model_validate(voucher)
    
    async def get_voucher(self, voucher_id: UUID, seller_id: UUID) -> VoucherResponse:
        """
        Get voucher by ID (seller must own the shop)
        
        Args:
            voucher_id: Voucher ID
            seller_id: Seller ID
        
        Returns:
            Voucher response
        
        Raises:
            HTTPException: If voucher not found or unauthorized
        """
        voucher = await self.voucher_repo.get(voucher_id)
        if not voucher:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Voucher not found"
            )
        
        # Verify ownership
        shop = await self.shop_repo.get(voucher.shop_id)
        if not shop or shop.owner_id != seller_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to access this voucher"
            )
        
        return VoucherResponse.model_validate(voucher)
    
    async def list_shop_vouchers(
        self,
        shop_id: UUID,
        seller_id: UUID,
        page: int = 1,
        page_size: int = 20,
        is_active: Optional[bool] = None
    ) -> VoucherListResponse:
        """
        List vouchers for a shop
        
        Args:
            shop_id: Shop ID
            seller_id: Seller ID
            page: Page number
            page_size: Items per page
            is_active: Filter by active status
        
        Returns:
            Paginated voucher list
        
        Raises:
            HTTPException: If shop not found or unauthorized
        """
        # Verify shop exists and belongs to seller
        shop = await self.shop_repo.get(shop_id)
        if not shop:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Shop not found"
            )
        
        if shop.owner_id != seller_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to access this shop's vouchers"
            )
        
        skip = (page - 1) * page_size
        vouchers, total = await self.voucher_repo.list_by_shop(
            shop_id=shop_id,
            skip=skip,
            limit=page_size,
            is_active=is_active
        )
        
        total_pages = (total + page_size - 1) // page_size
        
        return VoucherListResponse(
            items=[VoucherResponse.model_validate(v) for v in vouchers],
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )
    
    async def update_voucher(
        self,
        voucher_id: UUID,
        voucher_data: VoucherUpdate,
        seller_id: UUID
    ) -> VoucherResponse:
        """
        Update a voucher
        
        Args:
            voucher_id: Voucher ID
            voucher_data: Update data
            seller_id: Seller ID
        
        Returns:
            Updated voucher response
        
        Raises:
            HTTPException: If voucher not found or unauthorized
        """
        voucher = await self.voucher_repo.get(voucher_id)
        if not voucher:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Voucher not found"
            )
        
        # Verify ownership
        shop = await self.shop_repo.get(voucher.shop_id)
        if not shop or shop.owner_id != seller_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to update this voucher"
            )
        
        # Update fields
        update_data = voucher_data.model_dump(exclude_unset=True)
        
        # Validate percentage if value is being updated
        if 'value' in update_data and voucher.type == VoucherType.PERCENTAGE:
            if update_data['value'] > 100:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Percentage value cannot exceed 100"
                )
        
        # Validate date range if dates are being updated
        start_date = update_data.get('start_date', voucher.start_date)
        end_date = update_data.get('end_date', voucher.end_date)
        if end_date <= start_date:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="End date must be after start date"
            )
        
        for field, value in update_data.items():
            setattr(voucher, field, value)
        
        voucher = await self.voucher_repo.update(voucher)
        
        return VoucherResponse.model_validate(voucher)
    
    async def delete_voucher(self, voucher_id: UUID, seller_id: UUID) -> None:
        """
        Delete a voucher
        
        Args:
            voucher_id: Voucher ID
            seller_id: Seller ID
        
        Raises:
            HTTPException: If voucher not found or unauthorized
        """
        voucher = await self.voucher_repo.get(voucher_id)
        if not voucher:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Voucher not found"
            )
        
        # Verify ownership
        shop = await self.shop_repo.get(voucher.shop_id)
        if not shop or shop.owner_id != seller_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to delete this voucher"
            )
        
        await self.voucher_repo.delete(voucher_id)
    
    async def validate_voucher(
        self,
        code: str,
        shop_id: UUID,
        subtotal: Decimal
    ) -> VoucherValidateResponse:
        """
        Validate a voucher for an order
        
        Args:
            code: Voucher code
            shop_id: Shop ID
            subtotal: Order subtotal
        
        Returns:
            Validation response with discount amount
        """
        # Get voucher
        voucher = await self.voucher_repo.get_by_code_and_shop(code, shop_id)
        
        if not voucher:
            return VoucherValidateResponse(
                valid=False,
                message="Voucher not found for this shop"
            )
        
        # Check if voucher is active
        if not voucher.is_active:
            return VoucherValidateResponse(
                valid=False,
                message="Voucher is not active",
                voucher=VoucherResponse.model_validate(voucher)
            )
        
        # Check date validity
        current_time = datetime.utcnow()
        if current_time < voucher.start_date:
            return VoucherValidateResponse(
                valid=False,
                message="Voucher is not yet valid",
                voucher=VoucherResponse.model_validate(voucher)
            )
        
        if current_time > voucher.end_date:
            return VoucherValidateResponse(
                valid=False,
                message="Voucher has expired",
                voucher=VoucherResponse.model_validate(voucher)
            )
        
        # Check usage limit
        if voucher.usage_limit and voucher.usage_count >= voucher.usage_limit:
            return VoucherValidateResponse(
                valid=False,
                message="Voucher usage limit reached",
                voucher=VoucherResponse.model_validate(voucher)
            )
        
        # Check minimum order value
        if voucher.min_order_value and subtotal < voucher.min_order_value:
            return VoucherValidateResponse(
                valid=False,
                message=f"Minimum order value of {voucher.min_order_value} required",
                voucher=VoucherResponse.model_validate(voucher)
            )
        
        # Calculate discount
        discount_amount = voucher.calculate_discount(subtotal)
        
        return VoucherValidateResponse(
            valid=True,
            message="Voucher is valid",
            discount_amount=discount_amount,
            voucher=VoucherResponse.model_validate(voucher)
        )
    
    async def get_available_vouchers(
        self,
        shop_id: UUID,
        subtotal: Decimal
    ) -> VoucherAvailableResponse:
        """
        Get all available vouchers for an order
        
        Args:
            shop_id: Shop ID
            subtotal: Order subtotal
        
        Returns:
            Available vouchers response
        """
        vouchers = await self.voucher_repo.get_available_for_order(
            shop_id=shop_id,
            subtotal=subtotal
        )
        
        return VoucherAvailableResponse(
            available_vouchers=[VoucherResponse.model_validate(v) for v in vouchers],
            total=len(vouchers)
        )
    
    async def apply_voucher_to_order(
        self,
        voucher_id: UUID,
        subtotal: Decimal
    ) -> Decimal:
        """
        Apply voucher to order and increment usage
        
        Args:
            voucher_id: Voucher ID
            subtotal: Order subtotal
        
        Returns:
            Discount amount
        
        Raises:
            HTTPException: If voucher cannot be applied
        """
        voucher = await self.voucher_repo.get(voucher_id)
        if not voucher:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Voucher not found"
            )
        
        if not voucher.can_apply_to_order(subtotal):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Voucher cannot be applied to this order"
            )
        
        # Increment usage count
        await self.voucher_repo.increment_usage(voucher_id)
        
        # Calculate and return discount
        return voucher.calculate_discount(subtotal)
