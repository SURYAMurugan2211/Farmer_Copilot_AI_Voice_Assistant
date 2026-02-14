"""Minimal RAG test - output to file to avoid terminal encoding issues."""
import os, sys, warnings
warnings.filterwarnings("ignore")
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from dotenv import load_dotenv
load_dotenv()

# Redirect all output to file
output_path = os.path.join(os.path.dirname(__file__), "rag_results.txt")
original_stdout = sys.stdout

with open(output_path, "w", encoding="utf-8") as f:
    sys.stdout = f

    from services.rag.vector_store import get_store_stats
    from services.rag.retriever import semantic_search
    from services.rag.groq_composer import compose

    stats = get_store_stats()
    print(f"VECTOR STORE: {stats['total_documents']} documents\n")

    questions = [
        "How to detect wheat leaf disease?",
        "What is the best fertilizer for rice?",
        "How to control pests in tomato plants?",
    ]

    for q in questions:
        print(f"QUESTION: {q}")
        results = semantic_search(q, k=3)
        for i, r in enumerate(results):
            print(f"  DOC {i+1} [score={r.get('score', '?')}] source={r.get('source', '?')}")
            print(f"    {r['text'][:150]}...")
        answer = compose(q, results)
        print(f"\n  LLM ANSWER: {answer}")
        print(f"\n{'='*60}\n")

    print("TEST COMPLETE")

sys.stdout = original_stdout
print(f"Results written to: {output_path}")
