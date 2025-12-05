"""
Unit tests for Auth service
"""
import pytest
import pytest_asyncio
from unittest.mock import Mock, AsyncMock, patch
from uuid import uuid4

from app.services.auth import AuthService
from app.repositories.user import UserRepository
from app.models.user import User, UserRole
from app.schemas.auth import RegisterRequest, LoginRequest, OTPVerifyRequest, PasswordResetRequest
from fastapi import HTTPException


@pytest.fixture
def mock_user_repo():
    """Mock user repository"""
    return Mock(spec=UserRepository)


@pytest.fixture
def auth_service(mock_user_repo):
    """Create auth service with mocked repository"""
    return AuthService(mock_user_repo)


@pytest.fixture
def sample_user():
    """Create a sample user for testing"""
    return User(
        id=uuid4(),
        phone_number="+84912345678",
        email="test@example.com",
        password_hash="$2b$12$mocked_hash",
        full_name="Test User",
        role=UserRole.BUYER,
        is_verified=False,
        is_suspended=False,
    )


class TestUserRegistration:
    """Tests for user registration"""
    
    @pytest.mark.asyncio
    async def test_register_user_success(self, auth_service, mock_user_repo):
        """Test successful user registration"""
        mock_user_repo.phone_exists = AsyncMock(return_value=False)
        mock_user_repo.email_exists = AsyncMock(return_value=False)
        mock_user_repo.create = AsyncMock(return_value=User(
            id=uuid4(),
            phone_number="+84912345678",
            email="test@example.com",
            password_hash="hashed",
            full_name="Test User",
            role=UserRole.BUYER,
            is_verified=False,
            is_suspended=False,
        ))
        
        with patch('app.services.auth.generate_otp', return_value="123456"):
            with patch('app.services.auth.send_otp_sms', new_callable=AsyncMock):
                result = await auth_service.register_user(
                    phone_number="+84912345678",
                    password="Test@1234",
                    full_name="Test User",
                    email="test@example.com"
                )
        
        assert result.phone_number == "+84912345678"
        assert result.full_name == "Test User"
        assert result.email == "test@example.com"
        mock_user_repo.create.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_register_user_duplicate_phone(self, auth_service, mock_user_repo):
        """Test registration with duplicate phone number"""
        mock_user_repo.phone_exists = AsyncMock(return_value=True)
        
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.register_user(
                phone_number="+84912345678",
                password="Test@1234",
                full_name="Test User"
            )
        
        assert exc_info.value.status_code == 400
        assert "already registered" in str(exc_info.value.detail).lower()
    
    @pytest.mark.asyncio
    async def test_register_user_duplicate_email(self, auth_service, mock_user_repo):
        """Test registration with duplicate email"""
        mock_user_repo.phone_exists = AsyncMock(return_value=False)
        mock_user_repo.email_exists = AsyncMock(return_value=True)
        
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.register_user(
                phone_number="+84912345678",
                password="Test@1234",
                full_name="Test User",
                email="existing@example.com"
            )
        
        assert exc_info.value.status_code == 400
        assert "already registered" in str(exc_info.value.detail).lower()
    
    @pytest.mark.asyncio
    async def test_register_user_invalid_phone_format(self, auth_service, mock_user_repo):
        """Test registration with invalid phone format"""
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.register_user(
                phone_number="123456",  # Invalid format
                password="Test@1234",
                full_name="Test User"
            )
        
        assert exc_info.value.status_code == 400
        assert "phone number" in str(exc_info.value.detail).lower()
    
    @pytest.mark.asyncio
    async def test_register_user_otp_generated(self, auth_service, mock_user_repo):
        """Test that OTP is generated and stored during registration"""
        mock_user_repo.phone_exists = AsyncMock(return_value=False)
        mock_user_repo.create = AsyncMock(return_value=User(
            id=uuid4(),
            phone_number="+84912345678",
            password_hash="hashed",
            full_name="Test User",
            role=UserRole.BUYER,
            is_verified=False,
            is_suspended=False,
        ))
        
        with patch('app.services.auth.generate_otp', return_value="123456") as mock_gen:
            with patch('app.services.auth.store_otp') as mock_store:
                with patch('app.services.auth.send_otp_sms', new_callable=AsyncMock):
                    await auth_service.register_user(
                        phone_number="+84912345678",
                        password="Test@1234",
                        full_name="Test User"
                    )
        
        mock_gen.assert_called_once()
        mock_store.assert_called_once_with("+84912345678", "123456")


