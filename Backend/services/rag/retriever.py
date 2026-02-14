"""
Retriever — Semantic search over ingested documents.
Uses ChromaDB vector store for fast, local similarity search.
Falls back to built-in knowledge if the store is empty.
"""

import os
from typing import List, Dict
from services.rag.vector_store import search as vector_search, get_store_stats

# Minimal fallback knowledge (used only when vector store is empty)
FALLBACK_KNOWLEDGE = [
    {
        "text": "Crop rotation is the practice of growing a series of different types of crops in the same area across a sequence of growing seasons. It reduces reliance on one set of nutrients, pest and weed pressure, and the probability of developing resistant pests and weeds.",
        "source": "built-in", "score": 0.5
    },
    {
        "text": "Organic farming is a method of crop and livestock production that involves much more than choosing not to use pesticides, fertilizers, genetically modified organisms, antibiotics and growth hormones. It is a holistic system designed to optimize the productivity and fitness of diverse communities within the ecosystem.",
        "source": "built-in", "score": 0.5
    },
    {
        "text": "Irrigation is the artificial application of water to land or soil to assist in the growing of agricultural crops. Methods include drip irrigation, sprinkler systems, surface irrigation and sub-irrigation.",
        "source": "built-in", "score": 0.5
    },
    {
        "text": "Soil health refers to the continued capacity of soil to function as a vital living ecosystem that sustains plants, animals, and humans. Proper soil management includes testing pH, adding organic matter, crop rotation, and minimizing tillage.",
        "source": "built-in", "score": 0.5
    },
    {
        "text": "Precision agriculture uses GPS, IoT sensors, drones, and data analytics to manage crops at a micro-level. It helps farmers optimize inputs like water, fertilizer, and pesticides to maximize yield while reducing waste.",
        "source": "built-in", "score": 0.5
    },
]


def semantic_search(query: str, k: int = 5) -> List[Dict]:
    """
    Search the knowledge base for relevant documents.

    Priority:
        1. ChromaDB vector store (if documents are ingested)
        2. Fallback built-in knowledge

    Args:
        query: The user's question in English
        k: Number of results to return

    Returns:
        List of dicts with keys: text, source, score
    """
    try:
        stats = get_store_stats()
        if stats["total_documents"] > 0:
            # Use real vector search
            results = vector_search(query, k=k)
            if results:
                print(f"🔍 Found {len(results)} results from vector store")
                return results
            else:
                print("⚠️ Vector search returned no results, using fallback")
        else:
            print("📝 Vector store is empty — using fallback knowledge. Run 'python scripts/ingest_pdfs.py' to add your PDFs.")
    except Exception as e:
        print(f"⚠️ Vector search error: {e}")

    # Fallback: simple keyword matching
    return _keyword_search(query, k)


def _keyword_search(query: str, k: int = 5) -> List[Dict]:
    """Simple keyword-based fallback search."""
    query_lower = query.lower()
    stop_words = {'the', 'is', 'are', 'what', 'how', 'do', 'i', 'a', 'an', 'to', 'in', 'for', 'of', 'and', 'or', 'about', 'tell', 'me', 'can', 'you'}
    query_words = [w for w in query_lower.split() if w not in stop_words and len(w) > 2]

    scored = []
    for doc in FALLBACK_KNOWLEDGE:
        text_lower = doc["text"].lower()
        score = sum(3 for w in query_words if w in text_lower)
        scored.append({**doc, "score": score})

    scored.sort(key=lambda x: x["score"], reverse=True)

    # Return at least some results even if no keyword match
    if scored[0]["score"] == 0:
        return FALLBACK_KNOWLEDGE[:k]

    return scored[:k]
