"""
PDF Ingestion Pipeline
Extracts text from PDFs, chunks them, and stores in the vector database.
"""

import os
import uuid
import hashlib
from typing import List, Dict

from services.ingestion.extract_text import extract_text_from_file
from services.ingestion.chunk_and_meta import chunk_text
from services.rag.vector_store import add_documents, get_store_stats


def ingest_pdf(file_path: str, category: str = "general") -> Dict:
    """
    Ingest a single PDF file into the vector store.

    Args:
        file_path: Absolute path to the PDF file
        category: Category tag (e.g. "crops", "soil", "pests")

    Returns:
        Dictionary with ingestion results
    """
    filename = os.path.basename(file_path)
    print(f"\n📄 Processing: {filename}")

    # Step 1: Extract text
    try:
        raw_text = extract_text_from_file(file_path)
    except Exception as e:
        return {"status": "error", "file": filename, "error": f"Text extraction failed: {e}"}

    if not raw_text or not raw_text.strip():
        return {"status": "error", "file": filename, "error": "No text extracted from file"}

    print(f"   📝 Extracted {len(raw_text)} characters")

    # Step 2: Chunk the text
    file_id = hashlib.md5(filename.encode()).hexdigest()[:8]
    metadata = {
        "filename": filename,
        "file_id": file_id,
        "title": os.path.splitext(filename)[0].replace("_", " ").replace("-", " "),
        "category": category,
        "language": "en"
    }

    chunks = chunk_text(raw_text, metadata, chunk_size=800, overlap=150)

    if not chunks:
        return {"status": "error", "file": filename, "error": "No chunks generated"}

    print(f"   🔪 Created {len(chunks)} chunks")

    # Step 3: Prepare and store embeddings
    texts = [c["text"] for c in chunks]
    metadatas = [
        {
            "source": c["metadata"]["filename"],
            "title": c["metadata"]["title"],
            "category": c["metadata"]["category"],
            "chunk_index": str(c["chunk_index"])  # ChromaDB needs string metadata
        }
        for c in chunks
    ]
    ids = [f"{file_id}_chunk_{c['chunk_index']}" for c in chunks]

    added = add_documents(texts, metadatas, ids)
    print(f"   ✅ Stored {added} chunks for '{filename}'")

    return {
        "status": "success",
        "file": filename,
        "chars_extracted": len(raw_text),
        "chunks_created": len(chunks),
        "chunks_stored": added
    }


def ingest_directory(directory_path: str, category: str = "general") -> Dict:
    """
    Ingest all PDF files from a directory.

    Args:
        directory_path: Path to directory containing PDFs
        category: Category tag for all files in this directory

    Returns:
        Summary dictionary
    """
    if not os.path.isdir(directory_path):
        return {"status": "error", "error": f"Directory not found: {directory_path}"}

    pdf_files = [
        os.path.join(directory_path, f)
        for f in os.listdir(directory_path)
        if f.lower().endswith((".pdf", ".txt", ".docx"))
    ]

    if not pdf_files:
        return {"status": "error", "error": f"No PDF/TXT/DOCX files found in {directory_path}"}

    print(f"\n📂 Found {len(pdf_files)} files in {directory_path}")
    print("=" * 50)

    results = []
    for fp in pdf_files:
        result = ingest_pdf(fp, category=category)
        results.append(result)

    success = [r for r in results if r["status"] == "success"]
    failed = [r for r in results if r["status"] == "error"]

    stats = get_store_stats()

    summary = {
        "status": "complete",
        "total_files": len(pdf_files),
        "successful": len(success),
        "failed": len(failed),
        "total_chunks_in_store": stats["total_documents"],
        "details": results
    }

    print(f"\n{'=' * 50}")
    print(f"📊 Ingestion Summary:")
    print(f"   ✅ Success: {len(success)}/{len(pdf_files)}")
    print(f"   ❌ Failed:  {len(failed)}/{len(pdf_files)}")
    print(f"   📦 Total chunks in store: {stats['total_documents']}")

    if failed:
        print(f"\n   ⚠️ Failed files:")
        for f in failed:
            print(f"      - {f['file']}: {f.get('error', 'unknown error')}")

    return summary
