"""
LLM Composer using Groq API (Cloud LLaMA 3.3 70B)
Takes retrieved context + question and generates a focused agricultural answer.
"""

import os
from dotenv import load_dotenv

load_dotenv()

client = None


def _init_groq():
    """Initialize Groq client (lazy, once)."""
    global client
    if client is not None:
        return True

    api_key = os.getenv("GROQ_API_KEY", "")
    if not api_key:
        print("⚠️ GROQ_API_KEY not set. Get a free key at https://console.groq.com/")
        return False

    try:
        from groq import Groq
        client = Groq(api_key=api_key)
        print("✅ Groq API connected (LLaMA 3.3 70B)")
        return True
    except Exception as e:
        print(f"⚠️ Groq init failed: {e}")
        return False


SYSTEM_PROMPT = """You are Farmer Copilot — an expert agricultural AI assistant helping Indian farmers.

Rules:
1. Answer ONLY based on the provided Context. If the context doesn't cover the question, say so honestly.
2. Be practical and actionable — give specific advice a farmer can use today.
3. Keep answers concise (2-4 sentences for simple questions, up to 6 for complex ones).
4. When relevant, mention crop names, quantities, timing, and local practices.
5. Do NOT make up facts or statistics."""


def compose(question: str, retrieved: list) -> str:
    """
    Generate an answer using Groq LLaMA with RAG context.

    Args:
        question: User's question (in English)
        retrieved: List of dicts from retriever (each has 'text', 'source')

    Returns:
        Answer string
    """
    # Build context from retrieved documents
    if not retrieved:
        return "I don't have enough information in my knowledge base to answer that question. Please try asking about farming topics like crop management, soil health, irrigation, or pest control."

    context_parts = []
    for i, doc in enumerate(retrieved[:5]):  # Use top 5 docs
        source = doc.get("source", "unknown")
        text = doc.get("text", "")
        context_parts.append(f"[Source: {source}]\n{text}")

    context_text = "\n\n---\n\n".join(context_parts)

    # Try Groq API
    if _init_groq() and client is not None:
        try:
            chat = client.chat.completions.create(
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {
                        "role": "user",
                        "content": f"Context:\n{context_text}\n\n---\nFarmer's Question: {question}\n\nAnswer:"
                    }
                ],
                model=os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile"),
                temperature=0.5,
                max_tokens=300,
                top_p=0.9
            )
            return chat.choices[0].message.content.strip()

        except Exception as e:
            print(f"⚠️ Groq API error: {e}")

    # Fallback: return top context directly
    top_text = retrieved[0].get("text", "")
    return top_text[:400] + ("..." if len(top_text) > 400 else "")
