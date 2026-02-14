"""
Vector Store using ChromaDB (local, no Docker needed)
Handles embedding storage and semantic search for the RAG pipeline.
"""

import os
import chromadb
from sentence_transformers import SentenceTransformer
from typing import List, Dict, Optional

# Singleton instances
_chroma_client = None
_collection = None
_embedder = None

CHROMA_DB_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "storage", "chroma_db"))
COLLECTION_NAME = "agri_knowledge"


def _get_embedder() -> SentenceTransformer:
    """Lazy-load the sentence transformer model."""
    global _embedder
    if _embedder is None:
        model_name = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
        print(f"⏳ Loading embedding model: {model_name}...")
        _embedder = SentenceTransformer(model_name)
        print(f"✅ Embedding model loaded ({model_name})")
    return _embedder


def _get_collection() -> chromadb.Collection:
    """Get or create the ChromaDB collection."""
    global _chroma_client, _collection
    if _collection is None:
        os.makedirs(CHROMA_DB_PATH, exist_ok=True)
        _chroma_client = chromadb.PersistentClient(path=CHROMA_DB_PATH)
        _collection = _chroma_client.get_or_create_collection(
            name=COLLECTION_NAME,
            metadata={"hnsw:space": "cosine"}  # Use cosine similarity
        )
        count = _collection.count()
        print(f"✅ ChromaDB ready — {count} documents in store")
    return _collection


def add_documents(texts: List[str], metadatas: List[Dict], ids: List[str]) -> int:
    """
    Add documents to the vector store.

    Args:
        texts: List of text chunks
        metadatas: List of metadata dicts (source, title, etc.)
        ids: Unique IDs for each chunk

    Returns:
        Number of documents added
    """
    collection = _get_collection()
    embedder = _get_embedder()

    # Generate embeddings
    embeddings = embedder.encode(texts, show_progress_bar=True).tolist()

    # Add to ChromaDB in batches of 100
    batch_size = 100
    added = 0
    for i in range(0, len(texts), batch_size):
        batch_texts = texts[i:i + batch_size]
        batch_metas = metadatas[i:i + batch_size]
        batch_ids = ids[i:i + batch_size]
        batch_embeds = embeddings[i:i + batch_size]

        collection.add(
            documents=batch_texts,
            metadatas=batch_metas,
            ids=batch_ids,
            embeddings=batch_embeds
        )
        added += len(batch_texts)

    print(f"✅ Added {added} chunks to vector store (total: {collection.count()})")
    return added


def search(query: str, k: int = 5) -> List[Dict]:
    """
    Semantic search against the vector store.

    Args:
        query: Search query text
        k: Number of results to return

    Returns:
        List of dicts with keys: text, source, score
    """
    collection = _get_collection()

    if collection.count() == 0:
        print("⚠️ Vector store is empty. Please ingest documents first.")
        return []

    embedder = _get_embedder()
    query_embedding = embedder.encode(query).tolist()

    results = collection.query(
        query_embeddings=[query_embedding],
        n_results=min(k, collection.count()),
        include=["documents", "metadatas", "distances"]
    )

    # Format results
    formatted = []
    if results and results["documents"] and results["documents"][0]:
        for i, doc in enumerate(results["documents"][0]):
            meta = results["metadatas"][0][i] if results["metadatas"] else {}
            distance = results["distances"][0][i] if results["distances"] else 0
            formatted.append({
                "text": doc,
                "source": meta.get("source", "unknown"),
                "title": meta.get("title", ""),
                "score": round(1 - distance, 4)  # Convert distance to similarity
            })

    return formatted


def get_store_stats() -> Dict:
    """Get statistics about the vector store."""
    collection = _get_collection()
    return {
        "total_documents": collection.count(),
        "collection_name": COLLECTION_NAME,
        "db_path": CHROMA_DB_PATH
    }


def clear_store():
    """Clear all documents from the vector store."""
    global _collection
    client = chromadb.PersistentClient(path=CHROMA_DB_PATH)
    try:
        client.delete_collection(COLLECTION_NAME)
    except Exception:
        pass
    _collection = None
    print("🗑️ Vector store cleared")
