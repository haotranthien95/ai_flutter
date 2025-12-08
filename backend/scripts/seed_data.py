#!/usr/bin/env python3
"""
Script to seed test data into the database
"""
import asyncio
import random
import sys
from datetime import datetime, timedelta
from decimal import Decimal
from pathlib import Path
from uuid import uuid4

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal, init_db
from app.models import (
    User, Shop, Category, Product, Address,
    Order, OrderItem, Review, Voucher, Notification
)
from app.models.user import UserRole
from app.models.order import OrderStatus, PaymentMethod, PaymentStatus
from app.models.voucher import VoucherType, DiscountType
from app.models.notification import NotificationType
from app.core.security import get_password_hash


# Sample data
SAMPLE_USERS = [
    {"full_name": "Nguyen Van A", "email": "user1@example.com", "phone": "+84901234501", "role": UserRole.CUSTOMER},
    {"full_name": "Tran Thi B", "email": "user2@example.com", "phone": "+84901234502", "role": UserRole.CUSTOMER},
    {"full_name": "Le Van C", "email": "user3@example.com", "phone": "+84901234503", "role": UserRole.SELLER},
    {"full_name": "Pham Thi D", "email": "user4@example.com", "phone": "+84901234504", "role": UserRole.SELLER},
    {"full_name": "Hoang Van E", "email": "user5@example.com", "phone": "+84901234505", "role": UserRole.CUSTOMER},
    {"full_name": "Vo Thi F", "email": "user6@example.com", "phone": "+84901234506", "role": UserRole.SELLER},
    {"full_name": "Dang Van G", "email": "user7@example.com", "phone": "+84901234507", "role": UserRole.CUSTOMER},
    {"full_name": "Bui Thi H", "email": "user8@example.com", "phone": "+84901234508", "role": UserRole.CUSTOMER},
    {"full_name": "Do Van I", "email": "user9@example.com", "phone": "+84901234509", "role": UserRole.SELLER},
    {"full_name": "Admin User", "email": "admin@example.com", "phone": "+84901234500", "role": UserRole.ADMIN},
]

SAMPLE_SHOPS = [
    {"name": "Tech Store", "description": "Latest electronics and gadgets", "address": "123 Tech Street, HCMC"},
    {"name": "Fashion House", "description": "Trendy clothing and accessories", "address": "456 Fashion Ave, Hanoi"},
    {"name": "Home Decor", "description": "Beautiful items for your home", "address": "789 Home Blvd, Da Nang"},
    {"name": "Book Haven", "description": "Books for every reader", "address": "321 Book Lane, HCMC"},
    {"name": "Sports World", "description": "Everything for sports enthusiasts", "address": "654 Sports Road, Hanoi"},
]

SAMPLE_CATEGORIES = [
    # Top level
    {"name": "Electronics", "parent": None},
    {"name": "Fashion", "parent": None},
    {"name": "Home & Garden", "parent": None},
    {"name": "Books", "parent": None},
    {"name": "Sports", "parent": None},
    # Sub-categories
    {"name": "Smartphones", "parent": "Electronics"},
    {"name": "Laptops", "parent": "Electronics"},
    {"name": "Men's Clothing", "parent": "Fashion"},
    {"name": "Women's Clothing", "parent": "Fashion"},
    {"name": "Furniture", "parent": "Home & Garden"},
    {"name": "Kitchen", "parent": "Home & Garden"},
    {"name": "Fiction", "parent": "Books"},
    {"name": "Non-Fiction", "parent": "Books"},
    {"name": "Fitness", "parent": "Sports"},
    {"name": "Outdoor", "parent": "Sports"},
]

