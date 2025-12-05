"""
Main API v1 router
"""
from fastapi import APIRouter

from app.api.v1 import auth, users, seller

# Create main API router
api_router = APIRouter()

# Include sub-routers
api_router.include_router(auth.router)
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(seller.router, prefix="/seller", tags=["Seller"])

# Future routers will be added here:
# from app.api.v1 import products, cart, orders, etc.
# api_router.include_router(products.router)
# api_router.include_router(cart.router)
# api_router.include_router(orders.router)
