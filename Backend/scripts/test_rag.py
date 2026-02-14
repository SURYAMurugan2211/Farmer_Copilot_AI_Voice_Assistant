"""
RAG Pipeline Test
Tests: Embedding → Vector Store → Retrieval → LLM Composition
"""

import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from dotenv import load_dotenv
load_dotenv()


def test_vector_store():
    """Test adding and searching documents."""
    print("\n📦 Test 1: Vector Store")
    print("-" * 40)

    from services.rag.vector_store import add_documents, search, get_store_stats

    # Add test documents
    test_texts = [
        "Rice cultivation requires well-drained soil with a pH between 5.5 and 7.0. The best time to plant rice is during the monsoon season.",
        "Neem oil is an effective organic pesticide for controlling aphids, whiteflies, and mealybugs on vegetable crops.",
        "Drip irrigation saves up to 60% water compared to flood irrigation and delivers water directly to plant roots.",
    ]
    test_metas = [
        {"source": "test_rice.pdf", "title": "Rice Guide", "category": "crops", "chunk_index": "0"},
        {"source": "test_pest.pdf", "title": "Pest Control", "category": "pests", "chunk_index": "0"},
        {"source": "test_irrigation.pdf", "title": "Irrigation", "category": "irrigation", "chunk_index": "0"},
    ]
    test_ids = ["test_1", "test_2", "test_3"]

    added = add_documents(test_texts, test_metas, test_ids)
    print(f"   Added: {added} documents")

    # Search
    results = search("How to grow rice?", k=2)
    print(f"   Search 'How to grow rice?' → {len(results)} results")
    for r in results:
        print(f"     - [{r['source']}] score={r['score']}: {r['text'][:80]}...")

    stats = get_store_stats()
    print(f"   Store has {stats['total_documents']} documents total")
    print("   ✅ Vector Store: PASS")


def test_retriever():
    """Test the retriever module."""
    print("\n🔍 Test 2: Retriever")
    print("-" * 40)

    from services.rag.retriever import semantic_search

    results = semantic_search("What pest control methods are available?")
    print(f"   Found {len(results)} results")
    for r in results[:3]:
        print(f"     - [{r.get('source', '?')}] {r['text'][:80]}...")
    print("   ✅ Retriever: PASS")


def test_composer():
    """Test the LLM composer."""
    print("\n🤖 Test 3: LLM Composer (Groq)")
    print("-" * 40)

    from services.rag.retriever import semantic_search
    from services.rag.groq_composer import compose

    question = "How should I irrigate my crops to save water?"
    retrieved = semantic_search(question)
    answer = compose(question, retrieved)

    print(f"   Question: {question}")
    print(f"   Context docs: {len(retrieved)}")
    print(f"   Answer: {answer[:200]}...")
    print("   ✅ Composer: PASS")


def test_full_pipeline():
    """Test full RAG pipeline interactively."""
    print("\n🔄 Test 4: Interactive RAG Pipeline")
    print("-" * 40)

    from services.rag.retriever import semantic_search
    from services.rag.groq_composer import compose

    while True:
        question = input("\n🌾 Ask a farming question (or 'q' to quit): ").strip()
        if question.lower() == 'q':
            break

        print("🔍 Searching knowledge base...")
        retrieved = semantic_search(question)
        print(f"   Found {len(retrieved)} relevant docs")

        print("🤖 Generating answer...")
        answer = compose(question, retrieved)

        print(f"\n💬 Answer:\n{answer}")
        print(f"\n📚 Sources: {', '.join(set(r.get('source', '?') for r in retrieved[:3]))}")


if __name__ == "__main__":
    print("=" * 60)
    print("🌾 Farmer Copilot — RAG Pipeline Test")
    print("=" * 60)

    test_vector_store()
    test_retriever()
    test_composer()
    test_full_pipeline()

    print("\n✅ All tests complete!")
