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


SYSTEM_PROMPT = """You are Farmer Copilot — an expert agricultural assistant.

INSTRUCTIONS:
1. **Goal:** Answer the farmer's question directly and briefly.
2. **Style:** Use **Keywords** and **Short Sentences**. Avoid long explanations.
3. **Length:** Max 2-3 sentences. Focus on the core solution/action.
4. **No Fluff:** Do not repeat the question. Just give the answer.

Example of Style:
Query: "How to kill aphids?"
Answer: "Use Neem Oil spray (5ml/liter). You can also use yellow sticky traps to catch them. Remove infected leaves immediately."

Answer strictly in English (it will be translated)."""


def compose(question: str, retrieved: list) -> str:
    """
    Generate an answer using Groq LLaMA with RAG context.
    """
    # Build context — only use relevant short snippets
    context_parts = []
    for doc in retrieved[:3]:  # Top 3 is usually enough
        text = doc.get("text", "").strip()
        if len(text) > 800:
            text = text[:800]
        if text:
            context_parts.append(text)

    context_text = "\n---\n".join(context_parts)
    
    # Context in User Message
    user_content = f"""
CONTEXT INFORMATION:
{context_text}

USER QUESTION:
{question}

INSTRUCTION: 
Based on the context, provide a **Concise, Keyword-Focused Answer** (2-3 sentences max).
"""

    # Try Groq API
    if _init_groq() and client is not None:
        try:
            chat = client.chat.completions.create(
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {
                        "role": "user",
                        "content": user_content
                    }
                ],
                model=os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile"),
                temperature=0.3,  # Low temp for stability
                max_tokens=500,   # Reduced max_tokens for brevity
                top_p=0.9
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