SAMPLE_PRODUCTS = [
    {"name": "iPhone 15 Pro", "price": "29990000", "category": "Smartphones"},
    {"name": "Samsung Galaxy S24", "price": "25990000", "category": "Smartphones"},
    {"name": "MacBook Pro M3", "price": "45990000", "category": "Laptops"},
    {"name": "Dell XPS 15", "price": "35990000", "category": "Laptops"},
    {"name": "Men's Cotton T-Shirt", "price": "299000", "category": "Men's Clothing"},
    {"name": "Women's Summer Dress", "price": "599000", "category": "Women's Clothing"},
    {"name": "Leather Sofa", "price": "15990000", "category": "Furniture"},
    {"name": "Dining Table Set", "price": "8990000", "category": "Furniture"},
    {"name": "Blender Pro", "price": "1990000", "category": "Kitchen"},
    {"name": "Coffee Maker", "price": "2490000", "category": "Kitchen"},
]


async def seed_users(session: AsyncSession) -> dict:
    """Seed users"""
    print("Seeding users...")
    
    users = {}
    for data in SAMPLE_USERS:
        # Check if user exists
        result = await session.execute(
            select(User).where(User.email == data["email"])
        )
        user = result.scalar_one_or_none()
        
        if not user:
            user = User(
                full_name=data["full_name"],
                email=data["email"],
                phone_number=data["phone"],
                hashed_password=get_password_hash("password123"),
                role=data["role"],
                is_verified=True
            )
            session.add(user)
        
        users[data["email"]] = user
    
    await session.commit()
    print(f"✅ Seeded {len(users)} users")
    return users


async def seed_shops(session: AsyncSession, users: dict) -> list:
    """Seed shops"""
    print("Seeding shops...")
    
    # Get seller users
    sellers = [u for u in users.values() if u.role == UserRole.SELLER]
    
    shops = []
    for i, data in enumerate(SAMPLE_SHOPS):
        if i >= len(sellers):
            break
            
        # Check if shop exists
        result = await session.execute(
            select(Shop).where(Shop.name == data["name"])
        )
        shop = result.scalar_one_or_none()
        
        if not shop:
            shop = Shop(
                owner_id=sellers[i].id,
                name=data["name"],
                description=data["description"],
                address=data["address"],
                is_active=True
            )
            session.add(shop)
        
        shops.append(shop)
    
    await session.commit()
    print(f"✅ Seeded {len(shops)} shops")
    return shops


async def seed_categories(session: AsyncSession) -> dict:
    """Seed categories"""
    print("Seeding categories...")
    
    categories = {}
    
    # First pass: create top-level categories
    for data in SAMPLE_CATEGORIES:
        if data["parent"] is None:
            result = await session.execute(
                select(Category).where(Category.name == data["name"])
            )
            category = result.scalar_one_or_none()
            
            if not category:
                category = Category(
                    name=data["name"],
                    description=f"{data['name']} category"
                )
                session.add(category)
            
            categories[data["name"]] = category
    
    await session.commit()
    
    # Second pass: create sub-categories
    for data in SAMPLE_CATEGORIES:
        if data["parent"] is not None:
            result = await session.execute(
                select(Category).where(Category.name == data["name"])
            )
            category = result.scalar_one_or_none()
            
            if not category and data["parent"] in categories:
                category = Category(
                    name=data["name"],
                    description=f"{data['name']} category",
                    parent_id=categories[data["parent"]].id
                )
                session.add(category)
                categories[data["name"]] = category
    
    await session.commit()
    print(f"✅ Seeded {len(categories)} categories")
    return categories


async def seed_products(session: AsyncSession, shops: list, categories: dict) -> list:
    """Seed products"""
    print("Seeding products...")
    
    products = []
    
    for data in SAMPLE_PRODUCTS:
        if data["category"] not in categories:
            continue
        
        # Check if product exists
        result = await session.execute(
            select(Product).where(Product.name == data["name"])
        )
        product = result.scalar_one_or_none()
        
        if not product:
            # Randomly assign to a shop
            shop = random.choice(shops)
            
            product = Product(
                shop_id=shop.id,
                category_id=categories[data["category"]].id,
                name=data["name"],
                description=f"High quality {data['name'].lower()}",
                price=Decimal(data["price"]),
                stock_quantity=random.randint(10, 100),
                is_active=True
            )
            session.add(product)
        
        products.append(product)
    
    await session.commit()
    print(f"✅ Seeded {len(products)} products")
    return products


