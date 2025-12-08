"""
Validation utilities for the application.
"""
import re
from decimal import Decimal
from typing import Optional

from app.core.exceptions import ValidationError


def validate_vietnamese_phone(phone: str) -> bool:
    """
    Validate Vietnamese phone number format.
    
    Accepts formats:
    - +84XXXXXXXXX (10-11 digits after +84)
    - 0XXXXXXXXX (10-11 digits starting with 0)
    
    Args:
        phone: Phone number string
        
    Returns:
        True if valid
        
    Raises:
        ValidationError: If phone number is invalid
    """
    if not phone:
        raise ValidationError("Phone number is required")
    
    # Remove all whitespace and dashes
    phone = re.sub(r'[\s\-]', '', phone)
    
    # Pattern 1: +84 followed by 9-10 digits
    if phone.startswith('+84'):
        digits = phone[3:]
        if len(digits) >= 9 and len(digits) <= 10 and digits.isdigit():
            return True
    
    # Pattern 2: 0 followed by 9-10 digits
    elif phone.startswith('0'):
        if len(phone) >= 10 and len(phone) <= 11 and phone.isdigit():
            return True
    
    raise ValidationError("Invalid Vietnamese phone number format")


def normalize_vietnamese_phone(phone: str) -> str:
    """
    Normalize Vietnamese phone number to +84XXXXXXXXX format.
    
    Args:
        phone: Phone number string
        
    Returns:
        Normalized phone number
        
    Raises:
        ValidationError: If phone number is invalid
    """
    validate_vietnamese_phone(phone)
    
    # Remove all whitespace and dashes
    phone = re.sub(r'[\s\-]', '', phone)
    
    # Already in +84 format
    if phone.startswith('+84'):
        return phone
    
    # Convert from 0XXX to +84XXX
    if phone.startswith('0'):
        return '+84' + phone[1:]
    
    raise ValidationError("Invalid Vietnamese phone number format")


def validate_price(price: Decimal, min_value: Decimal = Decimal('0.01')) -> bool:
    """
    Validate price value.
    
    Args:
        price: Price value
        min_value: Minimum allowed price (default: 0.01)
        
    Returns:
        True if valid
        
    Raises:
        ValidationError: If price is invalid
    """
    try:
        # Check if price is a valid decimal
        if not isinstance(price, (Decimal, int, float)):
            raise ValidationError("Price must be a number")
        
        price_decimal = Decimal(str(price))
        
        # Check if price is greater than or equal to min_value
        if price_decimal < min_value:
            raise ValidationError(f"Price must be at least {min_value}")
        
        # Check if price has at most 2 decimal places
        if price_decimal.as_tuple().exponent < -2:
            raise ValidationError("Price cannot have more than 2 decimal places")
        
        return True
    except ValidationError:
        raise
    except (ValueError, TypeError, ArithmeticError) as e:
        raise ValidationError(f"Invalid price value: {e}")


def validate_email(email: str) -> bool:
    """
    Validate email format.
    
    Args:
        email: Email address string
        
    Returns:
        True if valid
        
    Raises:
        ValidationError: If email is invalid
    """
    if not email:
        raise ValidationError("Email is required")
    
    # Basic email regex pattern
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    
    if not re.match(pattern, email):
        raise ValidationError("Invalid email format")
    
    return True


def validate_image_file(filename: str, allowed_extensions: Optional[set] = None) -> bool:
    """
    Validate image file by extension.
    
    Args:
        filename: Name of the file
        allowed_extensions: Set of allowed extensions (default: jpg, jpeg, png, gif, webp)
        
    Returns:
        True if valid image file
        
    Raises:
        ValidationError: If file is invalid
    """
    if not filename:
        raise ValidationError("Filename is required")
    
    if allowed_extensions is None:
        allowed_extensions = {'jpg', 'jpeg', 'png', 'gif', 'webp'}
    
    # Get file extension
    if '.' not in filename:
        raise ValidationError("File has no extension")
    
    extension = filename.rsplit('.', 1)[1].lower()
    
    if extension not in allowed_extensions:
        raise ValidationError(
            f"Invalid image file extension: {extension}. "
            f"Allowed: {', '.join(allowed_extensions)}"
        )
    
    return True


