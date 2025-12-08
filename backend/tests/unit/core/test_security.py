"""
Unit tests for security utilities (password hashing, JWT tokens)
"""
import pytest
from datetime import datetime, timedelta
from jose import jwt, JWTError

from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    verify_token_type,
    get_user_id_from_token,
    get_user_role_from_token,
)
from app.config import settings


class TestPasswordHashing:
    """Tests for password hashing and verification"""
    
    def test_hash_password_returns_different_hash(self):
        """Test that hashing the same password twice returns different hashes"""
        password = "Test@1234"
        hash1 = hash_password(password)
        hash2 = hash_password(password)
        
        assert hash1 != hash2
        assert hash1 != password
        assert hash2 != password
    
    def test_hash_password_length(self):
        """Test that hashed password has expected length"""
        password = "Test@1234"
        hashed = hash_password(password)
        
        # Bcrypt hashes are 60 characters long
        assert len(hashed) == 60
        assert hashed.startswith("$2b$")
    
    def test_verify_password_correct(self):
        """Test password verification with correct password"""
        password = "Test@1234"
        hashed = hash_password(password)
        
        assert verify_password(password, hashed) is True
    
    def test_verify_password_incorrect(self):
        """Test password verification with incorrect password"""
        password = "Test@1234"
        wrong_password = "Wrong@1234"
        hashed = hash_password(password)
        
        assert verify_password(wrong_password, hashed) is False
    
    def test_verify_password_empty(self):
        """Test password verification with empty password"""
        password = "Test@1234"
        hashed = hash_password(password)
        
        assert verify_password("", hashed) is False
    
    def test_hash_password_with_special_characters(self):
        """Test hashing password with special characters"""
        password = "P@ssw0rd!#$%^&*()"
        hashed = hash_password(password)
        
        assert verify_password(password, hashed) is True
    
    def test_hash_password_unicode(self):
        """Test hashing password with unicode characters"""
        password = "Mật_Khẩu_123@"
        hashed = hash_password(password)
        
        assert verify_password(password, hashed) is True


class TestJWTTokens:
    """Tests for JWT token creation and decoding"""
    
    def test_create_access_token(self):
        """Test creating an access token"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        role = "BUYER"
        
        token = create_access_token(user_id, role)
        
        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 0
    
    def test_create_refresh_token(self):
        """Test creating a refresh token"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        
        token = create_refresh_token(user_id)
        
        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 0
    
    def test_decode_access_token(self):
        """Test decoding an access token"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        role = "SELLER"
        
        token = create_access_token(user_id, role)
        payload = decode_token(token)
        
        assert payload["sub"] == user_id
        assert payload["role"] == role
        assert payload["type"] == "access"
        assert "exp" in payload
    
    def test_decode_refresh_token(self):
        """Test decoding a refresh token"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        
        token = create_refresh_token(user_id)
        payload = decode_token(token)
        
        assert payload["sub"] == user_id
        assert payload["type"] == "refresh"
        assert "exp" in payload
    
    def test_decode_invalid_token(self):
        """Test decoding an invalid token raises error"""
        invalid_token = "invalid.token.here"
        
        with pytest.raises(JWTError):
            decode_token(invalid_token)
    
    def test_decode_expired_token(self):
        """Test decoding an expired token raises error"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        
        # Create token that expired 1 hour ago
        expire = datetime.utcnow() - timedelta(hours=1)
        payload = {
            "sub": user_id,
            "role": "BUYER",
            "type": "access",
            "exp": expire
        }
        expired_token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        
        with pytest.raises(JWTError):
            decode_token(expired_token)
    
    def test_verify_token_type_access(self):
        """Test verifying access token type"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        token = create_access_token(user_id, "BUYER")
        
        # Should not raise error
        verify_token_type(token, "access")
    
    def test_verify_token_type_refresh(self):
        """Test verifying refresh token type"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        token = create_refresh_token(user_id)
        
        # Should not raise error
        verify_token_type(token, "refresh")
    
    def test_verify_token_type_mismatch(self):
        """Test verifying wrong token type raises error"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        token = create_access_token(user_id, "BUYER")
        
        with pytest.raises(JWTError, match="Invalid token type"):
            verify_token_type(token, "refresh")
    
    def test_get_user_id_from_token(self):
        """Test extracting user ID from token"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        role = "ADMIN"
        
        token = create_access_token(user_id, role)
        extracted_id = get_user_id_from_token(token)
        
        assert extracted_id == user_id
    
    def test_get_user_role_from_token(self):
        """Test extracting user role from token"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        role = "SELLER"
        
        token = create_access_token(user_id, role)
        extracted_role = get_user_role_from_token(token)
        
        assert extracted_role == role
    
    def test_access_token_expiration_time(self):
        """Test that access token has correct expiration time"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        
        token = create_access_token(user_id, "BUYER")
        payload = decode_token(token)
        
        # Token should have exp and iat claims
        assert "exp" in payload
        assert "iat" in payload
        
        # Expiration should be ACCESS_TOKEN_EXPIRE_MINUTES from now
        exp_delta = payload["exp"] - payload["iat"]
        expected_delta = settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
        
        # Allow 2 seconds tolerance
        assert abs(exp_delta - expected_delta) < 2
    
    def test_refresh_token_expiration_time(self):
        """Test that refresh token has correct expiration time"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        
        token = create_refresh_token(user_id)
        payload = decode_token(token)
        
        # Token should have exp and iat claims
        assert "exp" in payload
        assert "iat" in payload
        
        # Expiration should be REFRESH_TOKEN_EXPIRE_DAYS from now
        exp_delta = payload["exp"] - payload["iat"]
        expected_delta = settings.REFRESH_TOKEN_EXPIRE_DAYS * 24 * 60 * 60
        
        # Allow 2 seconds tolerance
        assert abs(exp_delta - expected_delta) < 2
    
    def test_token_with_different_roles(self):
        """Test creating tokens with different user roles"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        roles = ["BUYER", "SELLER", "ADMIN"]
        
        for role in roles:
            token = create_access_token(user_id, role)
            payload = decode_token(token)
            assert payload["role"] == role


class TestTokenSecurity:
    """Tests for token security features"""
    
    def test_token_cannot_be_tampered(self):
        """Test that tampering with token makes it invalid"""
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        token = create_access_token(user_id, "BUYER")
        
        # Tamper with token by changing a character
        tampered_token = token[:-1] + ("a" if token[-1] != "a" else "b")
        
        with pytest.raises(JWTError):
            decode_token(tampered_token)
    
    def test_tokens_are_unique(self):
        """Test that creating multiple tokens produces unique values"""
        import time
        user_id = "123e4567-e89b-12d3-a456-426614174000"
        
        token1 = create_access_token(user_id, "BUYER")
        time.sleep(1.1)  # Delay to ensure different timestamp (iat is in seconds)
        token2 = create_access_token(user_id, "BUYER")
        
        # Tokens should be different due to timestamp
        assert token1 != token2
    
    def test_token_without_required_fields(self):
        """Test that token without required fields is invalid"""
        # Create token without 'sub' field
        payload = {
            "role": "BUYER",
            "type": "access",
            "exp": datetime.utcnow() + timedelta(minutes=15)
        }
        invalid_token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
        
        # Should decode but missing 'sub'
        decoded = decode_token(invalid_token)
        assert "sub" not in decoded or decoded.get("sub") is None
