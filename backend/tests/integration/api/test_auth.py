"""
Integration tests for Auth API endpoints
"""
import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from unittest.mock import patch

from app.models.user import User, UserRole
from app.repositories.user import UserRepository
from app.core.security import hash_password


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession):
    """Create a test user in the database"""
    user_repo = UserRepository(db_session)
    
    user = User(
        phone_number="+84912345678",
        email="test@example.com",
        password_hash=hash_password("Test@1234"),
        full_name="Test User",
        role=UserRole.BUYER,
        is_verified=True,
        is_suspended=False,
    )
    
    created_user = await user_repo.create(user)
    return created_user


class TestRegistrationFlow:
    """Integration tests for user registration"""
    
    @pytest.mark.asyncio
    async def test_register_new_user(self, client: AsyncClient):
        """Test registering a new user"""
        with patch('app.services.auth.send_otp_sms'):
            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "phone_number": "+84987654321",
                    "password": "Test@1234",
                    "full_name": "New User",
                    "email": "newuser@example.com"
                }
            )
        
        assert response.status_code == 201
        data = response.json()
        assert data["phone_number"] == "+84987654321"
        assert data["full_name"] == "New User"
        assert data["email"] == "newuser@example.com"
        assert "id" in data
        assert "password" not in data
        assert "password_hash" not in data
    
    @pytest.mark.asyncio
    async def test_register_duplicate_phone(self, client: AsyncClient, test_user: User):
        """Test registration with existing phone number"""
        with patch('app.services.auth.send_otp_sms'):
            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "phone_number": "+84912345678",  # Same as test_user
                    "password": "Test@1234",
                    "full_name": "Another User"
                }
            )
        
        assert response.status_code == 400
        assert "already registered" in response.json()["detail"].lower()
    
    @pytest.mark.asyncio
    async def test_register_invalid_phone_format(self, client: AsyncClient):
        """Test registration with invalid phone format"""
        with patch('app.services.auth.send_otp_sms'):
            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "phone_number": "123456",  # Invalid
                    "password": "Test@1234",
                    "full_name": "Test User"
                }
            )
        
        assert response.status_code == 400
    
    @pytest.mark.asyncio
    async def test_register_missing_required_fields(self, client: AsyncClient):
        """Test registration with missing required fields"""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "phone_number": "+84987654321"
                # Missing password and full_name
            }
        )
        
        assert response.status_code == 422  # Validation error
    
    @pytest.mark.asyncio
    async def test_register_without_email(self, client: AsyncClient):
        """Test registration without email (optional field)"""
        with patch('app.services.auth.send_otp_sms'):
            response = await client.post(
                "/api/v1/auth/register",
                json={
                    "phone_number": "+84987654321",
                    "password": "Test@1234",
                    "full_name": "Test User"
                    # email is optional
                }
            )
        
        assert response.status_code == 201
        data = response.json()
        assert data["email"] is None


class TestOTPVerificationFlow:
    """Integration tests for OTP verification"""
    
    @pytest.mark.asyncio
    async def test_verify_otp_success(self, client: AsyncClient, db_session: AsyncSession):
        """Test successful OTP verification"""
        # First register a user
        with patch('app.services.auth.send_otp_sms'):
            with patch('app.services.auth.generate_otp', return_value="123456"):
                await client.post(
                    "/api/v1/auth/register",
                    json={
                        "phone_number": "+84111111111",
                        "password": "Test@1234",
                        "full_name": "OTP Test User"
                    }
                )
        
        # Then verify OTP
        with patch('app.services.auth.verify_otp', return_value=True):
            response = await client.post(
                "/api/v1/auth/verify-otp",
                json={
                    "phone_number": "+84111111111",
                    "otp": "123456"
                }
            )
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "bearer"
    
    @pytest.mark.asyncio
    async def test_verify_otp_invalid_code(self, client: AsyncClient, test_user: User):
        """Test OTP verification with invalid code"""
        with patch('app.services.auth.verify_otp', return_value=False):
            response = await client.post(
                "/api/v1/auth/verify-otp",
                json={
                    "phone_number": "+84912345678",
                    "otp": "000000"
                }
            )
        
        assert response.status_code == 400
        assert "invalid" in response.json()["detail"].lower()
    
    @pytest.mark.asyncio
    async def test_verify_otp_nonexistent_user(self, client: AsyncClient):
        """Test OTP verification for non-existent user"""
        with patch('app.services.auth.verify_otp', return_value=True):
            response = await client.post(
                "/api/v1/auth/verify-otp",
                json={
                    "phone_number": "+84999999999",
                    "otp": "123456"
                }
            )
        
        assert response.status_code == 404


