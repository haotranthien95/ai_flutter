"""
Unit tests for validators utility
"""
from decimal import Decimal

import pytest

from app.core.exceptions import ValidationError
from app.utils.validators import (
    validate_vietnamese_phone,
    normalize_vietnamese_phone,
    validate_price,
    validate_email,
    validate_image_file,
    validate_image_size,
    validate_url,
    validate_password_strength,
    validate_order_code,
    validate_voucher_code,
    sanitize_string,
)


class TestVietnamesePhone:
    """Test Vietnamese phone number validation"""

    def test_validate_vietnamese_phone_with_country_code(self):
        """Test phone validation with +84 country code"""
        assert validate_vietnamese_phone("+84901234567") is True

    def test_validate_vietnamese_phone_without_country_code(self):
        """Test phone validation without country code"""
        assert validate_vietnamese_phone("0901234567") is True

    def test_validate_vietnamese_phone_invalid_format(self):
        """Test phone validation with invalid format"""
        with pytest.raises(ValidationError):
            validate_vietnamese_phone("123456789")

    def test_validate_vietnamese_phone_too_short(self):
        """Test phone validation with too short number"""
        with pytest.raises(ValidationError):
            validate_vietnamese_phone("090123456")

    def test_validate_vietnamese_phone_too_long(self):
        """Test phone validation with too long number"""
        with pytest.raises(ValidationError):
            validate_vietnamese_phone("09012345678901")

    def test_validate_vietnamese_phone_empty(self):
        """Test phone validation with empty string"""
        with pytest.raises(ValidationError):
            validate_vietnamese_phone("")

    def test_normalize_vietnamese_phone_with_country_code(self):
        """Test phone normalization with +84"""
        assert normalize_vietnamese_phone("+84901234567") == "+84901234567"

    def test_normalize_vietnamese_phone_without_country_code(self):
        """Test phone normalization without country code"""
        assert normalize_vietnamese_phone("0901234567") == "+84901234567"

    def test_normalize_vietnamese_phone_already_normalized(self):
        """Test phone normalization when already in correct format"""
        assert normalize_vietnamese_phone("+84901234567") == "+84901234567"


class TestPriceValidation:
    """Test price validation"""

    def test_validate_price_valid_integer(self):
        """Test price validation with valid integer"""
        assert validate_price(Decimal("100")) is True

    def test_validate_price_valid_decimal(self):
        """Test price validation with valid decimal"""
        assert validate_price(Decimal("99.99")) is True

    def test_validate_price_one_decimal_place(self):
        """Test price validation with one decimal place"""
        assert validate_price(Decimal("50.5")) is True

    def test_validate_price_negative(self):
        """Test price validation with negative value"""
        with pytest.raises(ValidationError):
            validate_price(Decimal("-10"))

    def test_validate_price_zero(self):
        """Test price validation with zero"""
        with pytest.raises(ValidationError):
            validate_price(Decimal("0"))

    def test_validate_price_too_many_decimals(self):
        """Test price validation with too many decimal places"""
        with pytest.raises(ValidationError):
            validate_price(Decimal("99.999"))

    def test_validate_price_with_min_value(self):
        """Test price validation with custom minimum"""
        assert validate_price(Decimal("50"), min_value=Decimal("50")) is True
        with pytest.raises(ValidationError):
            validate_price(Decimal("49"), min_value=Decimal("50"))


class TestEmailValidation:
    """Test email validation"""

    def test_validate_email_valid(self):
        """Test email validation with valid email"""
        assert validate_email("user@example.com") is True

    def test_validate_email_with_plus(self):
        """Test email validation with plus sign"""
        assert validate_email("user+tag@example.com") is True

    def test_validate_email_with_subdomain(self):
        """Test email validation with subdomain"""
        assert validate_email("user@mail.example.com") is True

    def test_validate_email_invalid_format(self):
        """Test email validation with invalid format"""
        with pytest.raises(ValidationError):
            validate_email("invalid-email")

    def test_validate_email_missing_at(self):
        """Test email validation missing @ symbol"""
        with pytest.raises(ValidationError):
            validate_email("userexample.com")

    def test_validate_email_empty(self):
        """Test email validation with empty string"""
        with pytest.raises(ValidationError):
            validate_email("")


