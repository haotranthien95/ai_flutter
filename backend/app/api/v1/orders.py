"""
Order API routes for buyers
"""
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_db, get_current_user, get_order_service
from app.models.user import User
from app.models.address import Address
from app.repositories.address import AddressRepository
from app.services.order import OrderService
from app.schemas.order import (
    OrderCreate,
    OrderResponse,
    OrderListResponse,
    OrderCancelRequest,
    OrderStatus,
)

router = APIRouter(tags=["Orders"])


@router.post(
    "",
    response_model=list[OrderResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create orders from cart"
)
async def create_orders(
    order_data: OrderCreate,
    current_user: User = Depends(get_current_user),
    order_service: OrderService = Depends(get_order_service),
    db: AsyncSession = Depends(get_db),
):
    """
    Create orders from cart items.
    
    - Items will be grouped by shop
    - One order will be created per shop
    - Stock will be validated and decremented
    - Cart will be cleared after successful order creation
    
    Requires authentication.
    """
    # Get address
    address_repo = AddressRepository(db)
    address = await address_repo.get(order_data.address_id)
    
    if not address or address.user_id != current_user.id:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Shipping address not found"
        )
    
    return await order_service.create_orders(
        user_id=current_user.id,
        order_data=order_data,
        address=address
    )


@router.get(
    "",
    response_model=OrderListResponse,
    summary="List user's orders"
)
async def list_orders(
    status_filter: Optional[OrderStatus] = Query(None, description="Filter by order status"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    current_user: User = Depends(get_current_user),
    order_service: OrderService = Depends(get_order_service),
):
    """
    List all orders for the current user.
    
    - Supports pagination
    - Optional status filter
    - Returns order summaries
    
    Requires authentication.
    """
    return await order_service.list_orders(
        user_id=current_user.id,
        status_filter=status_filter,
        page=page,
        page_size=page_size
    )


@router.get(
    "/{order_id}",
    response_model=OrderResponse,
    summary="Get order detail"
)
async def get_order_detail(
    order_id: UUID,
    current_user: User = Depends(get_current_user),
    order_service: OrderService = Depends(get_order_service),
):
    """
    Get detailed information about a specific order.
    
    - Includes all order items
    - Shows complete order history
    
    Requires authentication and ownership.
    """
    return await order_service.get_order_detail(
        user_id=current_user.id,
        order_id=order_id
    )


@router.post(
    "/{order_id}/cancel",
    response_model=OrderResponse,
    summary="Cancel an order"
)
async def cancel_order(
    order_id: UUID,
    cancel_request: OrderCancelRequest,
    current_user: User = Depends(get_current_user),
    order_service: OrderService = Depends(get_order_service),
):
    """
    Cancel an order.
    
    - Can only cancel orders with status PENDING or CONFIRMED
    - Stock will be restored
    - Requires cancellation reason
    
    Requires authentication and ownership.
    """
    return await order_service.cancel_order(
        user_id=current_user.id,
        order_id=order_id,
        cancel_request=cancel_request
    )
