"""
Cart API endpoints
"""
from uuid import UUID

from fastapi import APIRouter, Depends, status

from app.dependencies import get_current_user, get_cart_service
from app.models.user import User
from app.services.cart import CartService
from app.schemas.cart import (
    CartItemCreate,
    CartItemUpdate,
    CartItemResponse,
    CartResponse,
    CartSyncRequest,
)

router = APIRouter(prefix="/cart", tags=["cart"])


@router.get("", response_model=CartResponse)
async def get_cart(
    current_user: User = Depends(get_current_user),
    cart_service: CartService = Depends(get_cart_service),
):
    """
    Get current user's shopping cart
    
    Returns cart items grouped by shop with totals
    """
    return await cart_service.get_cart(current_user.id)


@router.post("", response_model=CartItemResponse, status_code=status.HTTP_201_CREATED)
async def add_to_cart(
    item_data: CartItemCreate,
    current_user: User = Depends(get_current_user),
    cart_service: CartService = Depends(get_cart_service),
):
    """
    Add item to cart
    
    If item already exists, quantity will be increased
    """
    return await cart_service.add_to_cart(current_user.id, item_data)


@router.patch("/items/{cart_item_id}", response_model=CartItemResponse)
async def update_cart_item(
    cart_item_id: UUID,
    update_data: CartItemUpdate,
    current_user: User = Depends(get_current_user),
    cart_service: CartService = Depends(get_cart_service),
):
    """
    Update cart item quantity
    """
    return await cart_service.update_cart_item(
        current_user.id, cart_item_id, update_data
    )


@router.delete("/items/{cart_item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_from_cart(
    cart_item_id: UUID,
    current_user: User = Depends(get_current_user),
    cart_service: CartService = Depends(get_cart_service),
):
    """
    Remove item from cart
    """
    await cart_service.remove_from_cart(current_user.id, cart_item_id)


@router.post("/sync", response_model=CartResponse)
async def sync_cart(
    sync_request: CartSyncRequest,
    current_user: User = Depends(get_current_user),
    cart_service: CartService = Depends(get_cart_service),
):
    """
    Sync cart items (useful for guest → logged in transition)
    
    Clears existing cart and adds all items from request
    """
    return await cart_service.sync_cart(current_user.id, sync_request)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
async def clear_cart(
    current_user: User = Depends(get_current_user),
    cart_service: CartService = Depends(get_cart_service),
):
    """
    Clear all items from cart
    """
    await cart_service.clear_cart(current_user.id)
