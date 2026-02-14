"""
PDF Ingestion CLI
Run this script to ingest your agricultural PDF documents into the vector store.

Usage:
    python scripts/ingest_pdfs.py                          # Ingest from default data/ folder
    python scripts/ingest_pdfs.py "C:/path/to/pdfs"        # Ingest from a custom folder
    python scripts/ingest_pdfs.py "C:/path/to/file.pdf"    # Ingest a single file
"""

import os
import sys

# Add project root to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from dotenv import load_dotenv
load_dotenv()

from services.ingestion.pdf_ingester import ingest_pdf, ingest_directory
from services.rag.vector_store import get_store_stats, clear_store


def main():
    print("=" * 60)
    print("🌾 Farmer Copilot — PDF Ingestion Tool")
    print("=" * 60)

    # Check current store status
    stats = get_store_stats()
    print(f"\n📦 Current vector store: {stats['total_documents']} documents")

    # Determine source
    if len(sys.argv) > 1:
        source = sys.argv[1].strip('"').strip("'")
    else:
        # Default: look in data/ folder
        source = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "data"))

    # Interactive mode
    while True:
        print(f"\n📂 Source: {source}")
        print("\nOptions:")
        print("  1. Ingest from this path")
        print("  2. Enter a different path")
        print("  3. View store stats")
        print("  4. Clear store (start fresh)")
        print("  5. Quit")

        choice = input("\n👉 Choose (1-5): ").strip()

        if choice == "1":
            if os.path.isfile(source):
                result = ingest_pdf(source)
                print(f"\nResult: {result}")
            elif os.path.isdir(source):
                result = ingest_directory(source)
            else:
                print(f"❌ Path not found: {source}")
                continue

        elif choice == "2":
            new_path = input("📝 Enter path to PDF file or folder: ").strip().strip('"').strip("'")
            if new_path:
                source = new_path

        elif choice == "3":
            stats = get_store_stats()
            print(f"\n📊 Store Statistics:")
            print(f"   Total documents: {stats['total_documents']}")
            print(f"   Collection: {stats['collection_name']}")
            print(f"   DB path: {stats['db_path']}")

        elif choice == "4":
            confirm = input("⚠️ This will delete all ingested data. Are you sure? (y/n): ").strip().lower()
            if confirm == "y":
                clear_store()
                print("✅ Store cleared")

        elif choice == "5":
            break

    print("\n👋 Done!")


if __name__ == "__main__":
    main()