async def seed_addresses(session: AsyncSession, users: dict) -> None:
    """Seed addresses for users"""
    print("Seeding addresses...")
    
    count = 0
    for user in users.values():
        if user.role == UserRole.CUSTOMER:
            # Check if user has addresses
            result = await session.execute(
                select(Address).where(Address.user_id == user.id)
            )
            existing = result.scalars().all()
            
            if not existing:
                address = Address(
                    user_id=user.id,
                    full_name=user.full_name,
                    phone_number=user.phone_number,
                    street_address=f"{random.randint(1, 999)} Test Street",
                    ward="Ward 1",
                    district="District 1",
                    city="Ho Chi Minh City",
                    is_default=True
                )
                session.add(address)
                count += 1
    
    await session.commit()
    print(f"✅ Seeded {count} addresses")


async def seed_orders(session: AsyncSession, users: dict, products: list) -> list:
    """Seed orders"""
    print("Seeding orders...")
    
    customers = [u for u in users.values() if u.role == UserRole.CUSTOMER]
    orders = []
    
    order_statuses = [
        OrderStatus.PENDING,
        OrderStatus.CONFIRMED,
        OrderStatus.PROCESSING,
        OrderStatus.SHIPPED,
        OrderStatus.DELIVERED,
        OrderStatus.CANCELLED
    ]
    
    for i in range(50):
        customer = random.choice(customers)
        
        # Get customer's default address
        result = await session.execute(
            select(Address).where(
                Address.user_id == customer.id,
                Address.is_default == True
            )
        )
        address = result.scalar_one_or_none()
        
        if not address:
            continue
        
        # Create order
        total_amount = Decimal("0")
        order_products = random.sample(products, k=random.randint(1, 3))
        
        for product in order_products:
            quantity = random.randint(1, 3)
            total_amount += product.price * quantity
        
        order = Order(
            user_id=customer.id,
            order_code=f"ORD-{datetime.now().strftime('%Y%m%d')}-{str(uuid4())[:5].upper()}",
            status=random.choice(order_statuses),
            payment_method=random.choice([PaymentMethod.COD, PaymentMethod.BANK_TRANSFER]),
            payment_status=PaymentStatus.PAID if random.random() > 0.3 else PaymentStatus.PENDING,
            shipping_address=f"{address.street_address}, {address.ward}, {address.district}, {address.city}",
            shipping_phone=address.phone_number,
            subtotal=total_amount,
            shipping_fee=Decimal("30000"),
            total_amount=total_amount + Decimal("30000"),
            created_at=datetime.now() - timedelta(days=random.randint(1, 30))
        )
        session.add(order)
        await session.flush()
        
        # Create order items
        for product in order_products:
            quantity = random.randint(1, 3)
            order_item = OrderItem(
                order_id=order.id,
                product_id=product.id,
                quantity=quantity,
                price=product.price,
                subtotal=product.price * quantity
            )
            session.add(order_item)
        
        orders.append(order)
    
    await session.commit()
    print(f"✅ Seeded {len(orders)} orders")
    return orders


async def seed_reviews(session: AsyncSession, orders: list) -> None:
    """Seed reviews"""
    print("Seeding reviews...")
    
    count = 0
    for order in orders:
        # Only add reviews for delivered orders
        if order.status == OrderStatus.DELIVERED and random.random() > 0.5:
            # Get order items
            result = await session.execute(
                select(OrderItem).where(OrderItem.order_id == order.id)
            )
            order_items = result.scalars().all()
            
            for item in order_items:
                # Check if review exists
                result = await session.execute(
                    select(Review).where(
                        Review.user_id == order.user_id,
                        Review.product_id == item.product_id
                    )
                )
                existing = result.scalar_one_or_none()
                
                if not existing:
                    review = Review(
                        user_id=order.user_id,
                        product_id=item.product_id,
                        order_id=order.id,
                        rating=random.randint(3, 5),
                        comment=random.choice([
                            "Great product! Highly recommend.",
                            "Good quality for the price.",
                            "Fast shipping and excellent service.",
                            "Exactly as described. Very satisfied.",
                            "Will buy again!"
                        ])
                    )
                    session.add(review)
                    count += 1
    
    await session.commit()
    print(f"✅ Seeded {count} reviews")


