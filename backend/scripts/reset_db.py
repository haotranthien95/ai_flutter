#!/usr/bin/env python3
"""
Script to reset database (drop all tables and re-run migrations)
"""
import asyncio
import subprocess
import sys
from pathlib import Path

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import text

from app.database import engine, init_db


async def drop_all_tables():
    """Drop all tables from database"""
    print("Dropping all tables...")
    
    async with engine.begin() as conn:
        # Drop all tables using CASCADE
        await conn.execute(text("DROP SCHEMA public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.execute(text("GRANT ALL ON SCHEMA public TO postgres"))
        await conn.execute(text("GRANT ALL ON SCHEMA public TO public"))
    
    print("✅ All tables dropped")


def run_migrations():
    """Run Alembic migrations"""
    print("Running Alembic migrations...")
    
    try:
        # Change to backend directory
        backend_dir = Path(__file__).parent.parent
        
        # Run alembic upgrade head
        result = subprocess.run(
            ["alembic", "upgrade", "head"],
            cwd=backend_dir,
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print(f"❌ Migration failed: {result.stderr}")
            sys.exit(1)
        
        print("✅ Migrations completed")
        print(result.stdout)
        
    except FileNotFoundError:
        print("❌ Alembic not found. Make sure it's installed.")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Migration error: {e}")
        sys.exit(1)


def run_seed_script():
    """Run seed data script"""
    print("Running seed data script...")
    
    try:
        seed_script = Path(__file__).parent / "seed_data.py"
        
        result = subprocess.run(
            [sys.executable, str(seed_script)],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print(f"❌ Seeding failed: {result.stderr}")
            return False
        
        print(result.stdout)
        return True
        
    except Exception as e:
        print(f"❌ Seeding error: {e}")
        return False


async def main():
    """Main function to reset database"""
    print("=" * 60)
    print("Database Reset Script")
    print("=" * 60)
    print()
    print("⚠️  WARNING: This will DELETE ALL DATA in the database!")
    print()
    
    # Confirmation prompt
    confirm = input("Are you sure you want to continue? (yes/no): ").strip().lower()
    
    if confirm != "yes":
        print("❌ Operation cancelled")
        sys.exit(0)
    
    print()
    print("Confirming... Type 'DELETE' to proceed: ", end="")
    final_confirm = input().strip()
    
    if final_confirm != "DELETE":
        print("❌ Operation cancelled")
        sys.exit(0)
    
    print()
    print("Initializing database connection...")
    await init_db()
    print("✅ Database connected")
    print()
    
    # Drop all tables
    await drop_all_tables()
    print()
    
    # Run migrations
    run_migrations()
    print()
    
    # Ask if user wants to seed data
    seed_data = input("Do you want to seed test data? (yes/no): ").strip().lower()
    print()
    
    if seed_data == "yes":
        run_seed_script()
    
    print()
    print("=" * 60)
    print("✅ Database reset completed successfully!")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
