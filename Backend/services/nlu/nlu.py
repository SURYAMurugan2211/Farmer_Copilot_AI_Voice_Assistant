"""
NLU (Natural Language Understanding) — Intent detection and entity extraction.
Keyword-based for speed; can be upgraded to ML-based later.
"""

from typing import Dict, List, Tuple

# Intent patterns: keyword -> (intent_name, base_confidence)
INTENT_PATTERNS = {
    "market_query":    (["price", "mandi", "market", "cost", "rate", "buy", "sell"], 0.85),
    "pest_control":    (["pest", "insect", "disease", "fungus", "worm", "blight", "rot", "spray"], 0.90),
    "crop_advice":     (["grow", "plant", "seed", "sow", "harvest", "crop", "variety", "yield"], 0.88),
    "fertilizer":      (["fertilizer", "manure", "urea", "npk", "compost", "nutrient", "soil health"], 0.90),
    "irrigation":      (["water", "irrigat", "drip", "sprinkler", "rain", "drought", "moisture"], 0.88),
    "weather":         (["weather", "rain", "temperature", "forecast", "monsoon", "climate"], 0.85),
    "scheme_query":    (["scheme", "subsidy", "government", "loan", "insurance", "pm kisan"], 0.85),
}

# Known crop entities
CROP_NAMES = [
    "paddy", "rice", "wheat", "maize", "corn", "sugarcane", "cotton",
    "tomato", "onion", "potato", "chilli", "pepper", "groundnut", "soybean",
    "mustard", "sunflower", "mango", "banana", "coconut", "tea", "coffee",
    "turmeric", "ginger", "garlic", "brinjal", "okra", "cabbage", "cauliflower",
]


def detect_intent(text: str) -> Dict:
    """
    Detect the intent of the user's query.

    Returns:
        Dict with 'intent' and 'confidence' keys
    """
    text_lower = text.lower()
    best_intent = "general_query"
    best_confidence = 0.5

    for intent, (keywords, base_conf) in INTENT_PATTERNS.items():
        matches = sum(1 for kw in keywords if kw in text_lower)
        if matches > 0:
            # More keyword matches = higher confidence
            confidence = min(base_conf + (matches - 1) * 0.03, 0.99)
            if confidence > best_confidence:
                best_confidence = confidence
                best_intent = intent

    return {
        "intent": best_intent,
        "confidence": round(best_confidence, 2)
    }


def extract_entities(text: str) -> Dict[str, List[str]]:
    """
    Extract entities (crops, locations, etc.) from text.

    Returns:
        Dict with entity types as keys and lists of values
    """
    text_lower = text.lower()

    crops = [c for c in CROP_NAMES if c in text_lower]
    # Deduplicate rice/paddy
    if "rice" in crops and "paddy" in crops:
        crops.remove("paddy")

    entities = {"crops": crops}

    # Extract season mentions
    seasons = []
    for s in ["kharif", "rabi", "zaid", "monsoon", "summer", "winter"]:
        if s in text_lower:
            seasons.append(s)
    if seasons:
        entities["seasons"] = seasons

    return entities
