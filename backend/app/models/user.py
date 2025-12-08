"""
User model
"""
import enum

from sqlalchemy import Boolean, Column, Enum, String, Index
from sqlalchemy.orm import relationship

from app.models.base import BaseModel


class UserRole(str, enum.Enum):
    """User role enumeration"""
    BUYER = "BUYER"
    SELLER = "SELLER"
    ADMIN = "ADMIN"


class User(BaseModel):
    """
    User model representing registered users
    
    A user can be a buyer, seller, or admin.
    Phone number is required for registration and used for OTP verification.
    """
    __tablename__ = "users"
    
    # Authentication
    phone_number = Column(
        String(20),
        unique=True,
        nullable=False,
        index=True,
        comment="User's phone number (Vietnamese format)"
    )
    
    email = Column(
        String(255),
        unique=True,
        nullable=True,
        index=True,
        comment="User's email address (optional)"
    )
    
    password_hash = Column(
        String(255),
        nullable=False,
        comment="Bcrypt hashed password"
    )
    
    # Profile
    full_name = Column(
        String(255),
        nullable=False,
        comment="User's full name"
    )
    
    avatar_url = Column(
        String(500),
        nullable=True,
        comment="URL to user's avatar image"
    )
    
    # Role & Status
    role = Column(
        Enum(UserRole),
        default=UserRole.BUYER,
        nullable=False,
        index=True,
        comment="User role: BUYER, SELLER, or ADMIN"
    )
    
    is_verified = Column(
        Boolean,
        default=False,
        nullable=False,
        comment="Whether phone number is verified via OTP"
    )
    
    is_suspended = Column(
        Boolean,
        default=False,
        nullable=False,
        index=True,
        comment="Whether user account is suspended by admin"
    )
    
    # Relationships (will be defined as models are created)
    addresses = relationship("Address", back_populates="user", cascade="all, delete-orphan")
    shop = relationship("Shop", back_populates="owner", uselist=False, cascade="all, delete-orphan")
    cart_items = relationship("CartItem", back_populates="user", cascade="all, delete-orphan")
    orders = relationship("Order", foreign_keys="Order.buyer_id", back_populates="buyer")
    reviews = relationship("Review", back_populates="user", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    
    def __repr__(self):
        return f"<User(id={self.id}, phone={self.phone_number}, role={self.role})>"
    
    @property
    def is_seller(self) -> bool:
        """Check if user is a seller"""
        return self.role in [UserRole.SELLER, UserRole.ADMIN]
    
    @property
    def is_admin(self) -> bool:
        """Check if user is an admin"""
        return self.role == UserRole.ADMIN


# Create composite indexes
Index('idx_user_phone_verified', User.phone_number, User.is_verified)
Index('idx_user_role_suspended', User.role, User.is_suspended)
