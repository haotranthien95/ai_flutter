"""
User profile and address API routes
"""
from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, UploadFile, File, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.dependencies import get_current_user, get_db
from app.models.user import User
from app.schemas.address import AddressCreate, AddressUpdate, AddressResponse
from app.schemas.user import UserResponse, UserUpdate
from app.services.address import AddressService
from app.services.user import UserService

router = APIRouter()


# Profile endpoints
@router.get("/profile", response_model=UserResponse)
async def get_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get current user profile"""
    user_service = UserService(db)
    return await user_service.get_profile(current_user.id)


@router.put("/profile", response_model=UserResponse)
async def update_profile(
    profile_data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update current user profile"""
    user_service = UserService(db)
    return await user_service.update_profile(current_user.id, profile_data)


@router.post("/profile/avatar", status_code=status.HTTP_200_OK)
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Upload user avatar"""
    user_service = UserService(db)
    avatar_url = await user_service.upload_avatar(current_user.id, file)
    return {"avatar_url": avatar_url}


# Address endpoints
@router.get("/profile/addresses", response_model=List[AddressResponse])
async def list_addresses(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get all addresses for current user"""
    address_service = AddressService(db)
    return await address_service.list_addresses(current_user.id)


@router.post(
    "/profile/addresses",
    response_model=AddressResponse,
    status_code=status.HTTP_201_CREATED
)
async def create_address(
    address_data: AddressCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new address"""
    address_service = AddressService(db)
    return await address_service.create_address(current_user.id, address_data)


@router.get("/profile/addresses/{address_id}", response_model=AddressResponse)
async def get_address(
    address_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific address"""
    address_service = AddressService(db)
    return await address_service.get_address(current_user.id, address_id)


@router.put("/profile/addresses/{address_id}", response_model=AddressResponse)
async def update_address(
    address_id: UUID,
    address_data: AddressUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update an address"""
    address_service = AddressService(db)
    return await address_service.update_address(
        current_user.id,
        address_id,
        address_data
    )


@router.delete("/profile/addresses/{address_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_address(
    address_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete an address"""
    address_service = AddressService(db)
    await address_service.delete_address(current_user.id, address_id)


@router.post("/profile/addresses/{address_id}/set-default", response_model=AddressResponse)
async def set_default_address(
    address_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Set an address as default"""
    address_service = AddressService(db)
    return await address_service.set_default_address(current_user.id, address_id)
