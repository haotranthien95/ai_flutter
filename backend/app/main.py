"""
Main FastAPI application
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError

from app.config import settings
from app.core.logging import setup_logging, get_logger
from app.database import close_db, init_db, AsyncSessionLocal
from app.core.exceptions import AppException


# Setup logging
setup_logging()
log = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    log.info(f"Starting {settings.APP_NAME} v{settings.APP_VERSION}")
    log.info(f"Environment: {settings.ENVIRONMENT}")
    log.info(f"Debug mode: {settings.DEBUG}")
    # await init_db()  # Uncomment when ready to use
    yield
    # Shutdown
    log.info("Shutting down application...")
    await close_db()


# Initialize FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="E-Commerce Marketplace REST API - A comprehensive platform for buyers and sellers",
    docs_url=f"{settings.API_PREFIX}/docs",
    redoc_url=f"{settings.API_PREFIX}/redoc",
    openapi_url=f"{settings.API_PREFIX}/openapi.json",
    lifespan=lifespan,
    openapi_tags=[
        {"name": "Health", "description": "Health check endpoints"},
        {"name": "Authentication", "description": "User registration and login"},
        {"name": "Users", "description": "User profile and address management"},
        {"name": "Seller", "description": "Seller and shop management"},
        {"name": "Products", "description": "Product catalog and management"},
        {"name": "Categories", "description": "Product category management"},
        {"name": "Cart", "description": "Shopping cart operations"},
        {"name": "Orders", "description": "Order management and checkout"},
        {"name": "Vouchers", "description": "Discount voucher management"},
        {"name": "Reviews", "description": "Product reviews and ratings"},
        {"name": "Notifications", "description": "User notification management"},
        {"name": "Admin", "description": "Admin platform management"},
    ],
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Exception handlers
@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    """Handle custom application exceptions"""
    log.warning(f"Application exception: {exc.message} - {exc.detail}")
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.message,
            "detail": exc.detail,
        },
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle validation errors"""
    log.warning(f"Validation error: {exc.errors()}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "Validation Error",
            "details": exc.errors(),
        },
    )


@app.exception_handler(SQLAlchemyError)
async def database_exception_handler(request: Request, exc: SQLAlchemyError):
    """Handle database errors"""
    log.error(f"Database error: {type(exc).__name__} - {str(exc)}")
    if settings.DEBUG:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": "Database Error",
                "message": str(exc),
                "type": type(exc).__name__,
            },
        )
    else:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": "Database Error",
                "message": "A database error occurred",
            },
        )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle all other exceptions"""
    log.error(f"Unhandled exception: {type(exc).__name__} - {str(exc)}", exc_info=True)
    if settings.DEBUG:
        # In debug mode, return full error details
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": "Internal Server Error",
                "message": str(exc),
                "type": type(exc).__name__,
            },
        )
    else:
        # In production, return generic error
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": "Internal Server Error",
                "message": "An unexpected error occurred",
            },
        )


# Health check endpoint
@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
    }


# Database health check endpoint
@app.get("/health/db", tags=["Health"])
async def database_health_check():
    """Database connection health check"""
    from sqlalchemy import text
    try:
        async with AsyncSessionLocal() as session:
            # Try to execute a simple query
            result = await session.execute(text("SELECT 1"))
            result.scalar()
            return {
                "status": "healthy",
                "database": "connected",
                "message": "Database connection successful"
            }
    except Exception as e:
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e)
        }


# Root endpoint
@app.get("/", tags=["Root"])
async def root():
    """Root endpoint"""
    return {
        "message": f"Welcome to {settings.APP_NAME}",
        "version": settings.APP_VERSION,
        "docs": f"{settings.API_PREFIX}/docs",
    }


# Include API routers
from app.api.v1.router import api_router
app.include_router(api_router, prefix=settings.API_PREFIX)
