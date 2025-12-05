"""
Security utilities for authentication and authorization
"""
from datetime import datetime, timedelta
from typing import Optional

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import settings

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# Password Hashing Functions
def hash_password(password: str) -> str:
    """
    Hash a plain password using bcrypt
    
    Args:
        password: Plain text password
        
    Returns:
        Hashed password string
    """
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify a plain password against a hashed password
    
    Args:
        plain_password: Plain text password to verify
        hashed_password: Hashed password from database
        
    Returns:
        True if password matches, False otherwise
    """
    return pwd_context.verify(plain_password, hashed_password)


# JWT Token Functions
def create_access_token(user_id: str, role: str, expires_delta: Optional[timedelta] = None) -> str:
    """
    Create a JWT access token
    
    Args:
        user_id: User's UUID as string
        role: User's role (BUYER, SELLER, ADMIN)
        expires_delta: Optional custom expiration time
        
    Returns:
        Encoded JWT token string
    """
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode = {
        "sub": user_id,
        "role": role,
        "type": "access",
        "exp": expire,
        "iat": datetime.utcnow()
    }
    
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def create_refresh_token(user_id: str) -> str:
    """
    Create a JWT refresh token
    
    Args:
        user_id: User's UUID as string
        
    Returns:
        Encoded JWT refresh token string
    """
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    
    to_encode = {
        "sub": user_id,
        "type": "refresh",
        "exp": expire,
        "iat": datetime.utcnow()
    }
    
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def decode_token(token: str) -> dict:
    """
    Decode and validate a JWT token
    
    Args:
        token: JWT token string
        
    Returns:
        Decoded token payload as dictionary
        
    Raises:
        JWTError: If token is invalid or expired
    """
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError as e:
        raise JWTError(f"Could not validate token: {str(e)}")


def verify_token_type(token: str, expected_type: str) -> dict:
    """
    Verify that a token is of the expected type (access or refresh)
    
    Args:
        token: JWT token string
        expected_type: Expected token type ('access' or 'refresh')
        
    Returns:
        Decoded token payload if type matches
        
    Raises:
        JWTError: If token type doesn't match or token is invalid
    """
    payload = decode_token(token)
    
    token_type = payload.get("type")
    if token_type != expected_type:
        raise JWTError(f"Invalid token type. Expected {expected_type}, got {token_type}")
    
    return payload


def get_user_id_from_token(token: str) -> str:
    """
    Extract user ID from access token
    
    Args:
        token: JWT access token string
        
    Returns:
        User ID from token
        
    Raises:
        JWTError: If token is invalid or missing user ID
    """
    payload = verify_token_type(token, "access")
    user_id = payload.get("sub")
    
    if user_id is None:
        raise JWTError("Token missing user ID")
    
    return user_id


def get_user_role_from_token(token: str) -> str:
    """
    Extract user role from access token
    
    Args:
        token: JWT access token string
        
    Returns:
        User role from token
        
    Raises:
        JWTError: If token is invalid or missing role
    """
    payload = verify_token_type(token, "access")
    role = payload.get("role")
    
    if role is None:
        raise JWTError("Token missing user role")
    
    return role