class TestOTPVerification:
    """Tests for OTP verification"""
    
    @pytest.mark.asyncio
    async def test_verify_otp_success(self, auth_service, mock_user_repo, sample_user):
        """Test successful OTP verification"""
        sample_user.is_verified = False
        mock_user_repo.get_by_phone = AsyncMock(return_value=sample_user)
        mock_user_repo.mark_as_verified = AsyncMock(return_value=None)
        
        with patch('app.services.auth.verify_otp', return_value=True):
            result = await auth_service.verify_otp(
                phone_number="+84912345678",
                otp="123456"
            )
        
        assert result.access_token is not None
        assert result.refresh_token is not None
        assert result.token_type == "bearer"
        mock_user_repo.mark_as_verified.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_verify_otp_invalid_otp(self, auth_service, mock_user_repo, sample_user):
        """Test OTP verification with invalid OTP"""
        mock_user_repo.get_by_phone = AsyncMock(return_value=sample_user)
        
        with patch('app.services.auth.verify_otp', return_value=False):
            with pytest.raises(HTTPException) as exc_info:
                await auth_service.verify_otp(
                    phone_number="+84912345678",
                    otp="000000"
                )
        
        assert exc_info.value.status_code == 400
        assert "invalid" in str(exc_info.value.detail).lower()
    
    @pytest.mark.asyncio
    async def test_verify_otp_user_not_found(self, auth_service, mock_user_repo):
        """Test OTP verification for non-existent user"""
        mock_user_repo.get_by_phone = AsyncMock(return_value=None)
        
        with patch('app.services.auth.verify_otp', return_value=True):
            with pytest.raises(HTTPException) as exc_info:
                await auth_service.verify_otp(
                    phone_number="+84999999999",
                    otp="123456"
                )
        
        assert exc_info.value.status_code == 404
    
    @pytest.mark.asyncio
    async def test_verify_otp_already_verified(self, auth_service, mock_user_repo, sample_user):
        """Test OTP verification for already verified user"""
        sample_user.is_verified = True
        mock_user_repo.get_by_phone = AsyncMock(return_value=sample_user)
        
        with patch('app.services.auth.verify_otp', return_value=True):
            result = await auth_service.verify_otp(
                phone_number="+84912345678",
                otp="123456"
            )
        
        # Should still return tokens
        assert result.access_token is not None
        assert result.refresh_token is not None


class TestUserLogin:
    """Tests for user login"""
    
    @pytest.mark.asyncio
    async def test_login_success(self, auth_service, mock_user_repo, sample_user):
        """Test successful login"""
        sample_user.is_verified = True
        mock_user_repo.get_by_phone = AsyncMock(return_value=sample_user)
        
        with patch('app.services.auth.verify_password', return_value=True):
            result = await auth_service.login(
                phone_number="+84912345678",
                password="Test@1234"
            )
        
        assert result.access_token is not None
        assert result.refresh_token is not None
        assert result.token_type == "bearer"
    
    @pytest.mark.asyncio
    async def test_login_wrong_password(self, auth_service, mock_user_repo, sample_user):
        """Test login with wrong password"""
        sample_user.is_verified = True
        mock_user_repo.get_by_phone = AsyncMock(return_value=sample_user)
        
        with patch('app.services.auth.verify_password', return_value=False):
            with pytest.raises(HTTPException) as exc_info:
                await auth_service.login(
                    phone_number="+84912345678",
                    password="WrongPassword"
                )
        
        assert exc_info.value.status_code == 401
        assert "invalid" in str(exc_info.value.detail).lower()
    
    @pytest.mark.asyncio
    async def test_login_user_not_found(self, auth_service, mock_user_repo):
        """Test login with non-existent user"""
        mock_user_repo.get_by_phone = AsyncMock(return_value=None)
        
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.login(
                phone_number="+84999999999",
                password="Test@1234"
            )
        
        assert exc_info.value.status_code == 401
    
    @pytest.mark.asyncio
    async def test_login_unverified_user(self, auth_service, mock_user_repo, sample_user):
        """Test login with unverified user"""
        sample_user.is_verified = False
        mock_user_repo.get_by_phone = AsyncMock(return_value=sample_user)
        
        with patch('app.services.auth.verify_password', return_value=True):
            with pytest.raises(HTTPException) as exc_info:
                await auth_service.login(
                    phone_number="+84912345678",
                    password="Test@1234"
                )
        
        assert exc_info.value.status_code == 403
        assert "not verified" in str(exc_info.value.detail).lower()
    
    @pytest.mark.asyncio
    async def test_login_suspended_user(self, auth_service, mock_user_repo, sample_user):
        """Test login with suspended user"""
        sample_user.is_verified = True
        sample_user.is_suspended = True
        mock_user_repo.get_by_phone = AsyncMock(return_value=sample_user)
        
        with patch('app.services.auth.verify_password', return_value=True):
            with pytest.raises(HTTPException) as exc_info:
                await auth_service.login(
                    phone_number="+84912345678",
                    password="Test@1234"
                )
        
        assert exc_info.value.status_code == 403
        assert "suspended" in str(exc_info.value.detail).lower()


