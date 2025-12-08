"""
Cart service for business logic
"""
from typing import List, Optional
from uuid import UUID
from decimal import Decimal
from collections import defaultdict

from fastapi import HTTPException, status

from app.models.cart import CartItem
from app.repositories.cart import CartRepository
from app.repositories.product import ProductRepository, ProductVariantRepository
from app.schemas.cart import (
    CartItemCreate,
    CartItemUpdate,
    CartItemResponse,
    CartResponse,
    ShopCartGroup,
    ProductSummary,
    VariantSummary,
    CartSyncRequest,
)


class CartService:
    """Service for cart business logic"""
    
    def __init__(
        self,
        cart_repo: CartRepository,
        product_repo: ProductRepository,
        variant_repo: ProductVariantRepository,
    ):
        self.cart_repo = cart_repo
        self.product_repo = product_repo
        self.variant_repo = variant_repo
    
    async def get_cart(self, user_id: UUID) -> CartResponse:
        """
        Get user's cart with items grouped by shop
        
        Args:
            user_id: User ID
        
        Returns:
            Cart response with items grouped by shop
        """
        # Get all cart items for user
        cart_items = await self.cart_repo.list_by_user(user_id, load_relations=True)
        
        # Convert to response format
        item_responses = []
        total_quantity = 0
        total_price = Decimal('0')
        
        for item in cart_items:
            item_response = await self._build_cart_item_response(item)
            item_responses.append(item_response)
            total_quantity += item.quantity
            total_price += item_response.total_price
        
        # Group by shop
        shops = await self._group_by_shop(item_responses)
        
        return CartResponse(
            items=item_responses,
            shops=shops,
            total_items=len(item_responses),
            total_quantity=total_quantity,
            total_price=total_price,
        )
    
    async def add_to_cart(
        self,
        user_id: UUID,
        item_data: CartItemCreate
    ) -> CartItemResponse:
        """
        Add item to cart or update quantity if exists
        
        Args:
            user_id: User ID
            item_data: Item to add
        
        Returns:
            Cart item response
        
        Raises:
            HTTPException: If product not found or validation fails
        """
        # Validate product exists and is active
        product = await self.product_repo.get_with_variants(item_data.product_id)
        if not product or not product.is_active:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Product not found or not available"
            )
        
        # Validate variant if provided
        variant = None
        if item_data.variant_id:
            variant = await self.variant_repo.get(item_data.variant_id)
            if not variant or variant.product_id != product.id:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Product variant not found"
                )
            if not variant.is_active:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Product variant is not available"
                )
        
        # Check stock availability
        available_stock = variant.stock if variant else product.total_stock
        if item_data.quantity > available_stock:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Only {available_stock} items available in stock"
            )
        
        # Check if item already in cart
        existing_item = await self.cart_repo.find_item(
            user_id, item_data.product_id, item_data.variant_id
        )
        
        if existing_item:
            # Update quantity
            new_quantity = existing_item.quantity + item_data.quantity
            if new_quantity > available_stock:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Cannot add {item_data.quantity} more. Only {available_stock - existing_item.quantity} available"
                )
            
            existing_item.quantity = new_quantity
            cart_item = await self.cart_repo.update(existing_item)
        else:
            # Create new cart item
            cart_item = CartItem(
                user_id=user_id,
                product_id=item_data.product_id,
                variant_id=item_data.variant_id,
                quantity=item_data.quantity,
            )
            cart_item = await self.cart_repo.create(cart_item)
        
        # Reload with relations
        cart_item = await self.cart_repo.get_with_relations(cart_item.id)
        return await self._build_cart_item_response(cart_item)
    
    async def update_cart_item(
        self,
        user_id: UUID,
        cart_item_id: UUID,
        update_data: CartItemUpdate
    ) -> CartItemResponse:
        """
        Update cart item quantity
        
        Args:
            user_id: User ID
            cart_item_id: Cart item ID
            update_data: Update data
        
        Returns:
            Updated cart item
        
        Raises:
            HTTPException: If not found or validation fails
        """
        # Get cart item
        cart_item = await self.cart_repo.get_with_relations(cart_item_id)
        if not cart_item or cart_item.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cart item not found"
            )
        
        # Check stock availability
        if cart_item.variant:
            available_stock = cart_item.variant.stock
        else:
            available_stock = cart_item.product.total_stock
        
        if update_data.quantity > available_stock:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Only {available_stock} items available in stock"
            )
        
        # Update quantity
        cart_item.quantity = update_data.quantity
        cart_item = await self.cart_repo.update(cart_item)
        
        return await self._build_cart_item_response(cart_item)
    
    async def remove_from_cart(
        self,
        user_id: UUID,
        cart_item_id: UUID
    ) -> None:
        """
        Remove item from cart
        
        Args:
            user_id: User ID
            cart_item_id: Cart item ID
        
        Raises:
            HTTPException: If not found or not authorized
        """
        # Verify ownership
        cart_item = await self.cart_repo.get(cart_item_id)
        if not cart_item or cart_item.user_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Cart item not found"
            )
        
        await self.cart_repo.delete(cart_item_id)
    
    async def sync_cart(
        self,
        user_id: UUID,
        sync_request: CartSyncRequest
    ) -> CartResponse:
        """
        Sync cart items (for guest → logged in transition)
        
        Args:
            user_id: User ID
            sync_request: Items to sync
        
        Returns:
            Updated cart
        """
        # Clear existing cart
        await self.cart_repo.clear_user_cart(user_id)
        
        # Add all items
        for item_data in sync_request.items:
            try:
                await self.add_to_cart(
                    user_id,
                    CartItemCreate(
                        product_id=item_data.product_id,
                        variant_id=item_data.variant_id,
                        quantity=item_data.quantity,
                    )
                )
            except HTTPException:
                # Skip items that can't be added (out of stock, etc.)
                continue
        
        # Return updated cart
        return await self.get_cart(user_id)
    
    async def clear_cart(self, user_id: UUID) -> None:
        """
        Clear all items from cart
        
        Args:
            user_id: User ID
        """
        await self.cart_repo.clear_user_cart(user_id)
    
    async def _build_cart_item_response(self, cart_item: CartItem) -> CartItemResponse:
        """
        Build cart item response with computed fields
        
        Args:
            cart_item: Cart item with product and variant loaded
        
        Returns:
            Cart item response
        """
        # Determine unit price
        if cart_item.variant:
            unit_price = cart_item.variant.price
        else:
            unit_price = cart_item.product.base_price
        
        # Build response
        return CartItemResponse(
            id=cart_item.id,
            product_id=cart_item.product_id,
            variant_id=cart_item.variant_id,
            quantity=cart_item.quantity,
            added_at=cart_item.created_at,
            product=ProductSummary.model_validate(cart_item.product),
            variant=VariantSummary.model_validate(cart_item.variant) if cart_item.variant else None,
            unit_price=unit_price,
            total_price=unit_price * cart_item.quantity,
        )
    
    async def _group_by_shop(self, items: List[CartItemResponse]) -> List[ShopCartGroup]:
        """
        Group cart items by shop
        
        Args:
            items: List of cart items
        
        Returns:
            List of shop groups
        """
        # Group items by shop_id
        shop_items = defaultdict(list)
        
        for item in items:
            # Get product to access shop_id
            product = await self.product_repo.get(item.product_id)
            if product:
                shop_items[product.shop_id].append(item)
        
        # Build shop groups
        groups = []
        for shop_id, shop_item_list in shop_items.items():
            # Get shop name
            from app.repositories.shop import ShopRepository
            shop_repo = ShopRepository(self.cart_repo.db)
            shop = await shop_repo.get(shop_id)
            
            if shop:
                subtotal = sum(item.total_price for item in shop_item_list)
                groups.append(ShopCartGroup(
                    shop_id=shop_id,
                    shop_name=shop.name,
                    items=shop_item_list,
                    subtotal=subtotal,
                ))
        
        return groups
