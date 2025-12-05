"""
OTP (One-Time Password) utility for phone verification
"""
import random
import time
from typing import Dict, Optional

# In-memory OTP storage (use Redis in production)
# Structure: {phone_number: {"otp": "123456", "expires_at": timestamp}}
_otp_store: Dict[str, Dict[str, any]] = {}

# OTP expiration time in seconds (5 minutes)
OTP_EXPIRATION_SECONDS = 300


def generate_otp() -> str:
    """
    Generate a 6-digit OTP code
    
    Returns:
        6-digit OTP string
    """
    return str(random.randint(100000, 999999))


def store_otp(phone_number: str, otp: str) -> None:
    """
    Store OTP for a phone number with expiration
    
    Args:
        phone_number: User's phone number
        otp: OTP code to store
    """
    expires_at = time.time() + OTP_EXPIRATION_SECONDS
    _otp_store[phone_number] = {
        "otp": otp,
        "expires_at": expires_at
    }


def verify_otp(phone_number: str, otp: str) -> bool:
    """
    Verify OTP for a phone number
    
    Args:
        phone_number: User's phone number
        otp: OTP code to verify
        
    Returns:
        True if OTP is valid and not expired, False otherwise
    """
    stored = _otp_store.get(phone_number)
    
    if not stored:
        return False
    
    # Check if expired
    if time.time() > stored["expires_at"]:
        # Clean up expired OTP
        del _otp_store[phone_number]
        return False
    
    # Verify OTP matches
    is_valid = stored["otp"] == otp
    
    # If valid, remove from store (one-time use)
    if is_valid:
        del _otp_store[phone_number]
    
    return is_valid


def get_otp(phone_number: str) -> Optional[str]:
    """
    Get stored OTP for a phone number (for testing/debugging only)
    
    Args:
        phone_number: User's phone number
        
    Returns:
        OTP code if exists and not expired, None otherwise
    """
    stored = _otp_store.get(phone_number)
    
    if not stored:
        return None
    
    # Check if expired
    if time.time() > stored["expires_at"]:
        del _otp_store[phone_number]
        return None
    
    return stored["otp"]


def clear_otp(phone_number: str) -> None:
    """
    Clear OTP for a phone number
    
    Args:
        phone_number: User's phone number
    """
    if phone_number in _otp_store:
        del _otp_store[phone_number]


def cleanup_expired_otps() -> int:
    """
    Clean up all expired OTPs
    Should be called periodically (e.g., via background task)
    
    Returns:
        Number of OTPs cleaned up
    """
    current_time = time.time()
    expired_phones = [
        phone for phone, data in _otp_store.items()
        if current_time > data["expires_at"]
    ]
    
    for phone in expired_phones:
        del _otp_store[phone]
    
    return len(expired_phones)


def send_otp_sms(phone_number: str, otp: str) -> bool:
    """
    Send OTP via SMS (placeholder implementation)
    
    In production, integrate with SMS gateway like:
    - Twilio
    - AWS SNS
    - Vonage (Nexmo)
    - etc.
    
    Args:
        phone_number: User's phone number
        otp: OTP code to send
        
    Returns:
        True if sent successfully, False otherwise
    """
    # TODO: Implement actual SMS sending
    print(f"[SMS] Sending OTP {otp} to {phone_number}")
    print(f"[SMS] Message: Your verification code is: {otp}. Valid for 5 minutes.")
    
    # Simulate successful send
    return True