class TestImageValidation:
    """Test image file validation"""

    def test_validate_image_file_jpg(self):
        """Test image validation with jpg"""
        assert validate_image_file("photo.jpg") is True

    def test_validate_image_file_jpeg(self):
        """Test image validation with jpeg"""
        assert validate_image_file("photo.jpeg") is True

    def test_validate_image_file_png(self):
        """Test image validation with png"""
        assert validate_image_file("photo.png") is True

    def test_validate_image_file_gif(self):
        """Test image validation with gif"""
        assert validate_image_file("photo.gif") is True

    def test_validate_image_file_webp(self):
        """Test image validation with webp"""
        assert validate_image_file("photo.webp") is True

    def test_validate_image_file_uppercase_extension(self):
        """Test image validation with uppercase extension"""
        assert validate_image_file("photo.JPG") is True

    def test_validate_image_file_invalid_extension(self):
        """Test image validation with invalid extension"""
        with pytest.raises(ValidationError):
            validate_image_file("document.pdf")

    def test_validate_image_size_valid(self):
        """Test image size validation within limit"""
        assert validate_image_size(1024 * 1024) is True  # 1MB

    def test_validate_image_size_at_limit(self):
        """Test image size validation at limit"""
        assert validate_image_size(5 * 1024 * 1024) is True  # 5MB

    def test_validate_image_size_exceeds_limit(self):
        """Test image size validation exceeding limit"""
        with pytest.raises(ValidationError):
            validate_image_size(6 * 1024 * 1024)  # 6MB

    def test_validate_image_size_custom_max(self):
        """Test image size validation with custom max"""
        assert validate_image_size(2 * 1024 * 1024, max_size_mb=2) is True
        with pytest.raises(ValidationError):
            validate_image_size(3 * 1024 * 1024, max_size_mb=2)


class TestURLValidation:
    """Test URL validation"""

    def test_validate_url_http(self):
        """Test URL validation with http"""
        assert validate_url("http://example.com") is True

    def test_validate_url_https(self):
        """Test URL validation with https"""
        assert validate_url("https://example.com") is True

    def test_validate_url_with_path(self):
        """Test URL validation with path"""
        assert validate_url("https://example.com/path/to/page") is True

    def test_validate_url_with_query(self):
        """Test URL validation with query string"""
        assert validate_url("https://example.com?key=value") is True

    def test_validate_url_invalid_protocol(self):
        """Test URL validation with invalid protocol"""
        with pytest.raises(ValidationError):
            validate_url("ftp://example.com")

    def test_validate_url_missing_protocol(self):
        """Test URL validation missing protocol"""
        with pytest.raises(ValidationError):
            validate_url("example.com")


class TestPasswordStrength:
    """Test password strength validation"""

    def test_validate_password_strength_valid(self):
        """Test password validation with strong password"""
        assert validate_password_strength("StrongP@ss123") is True

    def test_validate_password_strength_minimum_length(self):
        """Test password validation with minimum length"""
        assert validate_password_strength("Str0ng@1") is True

    def test_validate_password_strength_too_short(self):
        """Test password validation too short"""
        with pytest.raises(ValidationError):
            validate_password_strength("Str0@1")

    def test_validate_password_strength_missing_uppercase(self):
        """Test password validation missing uppercase"""
        with pytest.raises(ValidationError):
            validate_password_strength("strong@pass123")

    def test_validate_password_strength_missing_lowercase(self):
        """Test password validation missing lowercase"""
        with pytest.raises(ValidationError):
            validate_password_strength("STRONG@PASS123")

    def test_validate_password_strength_missing_digit(self):
        """Test password validation missing digit"""
        with pytest.raises(ValidationError):
            validate_password_strength("Strong@Password")

    def test_validate_password_strength_missing_special(self):
        """Test password validation missing special character"""
        with pytest.raises(ValidationError):
            validate_password_strength("StrongPassword123")


