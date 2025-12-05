"""
FastAPI dependencies for authentication and authorization
"""
from typing import Optional
from uuid import UUID

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_user_id_from_token, get_user_role_from_token
from app.database import get_db
from app.models.user import User, UserRole
from app.repositories.user import UserRepository
from app.repositories.product import ProductRepository, ProductVariantRepository
from app.repositories.category import CategoryRepository
from app.repositories.shop import ShopRepository
from app.repositories.cart import CartRepository
from app.repositories.order import OrderRepository, OrderItemRepository
from app.repositories.voucher import VoucherRepository
from app.services.product import ProductService
from app.services.category import CategoryService
from app.services.cart import CartService
from app.services.order import OrderService
from app.services.voucher import VoucherService

# HTTP Bearer security scheme
security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> User:
    """
    Get current authenticated user from JWT token
    
    Args:
        credentials: HTTP Authorization header with Bearer token
        db: Database session
        
    Returns:
        Current authenticated user
        
    Raises:
        HTTPException: If token is invalid or user not found
    """
    token = credentials.credentials
    
    try:
        # Extract user ID from token
        user_id = get_user_id_from_token(token)
        user_uuid = UUID(user_id)
        
        # Get user from database
        user_repo = UserRepository(db)
        user = await user_repo.get_by_id(user_uuid)
        
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found"
            )
        
        if user.is_suspended:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is suspended"
            )
        
        return user
        
    except (JWTError, ValueError) as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Could not validate credentials: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )


async def get_current_verified_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Get current user and ensure they are verified
    
    Args:
        current_user: Current authenticated user
        
    Returns:
        Current verified user
        
    Raises:
        HTTPException: If user is not verified
    """
    if not current_user.is_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Phone number not verified. Please verify your account."
        )
    
    return current_user


async def require_seller(
    current_user: User = Depends(get_current_verified_user)
) -> User:
    """
    Require user to have SELLER or ADMIN role
    
    Args:
        current_user: Current authenticated and verified user
        
    Returns:
        Current user if they are a seller or admin
        
    Raises:
        HTTPException: If user is not a seller or admin
    """
    if current_user.role not in [UserRole.SELLER, UserRole.ADMIN]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seller privileges required. Please register as a seller first."
        )
    
    return current_user


async def require_admin(
    current_user: User = Depends(get_current_verified_user)
) -> User:
    """
    Require user to have ADMIN role
    
    Args:
        current_user: Current authenticated and verified user
        
    Returns:
        Current user if they are an admin
        
    Raises:
        HTTPException: If user is not an admin
    """
    if current_user.role != UserRole.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin privileges required"
        )
    
    return current_user


async def get_optional_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer(auto_error=False)),
    db: AsyncSession = Depends(get_db)
) -> Optional[User]:
    """
    Get current user if authenticated, None otherwise
    Useful for endpoints that work differently for authenticated vs anonymous users
    
    Args:
        credentials: Optional HTTP Authorization header
        db: Database session
        
    Returns:
        Current user if authenticated, None otherwise
    """
    if credentials is None:
        return None
    
    try:
        token = credentials.credentials
        user_id = get_user_id_from_token(token)
        user_uuid = UUID(user_id)
        
        user_repo = UserRepository(db)
        user = await user_repo.get_by_id(user_uuid)
        
        if user and not user.is_suspended:
            return user
        
        return None
        
    except (JWTError, ValueError):
        return None


# Service dependencies

async def get_product_service(
    db: AsyncSession = Depends(get_db)
) -> ProductService:
    """
    Get ProductService instance with all required repositories
    
    Args:
        db: Database session
        
    Returns:
        ProductService instance
    """
    product_repo = ProductRepository(db)
    variant_repo = ProductVariantRepository(db)
    category_repo = CategoryRepository(db)
    shop_repo = ShopRepository(db)
    
    return ProductService(
        product_repo=product_repo,
        variant_repo=variant_repo,
        category_repo=category_repo,
        shop_repo=shop_repo,
    )


async def get_category_service(
    db: AsyncSession = Depends(get_db)
) -> CategoryService:
    """
    Get CategoryService instance
    
    Args:
        db: Database session
        
    Returns:
        CategoryService instance
    """
    category_repo = CategoryRepository(db)
    return CategoryService(category_repo=category_repo)


async def get_cart_service(
    db: AsyncSession = Depends(get_db)
) -> CartService:
    """
    Get CartService instance with all required repositories
    
    Args:
        db: Database session
        
    Returns:
        CartService instance
    """
    cart_repo = CartRepository(db)
    product_repo = ProductRepository(db)
    variant_repo = ProductVariantRepository(db)
    
    return CartService(
        cart_repo=cart_repo,
        product_repo=product_repo,
        variant_repo=variant_repo,
    )


async def get_order_service(
    db: AsyncSession = Depends(get_db)
) -> OrderService:
    """
    Get OrderService instance with all required repositories
    
    Args:
        db: Database session
        
    Returns:
        OrderService instance
    """
    order_repo = OrderRepository(db)
    order_item_repo = OrderItemRepository(db)
    product_repo = ProductRepository(db)
    variant_repo = ProductVariantRepository(db)
    cart_repo = CartRepository(db)
    shop_repo = ShopRepository(db)
    
    return OrderService(
        order_repo=order_repo,
        order_item_repo=order_item_repo,
        product_repo=product_repo,
        variant_repo=variant_repo,
        cart_repo=cart_repo,
        shop_repo=shop_repo,
        db=db,
    )


async def get_voucher_service(
    db: AsyncSession = Depends(get_db)
) -> VoucherService:
    """
    Get VoucherService instance with all required repositories
    
    Args:
        db: Database session
        
    Returns:
        VoucherService instance
    """
    voucher_repo = VoucherRepository(db)
    shop_repo = ShopRepository(db)
    
    return VoucherService(
        voucher_repo=voucher_repo,
        shop_repo=shop_repo,
    )