class TestLoginFlow:
    """Integration tests for user login"""
    
    @pytest.mark.asyncio
    async def test_login_success(self, client: AsyncClient, test_user: User):
        """Test successful login"""
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "phone_number": "+84912345678",
                "password": "Test@1234"
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "bearer"
    
    @pytest.mark.asyncio
    async def test_login_wrong_password(self, client: AsyncClient, test_user: User):
        """Test login with wrong password"""
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "phone_number": "+84912345678",
                "password": "WrongPassword@123"
            }
        )
        
        assert response.status_code == 401
        assert "invalid" in response.json()["detail"].lower()
    
    @pytest.mark.asyncio
    async def test_login_nonexistent_user(self, client: AsyncClient):
        """Test login with non-existent user"""
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "phone_number": "+84999999999",
                "password": "Test@1234"
            }
        )
        
        assert response.status_code == 401
    
    @pytest.mark.asyncio
    async def test_login_unverified_user(self, client: AsyncClient, db_session: AsyncSession):
        """Test login with unverified user"""
        # Create unverified user
        user_repo = UserRepository(db_session)
        unverified_user = User(
            phone_number="+84222222222",
            password_hash=hash_password("Test@1234"),
            full_name="Unverified User",
            role=UserRole.BUYER,
            is_verified=False,
            is_suspended=False,
        )
        await user_repo.create(unverified_user)
        
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "phone_number": "+84222222222",
                "password": "Test@1234"
            }
        )
        
        assert response.status_code == 403
        assert "not verified" in response.json()["detail"].lower()
    
    @pytest.mark.asyncio
    async def test_login_missing_credentials(self, client: AsyncClient):
        """Test login with missing credentials"""
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "phone_number": "+84912345678"
                # Missing password
            }
        )
        
        assert response.status_code == 422  # Validation error


class TestTokenRefreshFlow:
    """Integration tests for token refresh"""
    
    @pytest.mark.asyncio
    async def test_refresh_token_success(self, client: AsyncClient, test_user: User):
        """Test successful token refresh"""
        # First login to get tokens
        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "phone_number": "+84912345678",
                "password": "Test@1234"
            }
        )
        refresh_token = login_response.json()["refresh_token"]
        
        # Then refresh
        response = await client.post(
            "/api/v1/auth/refresh",
            json={
                "refresh_token": refresh_token
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
    
    @pytest.mark.asyncio
    async def test_refresh_token_invalid_token(self, client: AsyncClient):
        """Test refresh with invalid token"""
        response = await client.post(
            "/api/v1/auth/refresh",
            json={
                "refresh_token": "invalid.token.here"
            }
        )
        
        assert response.status_code == 401
    
    @pytest.mark.asyncio
    async def test_refresh_token_with_access_token(self, client: AsyncClient, test_user: User):
        """Test that access token cannot be used for refresh"""
        # First login to get tokens
        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "phone_number": "+84912345678",
                "password": "Test@1234"
            }
        )
        access_token = login_response.json()["access_token"]
        
        # Try to use access token for refresh (should fail)
        response = await client.post(
            "/api/v1/auth/refresh",
            json={
                "refresh_token": access_token
            }
        )
        
        assert response.status_code == 401


class TestPasswordResetFlow:
    """Integration tests for password reset"""
    
    @pytest.mark.asyncio
    async def test_forgot_password_success(self, client: AsyncClient, test_user: User):
        """Test successful forgot password request"""
        with patch('app.services.auth.send_otp_sms'):
            response = await client.post(
                "/api/v1/auth/forgot-password",
                json={
                    "phone_number": "+84912345678"
                }
            )
        
        assert response.status_code == 200
        assert "sent" in response.json()["message"].lower()
    
    @pytest.mark.asyncio
    async def test_forgot_password_nonexistent_user(self, client: AsyncClient):
        """Test forgot password for non-existent user"""
        with patch('app.services.auth.send_otp_sms'):
            response = await client.post(
                "/api/v1/auth/forgot-password",
                json={
                    "phone_number": "+84999999999"
                }
            )
        
        assert response.status_code == 404
    
    @pytest.mark.asyncio
    async def test_reset_password_success(self, client: AsyncClient, test_user: User):
        """Test successful password reset"""
        # First request OTP
        with patch('app.services.auth.send_otp_sms'):
            with patch('app.services.auth.generate_otp', return_value="123456"):
                await client.post(
                    "/api/v1/auth/forgot-password",
                    json={
                        "phone_number": "+84912345678"
                    }
                )
        
        # Then reset password
        with patch('app.services.auth.verify_otp', return_value=True):
            response = await client.post(
                "/api/v1/auth/reset-password",
                json={
                    "phone_number": "+84912345678",
                    "otp": "123456",
                    "new_password": "NewPassword@1234"
                }
            )
        
        assert response.status_code == 200
        assert "reset" in response.json()["message"].lower()
        
        # Verify can login with new password
        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "phone_number": "+84912345678",
                "password": "NewPassword@1234"
            }
        )
        assert login_response.status_code == 200
    
    @pytest.mark.asyncio
    async def test_reset_password_invalid_otp(self, client: AsyncClient, test_user: User):
        """Test password reset with invalid OTP"""
        with patch('app.services.auth.verify_otp', return_value=False):
            response = await client.post(
                "/api/v1/auth/reset-password",
                json={
                    "phone_number": "+84912345678",
                    "otp": "000000",
                    "new_password": "NewPassword@1234"
                }
            )
        
        assert response.status_code == 400


