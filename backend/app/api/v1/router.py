"""
Main API v1 router
"""
from fastapi import APIRouter

from app.api.v1 import auth, users, seller, products, categories, cart, orders, vouchers, reviews, notifications

# Create main API router
api_router = APIRouter()

# Include sub-routers
api_router.include_router(auth.router)
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(seller.router, prefix="/seller", tags=["Seller"])
api_router.include_router(products.router)
api_router.include_router(categories.router)
api_router.include_router(cart.router)
api_router.include_router(orders.router, prefix="/orders", tags=["Orders"])
api_router.include_router(vouchers.router, tags=["Vouchers"])
api_router.include_router(reviews.router)
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
