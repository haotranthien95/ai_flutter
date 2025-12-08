"""
Voucher API routes for buyers
"""
from decimal import Decimal
from uuid import UUID

from fastapi import APIRouter, Depends, Query

from app.dependencies import get_voucher_service
from app.schemas.voucher import (
    VoucherValidateRequest,
    VoucherValidateResponse,
    VoucherAvailableResponse,
)
from app.services.voucher import VoucherService

router = APIRouter(prefix="/vouchers", tags=["vouchers"])


@router.post("/validate", response_model=VoucherValidateResponse)
async def validate_voucher(
    validate_data: VoucherValidateRequest,
    voucher_service: VoucherService = Depends(get_voucher_service)
):
    """
    Validate a voucher for an order
    
    Checks if voucher is valid and calculates discount amount.
    """
    return await voucher_service.validate_voucher(
        code=validate_data.code,
        shop_id=validate_data.shop_id,
        subtotal=validate_data.subtotal
    )


@router.get("/available", response_model=VoucherAvailableResponse)
async def get_available_vouchers(
    shop_id: UUID = Query(..., description="Shop ID"),
    subtotal: Decimal = Query(..., gt=0, description="Order subtotal"),
    voucher_service: VoucherService = Depends(get_voucher_service)
):
    """
    Get all available vouchers for a shop and order amount
    
    Returns vouchers that can be applied to the order based on:
    - Active status
    - Date validity
    - Usage limits
    - Minimum order value requirements
    """
    return await voucher_service.get_available_vouchers(
        shop_id=shop_id,
        subtotal=subtotal
    )