class TestResendOTPFlow:
    """Integration tests for OTP resend"""
    
    @pytest.mark.asyncio
    async def test_resend_otp_success(self, client: AsyncClient, db_session: AsyncSession):
        """Test successful OTP resend"""
        # Create unverified user
        user_repo = UserRepository(db_session)
        user = User(
            phone_number="+84333333333",
            password_hash=hash_password("Test@1234"),
            full_name="Test User",
            role=UserRole.BUYER,
            is_verified=False,
            is_suspended=False,
        )
        await user_repo.create(user)
        
        # Resend OTP
        with patch('app.services.auth.send_otp_sms'):
            response = await client.post(
                "/api/v1/auth/resend-otp",
                json={
                    "phone_number": "+84333333333"
                }
            )
        
        assert response.status_code == 200
        assert "sent" in response.json()["message"].lower()
    
    @pytest.mark.asyncio
    async def test_resend_otp_already_verified(self, client: AsyncClient, test_user: User):
        """Test OTP resend for already verified user"""
        with patch('app.services.auth.send_otp_sms'):
            response = await client.post(
                "/api/v1/auth/resend-otp",
                json={
                    "phone_number": "+84912345678"  # test_user is verified
                }
            )
        
        assert response.status_code == 400
        assert "already verified" in response.json()["detail"].lower()


class TestLogoutFlow:
    """Integration tests for logout"""
    
    @pytest.mark.asyncio
    async def test_logout(self, client: AsyncClient, test_user: User):
        """Test logout endpoint"""
        # First login
        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "phone_number": "+84912345678",
                "password": "Test@1234"
            }
        )
        access_token = login_response.json()["access_token"]
        
        # Then logout
        response = await client.post(
            "/api/v1/auth/logout",
            headers={
                "Authorization": f"Bearer {access_token}"
            }
        )
        
        assert response.status_code == 200
        assert "logout" in response.json()["message"].lower()


class TestCompleteAuthenticationFlow:
    """Integration tests for complete authentication flows"""
    
    @pytest.mark.asyncio
    async def test_complete_registration_and_login_flow(self, client: AsyncClient):
        """Test complete flow: register -> verify OTP -> login"""
        phone = "+84444444444"
        password = "Test@1234"
        
        # 1. Register
        with patch('app.services.auth.send_otp_sms'):
            with patch('app.services.auth.generate_otp', return_value="123456"):
                register_response = await client.post(
                    "/api/v1/auth/register",
                    json={
                        "phone_number": phone,
                        "password": password,
                        "full_name": "Complete Flow User"
                    }
                )
        assert register_response.status_code == 201
        
        # 2. Verify OTP
        with patch('app.services.auth.verify_otp', return_value=True):
            verify_response = await client.post(
                "/api/v1/auth/verify-otp",
                json={
                    "phone_number": phone,
                    "otp": "123456"
                }
            )
        assert verify_response.status_code == 200
        assert "access_token" in verify_response.json()
        
        # 3. Login
        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "phone_number": phone,
                "password": password
            }
        )
        assert login_response.status_code == 200
        assert "access_token" in login_response.json()
    
    @pytest.mark.asyncio
    async def test_complete_password_reset_flow(self, client: AsyncClient, test_user: User):
        """Test complete flow: forgot password -> reset -> login with new password"""
        phone = "+84912345678"
        old_password = "Test@1234"
        new_password = "NewPassword@9999"
        
        # 1. Forgot password
        with patch('app.services.auth.send_otp_sms'):
            with patch('app.services.auth.generate_otp', return_value="654321"):
                forgot_response = await client.post(
                    "/api/v1/auth/forgot-password",
                    json={"phone_number": phone}
                )
        assert forgot_response.status_code == 200
        
        # 2. Reset password
        with patch('app.services.auth.verify_otp', return_value=True):
            reset_response = await client.post(
                "/api/v1/auth/reset-password",
                json={
                    "phone_number": phone,
                    "otp": "654321",
                    "new_password": new_password
                }
            )
        assert reset_response.status_code == 200
        
        # 3. Login with new password
        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "phone_number": phone,
                "password": new_password
            }
        )
        assert login_response.status_code == 200
        
        # 4. Verify old password doesn't work
        old_login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "phone_number": phone,
                "password": old_password
            }
        )
        assert old_login_response.status_code == 401
