"""
Address service for address management
"""
from typing import List
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.address import Address
from app.repositories.address import AddressRepository
from app.schemas.address import AddressCreate, AddressUpdate, AddressResponse


class AddressService:
    """Service for address operations"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.address_repo = AddressRepository(db)
    
    async def list_addresses(self, user_id: UUID) -> List[AddressResponse]:
        """
        Get all addresses for a user
        
        Args:
            user_id: User UUID
            
        Returns:
            List of AddressResponse
        """
        addresses = await self.address_repo.list_by_user(user_id)
        return [AddressResponse.model_validate(addr) for addr in addresses]
    
    async def get_address(self, user_id: UUID, address_id: UUID) -> AddressResponse:
        """
        Get a specific address
        
        Args:
            user_id: User UUID
            address_id: Address UUID
            
        Returns:
            AddressResponse
            
        Raises:
            HTTPException: If address not found or doesn't belong to user
        """
        address = await self.address_repo.get_by_id_and_user(address_id, user_id)
        if not address:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Address not found"
            )
        
        return AddressResponse.model_validate(address)
    
    async def create_address(
        self,
        user_id: UUID,
        address_data: AddressCreate
    ) -> AddressResponse:
        """
        Create a new address
        
        Args:
            user_id: User UUID
            address_data: Address creation data
            
        Returns:
            Created AddressResponse
        """
        # If this is set as default, unset other defaults first
        if address_data.is_default:
            await self.address_repo.unset_all_defaults(user_id)
        
        # If this is the first address, make it default
        address_count = await self.address_repo.count_by_user(user_id)
        if address_count == 0:
            address_data.is_default = True
        
        # Create address
        address = Address(
            user_id=user_id,
            **address_data.model_dump()
        )
        
        created_address = await self.address_repo.create(address)
        await self.db.commit()
        
        return AddressResponse.model_validate(created_address)
    
    async def update_address(
        self,
        user_id: UUID,
        address_id: UUID,
        update_data: AddressUpdate
    ) -> AddressResponse:
        """
        Update an address
        
        Args:
            user_id: User UUID
            address_id: Address UUID
            update_data: Address update data
            
        Returns:
            Updated AddressResponse
            
        Raises:
            HTTPException: If address not found or doesn't belong to user
        """
        address = await self.address_repo.get_by_id_and_user(address_id, user_id)
        if not address:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Address not found"
            )
        
        # If setting as default, unset other defaults first
        if update_data.is_default:
            await self.address_repo.unset_all_defaults(user_id)
        
        # Update fields
        update_dict = update_data.model_dump(exclude_unset=True)
        for field, value in update_dict.items():
            setattr(address, field, value)
        
        updated_address = await self.address_repo.update(address)
        await self.db.commit()
        
        return AddressResponse.model_validate(updated_address)
    
    async def delete_address(self, user_id: UUID, address_id: UUID) -> None:
        """
        Delete an address
        
        Args:
            user_id: User UUID
            address_id: Address UUID
            
        Raises:
            HTTPException: If address not found, doesn't belong to user,
                          or is the last address
        """
        address = await self.address_repo.get_by_id_and_user(address_id, user_id)
        if not address:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Address not found"
            )
        
        # Check if this is the user's only address
        address_count = await self.address_repo.count_by_user(user_id)
        if address_count <= 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot delete your only address. Please add another address first."
            )
        
        # If deleting default address, set another as default
        if address.is_default:
            addresses = await self.address_repo.list_by_user(user_id)
            # Find first non-deleted address
            for addr in addresses:
                if addr.id != address_id:
                    addr.is_default = True
                    await self.address_repo.update(addr)
                    break
        
        await self.address_repo.delete_by_id_and_user(address_id, user_id)
        await self.db.commit()
    
    async def set_default_address(
        self,
        user_id: UUID,
        address_id: UUID
    ) -> AddressResponse:
        """
        Set an address as default
        
        Args:
            user_id: User UUID
            address_id: Address UUID
            
        Returns:
            Updated AddressResponse
            
        Raises:
            HTTPException: If address not found or doesn't belong to user
        """
        address = await self.address_repo.get_by_id_and_user(address_id, user_id)
        if not address:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Address not found"
            )
        
        # Set as default
        await self.address_repo.set_default(user_id, address_id)
        await self.db.commit()
        
        # Refresh to get updated state
        await self.db.refresh(address)
        
        return AddressResponse.model_validate(address)
