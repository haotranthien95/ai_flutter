"""
Order service for business logic
"""
from typing import List, Optional
from uuid import UUID
from decimal import Decimal
from datetime import datetime
from collections import defaultdict
import secrets

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.order import Order, OrderItem, OrderStatus, PaymentMethod, PaymentStatus
from app.models.address import Address
from app.repositories.order import OrderRepository, OrderItemRepository
from app.repositories.product import ProductRepository, ProductVariantRepository
from app.repositories.cart import CartRepository
from app.repositories.shop import ShopRepository
from app.schemas.order import (
    OrderCreate,
    OrderResponse,
    OrderSummaryResponse,
    OrderListResponse,
    OrderItemResponse,
    OrderCancelRequest,
    OrderStatusUpdate,
)


class OrderService:
    """Service for order business logic"""
    
    def __init__(
        self,
        order_repo: OrderRepository,
        order_item_repo: OrderItemRepository,
        product_repo: ProductRepository,
        variant_repo: ProductVariantRepository,
        cart_repo: CartRepository,
        shop_repo: ShopRepository,
        db: AsyncSession,
    ):
        self.order_repo = order_repo
        self.order_item_repo = order_item_repo
        self.product_repo = product_repo
        self.variant_repo = variant_repo
        self.cart_repo = cart_repo
        self.shop_repo = shop_repo
        self.db = db
    
    async def create_orders(
        self,
        user_id: UUID,
        order_data: OrderCreate,
        address: Address
    ) -> List[OrderResponse]:
        """
        Create orders from cart items (one order per shop)
        
        Args:
            user_id: Buyer user ID
            order_data: Order creation data
            address: Shipping address
        
        Returns:
            List of created orders
        
        Raises:
            HTTPException: If validation fails or stock insufficient
        """
        # Validate items and check stock
        items_by_shop = defaultdict(list)
        
        for item_data in order_data.items:
            # Get product
            product = await self.product_repo.get_with_variants(item_data.product_id)
            if not product or not product.is_active:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Product {item_data.product_id} not found or not available"
                )
            
            # Get variant if specified
            variant = None
            if item_data.variant_id:
                variant = await self.variant_repo.get(item_data.variant_id)
                if not variant or variant.product_id != product.id:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail=f"Variant {item_data.variant_id} not found"
                    )
                if not variant.is_active:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Variant {item_data.variant_id} is not available"
                    )
            
            # Check stock
            available_stock = variant.stock if variant else product.total_stock
            if item_data.quantity > available_stock:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Insufficient stock for {product.title}. Only {available_stock} available"
                )
            
            # Group by shop
            items_by_shop[product.shop_id].append({
                "product": product,
                "variant": variant,
                "quantity": item_data.quantity,
            })
        
        # Create orders (one per shop)
        created_orders = []
        
        for shop_id, shop_items in items_by_shop.items():
            # Get shop for shipping fee
            shop = await self.shop_repo.get(shop_id)
            if not shop:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail=f"Shop {shop_id} not found"
                )
            
            # Calculate totals
            subtotal = Decimal('0')
            order_items_data = []
            
            for item in shop_items:
                product = item["product"]
                variant = item["variant"]
                quantity = item["quantity"]
                
                # Determine unit price
                unit_price = variant.price if variant else product.base_price
                item_subtotal = unit_price * quantity
                subtotal += item_subtotal
                
                # Create product snapshot
                product_snapshot = {
                    "id": str(product.id),
                    "title": product.title,
                    "base_price": str(product.base_price),
                    "images": product.images,
                    "condition": product.condition.value,
                }
                
                variant_snapshot = None
                if variant:
                    variant_snapshot = {
                        "id": str(variant.id),
                        "name": variant.name,
                        "sku": variant.sku,
                        "price": str(variant.price),
                        "attributes": variant.attributes,
                    }
                
                order_items_data.append({
                    "product_id": product.id,
                    "variant_id": variant.id if variant else None,
                    "quantity": quantity,
                    "unit_price": unit_price,
                    "subtotal": item_subtotal,
                    "product_snapshot": product_snapshot,
                    "variant_snapshot": variant_snapshot,
                })
            
            # Calculate shipping fee and total
            shipping_fee = shop.shipping_fee
            discount = Decimal('0')  # TODO: Apply voucher discount
            total = subtotal + shipping_fee - discount
            
            # Create shipping address snapshot
            shipping_address = {
                "full_name": address.full_name,
                "phone_number": address.phone_number,
                "address_line1": address.address_line1,
                "address_line2": address.address_line2,
                "ward": address.ward,
                "district": address.district,
                "city": address.city,
                "postal_code": address.postal_code,
            }
            
            # Generate unique order number
            order_number = await self._generate_order_number()
            
            # Create order
            order = Order(
                order_number=order_number,
                buyer_id=user_id,
                shop_id=shop_id,
                address_id=address.id,
                shipping_address=shipping_address,
                status=OrderStatus.PENDING,
                payment_method=order_data.payment_method,
                payment_status=PaymentStatus.PENDING,
                subtotal=subtotal,
                shipping_fee=shipping_fee,
                discount=discount,
                total=total,
                currency="VND",
                voucher_code=order_data.voucher_code,
                notes=order_data.notes,
            )
            
            order = await self.order_repo.create(order)
            
            # Create order items
            for item_data in order_items_data:
                order_item = OrderItem(
                    order_id=order.id,
                    product_id=item_data["product_id"],
                    variant_id=item_data["variant_id"],
                    product_snapshot=item_data["product_snapshot"],
                    variant_snapshot=item_data["variant_snapshot"],
                    quantity=item_data["quantity"],
                    unit_price=item_data["unit_price"],
                    subtotal=item_data["subtotal"],
                    currency="VND",
                )
                await self.order_item_repo.create(order_item)
            
            # Decrement stock
            for item in shop_items:
                product = item["product"]
                variant = item["variant"]
                quantity = item["quantity"]
                
                if variant:
                    variant.stock -= quantity
                    await self.variant_repo.update(variant)
                else:
                    product.total_stock -= quantity
                    await self.product_repo.update(product)
            
            await self.db.commit()
            
            # Reload with relations
            order = await self.order_repo.get_with_items(order.id)
            created_orders.append(self._build_order_response(order))
        
        # Clear cart after successful order creation
        await self.cart_repo.clear_user_cart(user_id)
        await self.db.commit()
        
        return created_orders
    
    async def list_orders(
        self,
        user_id: UUID,
        status_filter: Optional[OrderStatus] = None,
        page: int = 1,
        page_size: int = 20
    ) -> OrderListResponse:
        """
        List user's orders with optional filtering
        
        Args:
            user_id: User ID
            status_filter: Optional status filter
            page: Page number (1-indexed)
            page_size: Items per page
        
        Returns:
            Paginated order list
        """
        skip = (page - 1) * page_size
        orders, total = await self.order_repo.list_by_buyer(
            buyer_id=user_id,
            status=status_filter,
            skip=skip,
            limit=page_size
        )
        
        order_summaries = [self._build_order_summary(order) for order in orders]
        
        total_pages = (total + page_size - 1) // page_size
        
        return OrderListResponse(
            orders=order_summaries,
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages,
        )
    
    async def get_order_detail(
        self,
        user_id: UUID,
        order_id: UUID
    ) -> OrderResponse:
        """
        Get order detail
        
        Args:
            user_id: User ID
            order_id: Order ID
        
        Returns:
            Order detail
        
        Raises:
            HTTPException: If not found or unauthorized
        """
        order = await self.order_repo.get_with_items(order_id)
        
        if not order or order.buyer_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found"
            )
        
        return self._build_order_response(order)
    
    async def cancel_order(
        self,
        user_id: UUID,
        order_id: UUID,
        cancel_request: OrderCancelRequest
    ) -> OrderResponse:
        """
        Cancel an order
        
        Args:
            user_id: User ID
            order_id: Order ID
            cancel_request: Cancellation reason
        
        Returns:
            Updated order
        
        Raises:
            HTTPException: If not found, unauthorized, or cannot cancel
        """
        order = await self.order_repo.get_with_items(order_id)
        
        if not order or order.buyer_id != user_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found"
            )
        
        # Can only cancel if order is PENDING or CONFIRMED
        if order.status not in [OrderStatus.PENDING, OrderStatus.CONFIRMED]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot cancel order with status {order.status.value}"
            )
        
        # Update status
        order.status = OrderStatus.CANCELLED
        order.cancellation_reason = cancel_request.reason
        
        # Restore stock
        for item in order.items:
            if item.variant_id:
                variant = await self.variant_repo.get(item.variant_id)
                if variant:
                    variant.stock += item.quantity
                    await self.variant_repo.update(variant)
            elif item.product_id:
                product = await self.product_repo.get(item.product_id)
                if product:
                    product.total_stock += item.quantity
                    await self.product_repo.update(product)
        
        order = await self.order_repo.update(order)
        await self.db.commit()
        
        return self._build_order_response(order)
    
    # ========================================================================
    # Seller methods
    # ========================================================================
    
    async def list_shop_orders(
        self,
        shop_id: UUID,
        status_filter: Optional[OrderStatus] = None,
        page: int = 1,
        page_size: int = 20
    ) -> OrderListResponse:
        """
        List shop's orders
        
        Args:
            shop_id: Shop ID
            status_filter: Optional status filter
            page: Page number (1-indexed)
            page_size: Items per page
        
        Returns:
            Paginated order list
        """
        skip = (page - 1) * page_size
        orders, total = await self.order_repo.list_by_shop(
            shop_id=shop_id,
            status=status_filter,
            skip=skip,
            limit=page_size
        )
        
        order_summaries = [self._build_order_summary(order) for order in orders]
        
        total_pages = (total + page_size - 1) // page_size
        
        return OrderListResponse(
            orders=order_summaries,
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages,
        )
    
    async def get_shop_order_detail(
        self,
        shop_id: UUID,
        order_id: UUID
    ) -> OrderResponse:
        """
        Get shop order detail
        
        Args:
            shop_id: Shop ID
            order_id: Order ID
        
        Returns:
            Order detail
        
        Raises:
            HTTPException: If not found or unauthorized
        """
        order = await self.order_repo.get_with_items(order_id)
        
        if not order or order.shop_id != shop_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found"
            )
        
        return self._build_order_response(order)
    
    async def update_order_status(
        self,
        shop_id: UUID,
        order_id: UUID,
        status_update: OrderStatusUpdate
    ) -> OrderResponse:
        """
        Update order status (seller only)
        
        Args:
            shop_id: Shop ID
            order_id: Order ID
            status_update: New status
        
        Returns:
            Updated order
        
        Raises:
            HTTPException: If not found, unauthorized, or invalid transition
        """
        order = await self.order_repo.get_with_items(order_id)
        
        if not order or order.shop_id != shop_id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Order not found"
            )
        
        # Validate status transition
        if not self._is_valid_status_transition(order.status, status_update.status):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot transition from {order.status.value} to {status_update.status.value}"
            )
        
        # Update status
        old_status = order.status
        order.status = status_update.status
        
        # Set completed_at if order is completed
        if status_update.status == OrderStatus.COMPLETED:
            order.completed_at = datetime.utcnow()
            order.payment_status = PaymentStatus.PAID  # Assume paid on completion
        
        order = await self.order_repo.update(order)
        await self.db.commit()
        
        # TODO: Create notification for buyer
        
        return self._build_order_response(order)
    
    # ========================================================================
    # Helper methods
    # ========================================================================
    
    async def _generate_order_number(self) -> str:
        """Generate unique order number"""
        while True:
            # Format: ORD-YYYYMMDD-XXXXXX (e.g., ORD-20251205-A3B5C7)
            date_str = datetime.utcnow().strftime("%Y%m%d")
            random_str = secrets.token_hex(3).upper()
            order_number = f"ORD-{date_str}-{random_str}"
            
            # Check if exists
            existing = await self.order_repo.get_by_order_number(order_number)
            if not existing:
                return order_number
    
    def _is_valid_status_transition(
        self,
        current: OrderStatus,
        new: OrderStatus
    ) -> bool:
        """
        Validate status transition
        
        Valid transitions:
        - PENDING → CONFIRMED, CANCELLED
        - CONFIRMED → PACKED, CANCELLED
        - PACKED → SHIPPING
        - SHIPPING → DELIVERED
        - DELIVERED → COMPLETED
        """
        valid_transitions = {
            OrderStatus.PENDING: [OrderStatus.CONFIRMED, OrderStatus.CANCELLED],
            OrderStatus.CONFIRMED: [OrderStatus.PACKED, OrderStatus.CANCELLED],
            OrderStatus.PACKED: [OrderStatus.SHIPPING],
            OrderStatus.SHIPPING: [OrderStatus.DELIVERED],
            OrderStatus.DELIVERED: [OrderStatus.COMPLETED],
        }
        
        return new in valid_transitions.get(current, [])
    
    def _build_order_response(self, order: Order) -> OrderResponse:
        """Build order response with items"""
        items = [
            OrderItemResponse(
                id=item.id,
                order_id=item.order_id,
                product_id=item.product_id,
                variant_id=item.variant_id,
                product_snapshot=item.product_snapshot,
                variant_snapshot=item.variant_snapshot,
                quantity=item.quantity,
                unit_price=item.unit_price,
                subtotal=item.subtotal,
                currency=item.currency,
            )
            for item in order.items
        ]
        
        return OrderResponse(
            id=order.id,
            order_number=order.order_number,
            buyer_id=order.buyer_id,
            shop_id=order.shop_id,
            address_id=order.address_id,
            shipping_address=order.shipping_address,
            status=order.status,
            payment_method=order.payment_method,
            payment_status=order.payment_status,
            subtotal=order.subtotal,
            shipping_fee=order.shipping_fee,
            discount=order.discount,
            total=order.total,
            currency=order.currency,
            voucher_code=order.voucher_code,
            notes=order.notes,
            cancellation_reason=order.cancellation_reason,
            created_at=order.created_at,
            updated_at=order.updated_at,
            completed_at=order.completed_at,
            items=items,
        )
    
    def _build_order_summary(self, order: Order) -> OrderSummaryResponse:
        """Build order summary for list views"""
        return OrderSummaryResponse(
            id=order.id,
            order_number=order.order_number,
            shop_id=order.shop_id,
            shop_name=order.shop.shop_name if order.shop else "Unknown Shop",
            status=order.status,
            payment_method=order.payment_method,
            payment_status=order.payment_status,
            total=order.total,
            currency=order.currency,
            item_count=len(order.items),
            created_at=order.created_at,
        )
