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

YOUR GOAL:
Answer the farmer's question based ONLY on the provided context.
- Be concise (max 3-4 sentences).
- Use simple, direct language.
- Ensure your answer is COMPLETE and does not end mid-sentence.
- Do NOT continue the conversation or generate new questions.
- Do NOT output "Query:" or "Answer:". Just output the answer text.

Answer strictly in English."""

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

    # Use a clear separator that won't confuse the model
    context_text = "\n\n".join(context_parts)
    
    # Context in User Message
    user_content = f"""
CONTEXT:
{context_text}

QUESTION:
{question}

ANSWER:
"""

    # Try Groq API
    if _init_groq() and client is not None:
        try:
            chat = client.chat.completions.create(
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": user_content}
                ],
                model=os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile"),
                temperature=0.1,  # Lower temperature for more deterministic output
                max_tokens=600,   # Increased to prevent truncation
                top_p=0.9
            )
            answer = chat.choices[0].message.content.strip()
            # Clean up any potential artifacts if the model still outputs them
            if answer.startswith("Answer:"):
                answer = answer[7:].strip()
            
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
