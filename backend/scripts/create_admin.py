#!/usr/bin/env python3
"""
Script to create an admin user
"""
import asyncio
import getpass
import sys
from pathlib import Path

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal, init_db
from app.models import User
from app.core.security import get_password_hash
from app.models.user import UserRole


async def create_admin_user(
    full_name: str,
    email: str,
    phone_number: str,
    password: str
) -> User:
    """
    Create an admin user
    
    Args:
        full_name: Full name of admin
        email: Email address
        phone_number: Phone number
        password: Password
        
    Returns:
        Created User object
    """
    async with AsyncSessionLocal() as session:
        # Check if user already exists
        result = await session.execute(
            select(User).where(User.email == email)
        )
        existing_user = result.scalar_one_or_none()
        
        if existing_user:
            if existing_user.role == UserRole.ADMIN:
                print(f"❌ Admin user with email {email} already exists")
                return existing_user
            else:
                # Upgrade existing user to admin
                existing_user.role = UserRole.ADMIN
                await session.commit()
                await session.refresh(existing_user)
                print(f"✅ Upgraded existing user {email} to admin role")
                return existing_user
        
        # Create new admin user
        admin_user = User(
            full_name=full_name,
            email=email,
            phone_number=phone_number,
            hashed_password=get_password_hash(password),
            role=UserRole.ADMIN,
            is_verified=True  # Auto-verify admin
        )
        
        session.add(admin_user)
        await session.commit()
        await session.refresh(admin_user)
        
        print(f"✅ Created admin user: {full_name} ({email})")
        return admin_user


async def main():
    """Main function to create admin user with interactive prompts"""
    print("=" * 60)
    print("Create Admin User")
    print("=" * 60)
    print()
    
    # Initialize database
    print("Initializing database connection...")
    await init_db()
    print("✅ Database connected")
    print()
    
    # Get admin details
    full_name = input("Enter full name: ").strip()
    if not full_name:
        print("❌ Full name is required")
        sys.exit(1)
    
    email = input("Enter email: ").strip()
    if not email or '@' not in email:
        print("❌ Valid email is required")
        sys.exit(1)
    
    phone_number = input("Enter phone number (e.g., +84901234567): ").strip()
    if not phone_number:
        print("❌ Phone number is required")
        sys.exit(1)
    
    password = getpass.getpass("Enter password: ")
    if not password or len(password) < 8:
        print("❌ Password must be at least 8 characters")
        sys.exit(1)
    
    password_confirm = getpass.getpass("Confirm password: ")
    if password != password_confirm:
        print("❌ Passwords do not match")
        sys.exit(1)
    
    print()
    print("Creating admin user...")
    
    # Create admin user
    admin = await create_admin_user(
        full_name=full_name,
        email=email,
        phone_number=phone_number,
        password=password
    )
    
    print()
    print("=" * 60)
    print("Admin User Details")
    print("=" * 60)
    print(f"ID: {admin.id}")
    print(f"Full Name: {admin.full_name}")
    print(f"Email: {admin.email}")
    print(f"Phone: {admin.phone_number}")
    print(f"Role: {admin.role.value}")
    print(f"Verified: {admin.is_verified}")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