class TestOrderCode:
    """Test order code validation"""

    def test_validate_order_code_valid(self):
        """Test order code validation with valid code"""
        assert validate_order_code("ORD-20240115-12345") is True

    def test_validate_order_code_invalid_prefix(self):
        """Test order code validation with invalid prefix"""
        with pytest.raises(ValidationError):
            validate_order_code("ORDER-20240115-12345")

    def test_validate_order_code_invalid_date(self):
        """Test order code validation with invalid format (not date validation)"""
        with pytest.raises(ValidationError):
            validate_order_code("ORD-2024115-12345")  # Only 7 digits instead of 8

    def test_validate_order_code_invalid_sequence(self):
        """Test order code validation with invalid sequence"""
        with pytest.raises(ValidationError):
            validate_order_code("ORD-20240115-1234")

    def test_validate_order_code_empty(self):
        """Test order code validation with empty string"""
        with pytest.raises(ValidationError):
            validate_order_code("")


class TestVoucherCode:
    """Test voucher code validation"""

    def test_validate_voucher_code_valid(self):
        """Test voucher code validation with valid code"""
        assert validate_voucher_code("SUMMER2024") is True

    def test_validate_voucher_code_with_hyphens(self):
        """Test voucher code validation with hyphens"""
        assert validate_voucher_code("NEW-YEAR-2024") is True

    def test_validate_voucher_code_minimum_length(self):
        """Test voucher code validation with minimum length"""
        assert validate_voucher_code("SALE") is True

    def test_validate_voucher_code_maximum_length(self):
        """Test voucher code validation with maximum length"""
        assert validate_voucher_code("SUPER-MEGA-SALE-2024") is True

    def test_validate_voucher_code_too_short(self):
        """Test voucher code validation too short"""
        with pytest.raises(ValidationError):
            validate_voucher_code("SAL")

    def test_validate_voucher_code_too_long(self):
        """Test voucher code validation too long"""
        with pytest.raises(ValidationError):
            validate_voucher_code("SUPER-MEGA-ULTRA-SALE-2024")

    def test_validate_voucher_code_lowercase(self):
        """Test voucher code validation with lowercase"""
        with pytest.raises(ValidationError):
            validate_voucher_code("summer2024")

    def test_validate_voucher_code_special_chars(self):
        """Test voucher code validation with special characters"""
        with pytest.raises(ValidationError):
            validate_voucher_code("SUMMER@2024")


class TestSanitizeString:
    """Test string sanitization"""

    def test_sanitize_string_trim_whitespace(self):
        """Test sanitization trimming whitespace"""
        assert sanitize_string("  hello  ") == "hello"

    def test_sanitize_string_remove_extra_spaces(self):
        """Test sanitization removing extra spaces"""
        assert sanitize_string("hello    world") == "hello world"

    def test_sanitize_string_remove_newlines(self):
        """Test sanitization removing newlines"""
        assert sanitize_string("hello\nworld") == "hello world"

    def test_sanitize_string_remove_tabs(self):
        """Test sanitization removing tabs"""
        assert sanitize_string("hello\tworld") == "hello world"

    def test_sanitize_string_mixed_whitespace(self):
        """Test sanitization with mixed whitespace"""
        assert sanitize_string("  hello \n\t world  ") == "hello world"

    def test_sanitize_string_empty(self):
        """Test sanitization with empty string"""
        assert sanitize_string("") == ""

    def test_sanitize_string_only_whitespace(self):
        """Test sanitization with only whitespace"""
        assert sanitize_string("   \n\t   ") == ""
