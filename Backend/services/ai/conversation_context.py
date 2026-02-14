from typing import Dict, List, Optional, Any
from datetime import datetime, timedelta
import json
from dataclasses import dataclass, asdict
from services.db.user_service import QueryService

@dataclass
class ConversationTurn:
    """Represents a single turn in conversation"""
    user_input: str
    ai_response: str
    intent: str
    entities: Dict[str, Any]
    timestamp: datetime
    confidence: float

class ConversationContext:
    """Manages conversation context and memory for users"""
    
    def __init__(self, user_id: int, max_turns: int = 5, context_window_hours: int = 24):
        self.user_id = user_id
        self.max_turns = max_turns
        self.context_window_hours = context_window_hours
        self.conversation_history: List[ConversationTurn] = []
        self._load_recent_context()
    
    def _load_recent_context(self):
        """Load recent conversation history from database"""
        try:
            recent_queries = QueryService.get_user_queries(self.user_id, limit=self.max_turns)
            
            for query in reversed(recent_queries):  # Reverse to get chronological order
                # Only include queries from the last 24 hours
                if query.created_at > datetime.utcnow() - timedelta(hours=self.context_window_hours):
                    turn = ConversationTurn(
                        user_input=query.original_text,
                        ai_response=query.response_text,
                        intent=query.intent or "unknown",
                        entities={},  # Could be enhanced to store entities
                        timestamp=query.created_at,
                        confidence=query.confidence or 0.0
                    )
                    self.conversation_history.append(turn)
        except Exception as e:
            print(f"Error loading conversation context: {e}")
    
    def add_turn(self, user_input: str, ai_response: str, intent: str, entities: Dict[str, Any], confidence: float = 0.0):
        """Add a new conversation turn"""
        turn = ConversationTurn(
            user_input=user_input,
            ai_response=ai_response,
            intent=intent,
            entities=entities,
            timestamp=datetime.utcnow(),
            confidence=confidence
        )
        
        self.conversation_history.append(turn)
        
        # Keep only the most recent turns
        if len(self.conversation_history) > self.max_turns:
            self.conversation_history = self.conversation_history[-self.max_turns:]
    
    def get_context_summary(self) -> str:
        """Generate a context summary for the AI model"""
        if not self.conversation_history:
            return ""
        
        context_parts = []
        
        # Recent topics discussed
        recent_intents = [turn.intent for turn in self.conversation_history[-3:]]
        if recent_intents:
            context_parts.append(f"Recent topics: {', '.join(set(recent_intents))}")
        
        # Previous questions for reference
        if len(self.conversation_history) >= 2:
            prev_turn = self.conversation_history[-2]
            context_parts.append(f"Previous question: {prev_turn.user_input}")
            context_parts.append(f"Previous answer: {prev_turn.ai_response[:100]}...")
        
        return " | ".join(context_parts)
    
    def get_related_entities(self) -> Dict[str, List[str]]:
        """Extract related entities from conversation history"""
        all_entities = {}
        
        for turn in self.conversation_history:
            for entity_type, entities in turn.entities.items():
                if entity_type not in all_entities:
                    all_entities[entity_type] = []
                
                if isinstance(entities, list):
                    all_entities[entity_type].extend(entities)
                else:
                    all_entities[entity_type].append(entities)
        
        # Remove duplicates
        for entity_type in all_entities:
            all_entities[entity_type] = list(set(all_entities[entity_type]))
        
        return all_entities
    
    def is_follow_up_question(self, current_input: str) -> bool:
        """Determine if current input is a follow-up to previous conversation"""
        if not self.conversation_history:
            return False
        
        # Simple heuristics for follow-up detection
        follow_up_indicators = [
            "what about", "how about", "and", "also", "more", "tell me more",
            "explain", "why", "how", "when", "where", "can you", "what if"
        ]
        
        current_lower = current_input.lower()
        return any(indicator in current_lower for indicator in follow_up_indicators)
    
    def get_conversation_summary(self) -> Dict[str, Any]:
        """Get a summary of the conversation for analytics"""
        if not self.conversation_history:
            return {"total_turns": 0, "topics": [], "duration_minutes": 0}
        
        topics = list(set(turn.intent for turn in self.conversation_history))
        
        # Calculate conversation duration
        if len(self.conversation_history) > 1:
            start_time = self.conversation_history[0].timestamp
            end_time = self.conversation_history[-1].timestamp
            duration = (end_time - start_time).total_seconds() / 60
        else:
            duration = 0
        
        return {
            "total_turns": len(self.conversation_history),
            "topics": topics,
            "duration_minutes": round(duration, 2),
            "avg_confidence": sum(turn.confidence for turn in self.conversation_history) / len(self.conversation_history)
        }

class ContextualResponseGenerator:
    """Generates contextually aware responses"""
    
    @staticmethod
    def enhance_prompt_with_context(base_prompt: str, context: ConversationContext, current_query: str) -> str:
        """Enhance the prompt with conversation context"""
        
        context_summary = context.get_context_summary()
        related_entities = context.get_related_entities()
        is_follow_up = context.is_follow_up_question(current_query)
        
        enhanced_prompt = base_prompt
        
        if context_summary:
            enhanced_prompt += f"\n\nConversation Context: {context_summary}"
        
        if related_entities:
            entities_str = ", ".join([f"{k}: {v}" for k, v in related_entities.items()])
            enhanced_prompt += f"\nRelated topics discussed: {entities_str}"
        
        if is_follow_up:
            enhanced_prompt += "\nNote: This appears to be a follow-up question. Please reference previous context when appropriate."
        
        return enhanced_prompt
    
    @staticmethod
    def generate_contextual_response(query: str, retrieved_docs: List[Dict], context: ConversationContext) -> str:
        """Generate a response that takes conversation context into account"""
        
        # Build context-aware prompt
        base_prompt = f"Question: {query}\nContext:\n" + "\n---\n".join([doc["text"] for doc in retrieved_docs])
        
        enhanced_prompt = ContextualResponseGenerator.enhance_prompt_with_context(
            base_prompt, context, query
        )
        
        enhanced_prompt += "\n\nProvide a helpful, contextually aware response that references previous conversation when relevant:"
        
        return enhanced_prompt

# Global context manager for active conversations
_active_contexts: Dict[int, ConversationContext] = {}

def get_conversation_context(user_id: int) -> ConversationContext:
    """Get or create conversation context for a user"""
    if user_id not in _active_contexts:
        _active_contexts[user_id] = ConversationContext(user_id)
    return _active_contexts[user_id]

def cleanup_inactive_contexts(max_age_hours: int = 2):
    """Clean up inactive conversation contexts"""
    current_time = datetime.utcnow()
    inactive_users = []
    
    for user_id, context in _active_contexts.items():
        if context.conversation_history:
            last_activity = context.conversation_history[-1].timestamp
            if current_time - last_activity > timedelta(hours=max_age_hours):
                inactive_users.append(user_id)
    
    for user_id in inactive_users:
        del _active_contexts[user_id]
    
    print(f"Cleaned up {len(inactive_users)} inactive conversation contexts")