async def seed_vouchers(session: AsyncSession, shops: list) -> None:
    """Seed vouchers"""
    print("Seeding vouchers...")
    
    voucher_codes = ["SUMMER2024", "WELCOME10", "FREESHIP", "BIGSALE20", "NEWUSER15"]
    count = 0
    
    for i, code in enumerate(voucher_codes):
        # Check if voucher exists
        result = await session.execute(
            select(Voucher).where(Voucher.code == code)
        )
        existing = result.scalar_one_or_none()
        
        if not existing:
            voucher = Voucher(
                code=code,
                description=f"Special discount voucher - {code}",
                voucher_type=random.choice([VoucherType.PLATFORM, VoucherType.SHOP]),
                shop_id=random.choice(shops).id if i % 2 == 0 else None,
                discount_type=random.choice([DiscountType.PERCENTAGE, DiscountType.FIXED_AMOUNT]),
                discount_value=Decimal(random.choice(["10", "15", "20", "50000", "100000"])),
                min_order_value=Decimal("100000"),
                max_discount=Decimal("500000"),
                usage_limit=100,
                times_used=random.randint(0, 20),
                start_date=datetime.now(),
                end_date=datetime.now() + timedelta(days=30),
                is_active=True
            )
            session.add(voucher)
            count += 1
    
    await session.commit()
    print(f"✅ Seeded {count} vouchers")


async def seed_notifications(session: AsyncSession, users: dict) -> None:
    """Seed notifications"""
    print("Seeding notifications...")
    
    count = 0
    for user in users.values():
        # Create a few sample notifications
        for i in range(random.randint(2, 5)):
            notification = Notification(
                user_id=user.id,
                type=random.choice([
                    NotificationType.ORDER_UPDATE,
                    NotificationType.MESSAGE,
                    NotificationType.PROMOTION,
                    NotificationType.SYSTEM
                ]),
                title=random.choice([
                    "Order Update",
                    "New Message",
                    "Special Offer",
                    "System Notification"
                ]),
                message=random.choice([
                    "Your order has been shipped",
                    "You have a new message",
                    "Check out our latest deals",
                    "System maintenance scheduled"
                ]),
                is_read=random.choice([True, False]),
                created_at=datetime.now() - timedelta(days=random.randint(0, 7))
            )
            session.add(notification)
            count += 1
    
    await session.commit()
    print(f"✅ Seeded {count} notifications")


async def main():
    """Main function to seed all data"""
    print("=" * 60)
    print("Database Seeding Script")
    print("=" * 60)
    print()
    
    # Initialize database
    print("Initializing database connection...")
    await init_db()
    print("✅ Database connected")
    print()
    
    async with AsyncSessionLocal() as session:
        # Seed data in order
        users = await seed_users(session)
        shops = await seed_shops(session, users)
        categories = await seed_categories(session)
        products = await seed_products(session, shops, categories)
        await seed_addresses(session, users)
        orders = await seed_orders(session, users, products)
        await seed_reviews(session, orders)
        await seed_vouchers(session, shops)
        await seed_notifications(session, users)
    
    print()
    print("=" * 60)
    print("✅ Database seeding completed successfully!")
    print("=" * 60)
    print()
    print("Test credentials:")
    print("- Customer: user1@example.com / password123")
    print("- Seller: user3@example.com / password123")
    print("- Admin: admin@example.com / password123")
    print()


if __name__ == "__main__":
    asyncio.run(main())
