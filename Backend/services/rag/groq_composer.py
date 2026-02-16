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


SYSTEM_PROMPT = """You are Farmer Copilot — a farming AI assistant for Indian farmers.

CORE INSTRUCTION:
Provide a **SHORT and SWEET** answer (max 3 lines) to the farmer's specific question.

RULES FOR USING CONTEXT:
1. **CRITICAL:** First, check if the provided 'Context' actually answers the specific question.
2. If the Context is **IRRELEVANT** (e.g., user asks about 'Water Plants' but context is about 'Wheat'), **IGNORE THE CONTEXT COMPLETELY**.
3. Instead, answer directly from your own **General Agricultural Knowledge**.
4. If Context IS relevant, combine it with your knowledge for the best answer.

OUTPUT FORMAT:
• Answer in 2-3 simple bullet points.
• Be direct. No fluff. No "Hello" or "Here is the answer".
• **NEVER** dump the raw context if it doesn't match the question.

Example (Good):
• Water spinach (Kang Kong) and Lotus are excellent for water farming.
• Lotus is the most profitable choice for varied products (flowers, roots).
• Ensure clean, stagnant water for best growth.

Answer explicitly and concisely."""


def compose(question: str, retrieved: list) -> str:
    """
    Generate an answer using Groq LLaMA with RAG context.
    """
    # Support General Knowledge fallback if no docs found
    # (Do not return early, let the LLM handle it with empty context)
    # in case retrieved is empty, context_text will be empty string.

    # Build context — only use relevant short snippets
    context_parts = []
    for doc in retrieved[:3]:  # Only top 3 for focused answers
        text = doc.get("text", "").strip()
        # Skip very long or irrelevant chunks
        if len(text) > 500:
            text = text[:500]
        if text:
            context_parts.append(text)

    context_text = "\n---\n".join(context_parts)

    # Try Groq API
    if _init_groq() and client is not None:
        try:
            chat = client.chat.completions.create(
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {
                        "role": "user",
                        "content": f"Reference info:\n{context_text}\n\nFarmer asks: {question}\n\nGive a short, helpful answer in 2-3 simple sentences:"
                    }
                ],
                model=os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile"),
                temperature=0.3,
                max_tokens=150,
                top_p=0.85
            )
            answer = chat.choices[0].message.content.strip()
            print(f"✅ Groq answer ({len(answer)} chars): {answer[:80]}...")
            return answer

        except Exception as e:
            print(f"⚠️ Groq API error: {e}")

    # Smart fallback — don't dump raw text, summarize it
    if retrieved:
        top_text = retrieved[0].get("text", "").strip()
        # Extract just the first meaningful sentence
        sentences = [s.strip() for s in top_text.replace('\n', '. ').split('.') if len(s.strip()) > 15]
        if sentences:
            # Return first 2 relevant sentences
            fallback = '. '.join(sentences[:2]) + '.'
            if len(fallback) > 200:
                fallback = sentences[0] + '.'
            return fallback
    
    return "Sorry, I couldn't process your question right now. Please try again."