def validate_image_size(file_size_bytes: int, max_size_mb: int = 5) -> bool:
    """
    Validate image file size.
    
    Args:
        file_size_bytes: File size in bytes
        max_size_mb: Maximum allowed size in MB (default: 5MB)
        
    Returns:
        True if valid
        
    Raises:
        ValidationError: If file size is invalid
    """
    max_size_bytes = max_size_mb * 1024 * 1024
    
    if file_size_bytes <= 0:
        raise ValidationError("File size must be greater than 0")
    
    if file_size_bytes > max_size_bytes:
        raise ValidationError(
            f"File size exceeds maximum of {max_size_mb}MB"
        )
    
    return True


def validate_url(url: str) -> bool:
    """
    Validate URL format.
    
    Args:
        url: URL string
        
    Returns:
        True if valid
        
    Raises:
        ValidationError: If URL is invalid
    """
    if not url:
        raise ValidationError("URL is required")
    
    # Basic URL regex pattern
    pattern = r'^https?://[^\s/$.?#].[^\s]*$'
    
    if not re.match(pattern, url, re.IGNORECASE):
        raise ValidationError("Invalid URL format. Must start with http:// or https://")
    
    return True


def validate_password_strength(password: str) -> bool:
    """
    Validate password strength.
    
    Requirements:
    - At least 8 characters
    - At least one uppercase letter
    - At least one lowercase letter
    - At least one digit
    - At least one special character
    
    Args:
        password: Password string
        
    Returns:
        True if valid
        
    Raises:
        ValidationError: If password is weak
    """
    if not password:
        raise ValidationError("Password is required")
    
    if len(password) < 8:
        raise ValidationError("Password must be at least 8 characters long")
    
    if not re.search(r'[A-Z]', password):
        raise ValidationError("Password must contain at least one uppercase letter")
    
    if not re.search(r'[a-z]', password):
        raise ValidationError("Password must contain at least one lowercase letter")
    
    if not re.search(r'\d', password):
        raise ValidationError("Password must contain at least one digit")
    
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        raise ValidationError("Password must contain at least one special character")
    
    return True


def validate_order_code(order_code: str) -> bool:
    """
    Validate order code format.
    
    Expected format: ORD-YYYYMMDD-XXXXX
    
    Args:
        order_code: Order code string
        
    Returns:
        True if valid
        
    Raises:
        ValidationError: If order code is invalid
    """
    if not order_code:
        raise ValidationError("Order code is required")
    
    pattern = r'^ORD-\d{8}-\d{5}$'
    
    if not re.match(pattern, order_code):
        raise ValidationError("Invalid order code format. Expected: ORD-YYYYMMDD-XXXXX")
    
    return True


def validate_voucher_code(voucher_code: str) -> bool:
    """
    Validate voucher code format.
    
    Requirements:
    - 4-20 characters
    - Alphanumeric and hyphens only
    - Uppercase letters
    
    Args:
        voucher_code: Voucher code string
        
    Returns:
        True if valid
        
    Raises:
        ValidationError: If voucher code is invalid
    """
    if not voucher_code:
        raise ValidationError("Voucher code is required")
    
    if len(voucher_code) < 4 or len(voucher_code) > 20:
        raise ValidationError("Voucher code must be between 4 and 20 characters")
    
    pattern = r'^[A-Z0-9\-]+$'
    
    if not re.match(pattern, voucher_code):
        raise ValidationError(
            "Voucher code must contain only uppercase letters, numbers, and hyphens"
        )
    
    return True


def sanitize_string(text: str, max_length: Optional[int] = None) -> str:
    """
    Sanitize string by removing extra whitespace and trimming.
    
    Args:
        text: Input string
        max_length: Maximum length to trim to
        
    Returns:
        Sanitized string
    """
    if not text:
        return ""
    
    # Remove leading/trailing whitespace
    text = text.strip()
    
    # Replace multiple whitespaces with single space
    text = re.sub(r'\s+', ' ', text)
    
    # Trim to max length if specified
    if max_length and len(text) > max_length:
        text = text[:max_length]
    
    return text
