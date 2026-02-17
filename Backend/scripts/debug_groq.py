
import os
import sys

# Add backend to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from services.rag.groq_composer import compose

# Mock context
context = [
    {"text": "Scientific beekeeping, also known as meliponiculture in the context of certain ICAR-developed technologies, offers a sustainable way to increase crop yields through pollination services while producing honey and beeswax."},
    {"text": "Apiculture is the maintenance of bee colonies, commonly in man-made hives, by humans."}
]

question = "What is beekeeping called?"

print(f"Testing compose with max_tokens...")
answer = compose(question, context)

print(f"Length: {len(answer)}")
print(f"Answer: {answer}")
