"""
Database Migration — Adds new columns to the queries table.
Run this once to upgrade the existing database schema.
"""
import os, sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from dotenv import load_dotenv
load_dotenv()

from services.db.session import engine
from sqlalchemy import text, inspect


def migrate():
    """Add new columns to the queries table if they don't exist."""
    inspector = inspect(engine)
    existing_columns = [col["name"] for col in inspector.get_columns("queries")]

    new_columns = {
        "input_audio_url": "VARCHAR(300)",
        "response_audio_url": "VARCHAR(300)",
        "response_text_en": "TEXT",
        "detected_language": "VARCHAR(10)",
        "source_count": "INTEGER",
        "query_type": "VARCHAR(20) DEFAULT 'text'",
    }

    with engine.connect() as conn:
        for col_name, col_type in new_columns.items():
            if col_name not in existing_columns:
                sql = f"ALTER TABLE queries ADD COLUMN {col_name} {col_type}"
                conn.execute(text(sql))
                print(f"  + Added column: {col_name} ({col_type})")
            else:
                print(f"  = Column exists: {col_name}")

        conn.commit()

    # Also add feedback relationship column if missing
    feedback_columns = [col["name"] for col in inspector.get_columns("feedback")]
    # All existing columns are fine for feedback

    print("\nMigration complete!")


if __name__ == "__main__":
    print("Running database migration...\n")
    migrate()

    # Verify
    inspector = inspect(engine)
    columns = inspector.get_columns("queries")
    print(f"\nQueries table now has {len(columns)} columns:")
    for col in columns:
        print(f"  - {col['name']} ({col['type']})")