class TestTokenRefresh:
    """Tests for token refresh"""
    
    @pytest.mark.asyncio
    async def test_refresh_token_success(self, auth_service, mock_user_repo, sample_user):
        """Test successful token refresh"""
        sample_user.is_verified = True
        mock_user_repo.get_by_id = AsyncMock(return_value=sample_user)
        
        with patch('app.services.auth.decode_token') as mock_decode:
            with patch('app.services.auth.verify_token_type'):
                mock_decode.return_value = {
                    "sub": str(sample_user.id),
                    "type": "refresh"
                }
                
                result = await auth_service.refresh_token("valid_refresh_token")
        
        assert result.access_token is not None
        assert result.refresh_token is not None
    
    @pytest.mark.asyncio
    async def test_refresh_token_invalid_token(self, auth_service, mock_user_repo):
        """Test refresh with invalid token"""
        from jose import JWTError
        
        with patch('app.services.auth.decode_token', side_effect=JWTError("Invalid token")):
            with pytest.raises(HTTPException) as exc_info:
                await auth_service.refresh_token("invalid_token")
        
        assert exc_info.value.status_code == 401
    
    @pytest.mark.asyncio
    async def test_refresh_token_user_not_found(self, auth_service, mock_user_repo):
        """Test refresh when user no longer exists"""
        mock_user_repo.get_by_id = AsyncMock(return_value=None)
        
        with patch('app.services.auth.decode_token') as mock_decode:
            with patch('app.services.auth.verify_token_type'):
                mock_decode.return_value = {
                    "sub": str(uuid4()),
                    "type": "refresh"
                }
                
                with pytest.raises(HTTPException) as exc_info:
                    await auth_service.refresh_token("valid_refresh_token")
        
        assert exc_info.value.status_code == 401


class TestPasswordReset:
    """Tests for password reset flow"""
    
    @pytest.mark.asyncio
    async def test_forgot_password_success(self, auth_service, mock_user_repo, sample_user):
        """Test successful forgot password request"""
        mock_user_repo.get_by_phone = AsyncMock(return_value=sample_user)
        
        with patch('app.services.auth.generate_otp', return_value="123456"):
            with patch('app.services.auth.store_otp') as mock_store:
                with patch('app.services.auth.send_otp_sms', new_callable=AsyncMock):
                    await auth_service.forgot_password(phone_number="+84912345678")
        
        mock_store.assert_called_once_with("+84912345678", "123456")
    
    @pytest.mark.asyncio
    async def test_forgot_password_user_not_found(self, auth_service, mock_user_repo):
        """Test forgot password for non-existent user"""
        mock_user_repo.get_by_phone = AsyncMock(return_value=None)
        
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.forgot_password(phone_number="+84999999999")
        
        assert exc_info.value.status_code == 404
    
    @pytest.mark.asyncio
    async def test_reset_password_success(self, auth_service, mock_user_repo, sample_user):
        """Test successful password reset"""
        mock_user_repo.get_by_phone = AsyncMock(return_value=sample_user)
        mock_user_repo.update = AsyncMock(return_value=sample_user)
        
        with patch('app.services.auth.verify_otp', return_value=True):
            with patch('app.services.auth.hash_password', return_value="new_hashed_password"):
                await auth_service.reset_password(
                    phone_number="+84912345678",
                    otp="123456",
                    new_password="NewPassword@1234"
                )
        
        mock_user_repo.update.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_reset_password_invalid_otp(self, auth_service, mock_user_repo, sample_user):
        """Test password reset with invalid OTP"""
        mock_user_repo.get_by_phone = AsyncMock(return_value=sample_user)
        
        with patch('app.services.auth.verify_otp', return_value=False):
            with pytest.raises(HTTPException) as exc_info:
                await auth_service.reset_password(
                    phone_number="+84912345678",
                    otp="000000",
                    new_password="NewPassword@1234"
                )
        
        assert exc_info.value.status_code == 400


class TestResendOTP:
    """Tests for OTP resend"""
    
    @pytest.mark.asyncio
    async def test_resend_otp_success(self, auth_service, mock_user_repo, sample_user):
        """Test successful OTP resend"""
        sample_user.is_verified = False
        mock_user_repo.get_by_phone = AsyncMock(return_value=sample_user)
        
        with patch('app.services.auth.generate_otp', return_value="654321"):
            with patch('app.services.auth.store_otp') as mock_store:
                with patch('app.services.auth.send_otp_sms', new_callable=AsyncMock):
                    await auth_service.resend_otp(phone_number="+84912345678")
        
        mock_store.assert_called_once_with("+84912345678", "654321")
    
    @pytest.mark.asyncio
    async def test_resend_otp_already_verified(self, auth_service, mock_user_repo, sample_user):
        """Test OTP resend for already verified user"""
        sample_user.is_verified = True
        mock_user_repo.get_by_phone = AsyncMock(return_value=sample_user)
        
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.resend_otp(phone_number="+84912345678")
        
        assert exc_info.value.status_code == 400
        assert "already verified" in str(exc_info.value.detail).lower()
    
    @pytest.mark.asyncio
    async def test_resend_otp_user_not_found(self, auth_service, mock_user_repo):
        """Test OTP resend for non-existent user"""
        mock_user_repo.get_by_phone = AsyncMock(return_value=None)
        
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.resend_otp(phone_number="+84999999999")
        
        assert exc_info.value.status_code == 404
