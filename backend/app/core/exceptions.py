"""
Custom exception classes for the application.
"""
from typing import Any, Optional


class AppException(Exception):
    """Base exception class for application errors."""
    
    def __init__(
        self,
        message: str,
        status_code: int = 500,
        detail: Optional[Any] = None,
    ):
        self.message = message
        self.status_code = status_code
        self.detail = detail
        super().__init__(self.message)


class ValidationError(AppException):
    """Exception raised for validation errors."""
    
    def __init__(self, message: str = "Validation error", detail: Optional[Any] = None):
        super().__init__(message=message, status_code=400, detail=detail)


class NotFoundError(AppException):
    """Exception raised when a resource is not found."""
    
    def __init__(self, message: str = "Resource not found", detail: Optional[Any] = None):
        super().__init__(message=message, status_code=404, detail=detail)


class UnauthorizedError(AppException):
    """Exception raised for unauthorized access."""
    
    def __init__(self, message: str = "Unauthorized", detail: Optional[Any] = None):
        super().__init__(message=message, status_code=401, detail=detail)


class ForbiddenError(AppException):
    """Exception raised for forbidden access."""
    
    def __init__(self, message: str = "Forbidden", detail: Optional[Any] = None):
        super().__init__(message=message, status_code=403, detail=detail)


class ConflictError(AppException):
    """Exception raised for resource conflicts."""
    
    def __init__(self, message: str = "Resource conflict", detail: Optional[Any] = None):
        super().__init__(message=message, status_code=409, detail=detail)


class BadRequestError(AppException):
    """Exception raised for bad requests."""
    
    def __init__(self, message: str = "Bad request", detail: Optional[Any] = None):
        super().__init__(message=message, status_code=400, detail=detail)


class InternalServerError(AppException):
    """Exception raised for internal server errors."""
    
    def __init__(self, message: str = "Internal server error", detail: Optional[Any] = None):
        super().__init__(message=message, status_code=500, detail=detail)


class ServiceUnavailableError(AppException):
    """Exception raised when a service is unavailable."""
    
    def __init__(self, message: str = "Service unavailable", detail: Optional[Any] = None):
        super().__init__(message=message, status_code=503, detail=detail)
