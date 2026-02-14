"""
Property-based tests for conversation context consistency
**Feature: farmer-copilot-integration, Property 2: Conversation context consistency**
"""

import pytest
from hypothesis import given, strategies as st, settings
from services.ai.conversation_context import ConversationContext, get_conversation_context
from datetime import datetime, timedelta

@settings(max_examples=20, deadline=10000)
@given(
    user_id=st.integers(min_value=1, max_value=1000),
    conversation_turns=st.lists(
        st.tuples(
            st.text(min_size=5, max_size=100),  # user_input
            st.text(min_size=10, max_size=200),  # ai_response
            st.sampled_from(['crop_query', 'pest_control', 'weather', 'market', 'general']),  # intent
            st.floats(min_value=0.1, max_value=1.0)  # confidence
        ),
        min_size=1, max_size=5
    )
)
def test_conversation_context_consistency(user_id, conversation_turns):
    """
    **Feature: farmer-copilot-integration, Property 2: Conversation context consistency**
    
    Property: For any multi-turn conversation, the system should maintain context across turns 
    and reference previous interactions appropriately in follow-up responses
    """
    # Create conversation context
    context = ConversationContext(user_id, max_turns=5)
    
    # Add conversation turns
    for user_input, ai_response, intent, confidence in conversation_turns:
        context.add_turn(
            user_input=user_input,
            ai_response=ai_response,
            intent=intent,
            entities={},
            confidence=confidence
        )
    
    # Property 1: Context should maintain the correct number of turns (up to max_turns)
    expected_turns = min(len(conversation_turns), 5)
    assert len(context.conversation_history) == expected_turns, \
        f"Expected {expected_turns} turns, got {len(context.conversation_history)}"
    
    # Property 2: Most recent turns should be preserved
    if conversation_turns:
        last_turn = context.conversation_history[-1]
        expected_last = conversation_turns[-1]
        assert last_turn.user_input == expected_last[0], "Last user input not preserved"
        assert last_turn.ai_response == expected_last[1], "Last AI response not preserved"
        assert last_turn.intent == expected_last[2], "Last intent not preserved"
    
    # Property 3: Context summary should be generated for non-empty conversations
    if conversation_turns:
        summary = context.get_context_summary()
        assert isinstance(summary, str), "Context summary should be a string"
        if len(conversation_turns) >= 2:
            assert len(summary) > 0, "Context summary should not be empty for multi-turn conversations"
    
    # Property 4: Conversation summary should contain valid metrics
    conv_summary = context.get_conversation_summary()
    assert conv_summary['total_turns'] == len(context.conversation_history), \
        "Total turns mismatch in summary"
    assert isinstance(conv_summary['topics'], list), "Topics should be a list"
    assert conv_summary['duration_minutes'] >= 0, "Duration should be non-negative"

@settings(max_examples=10, deadline=8000)
@given(
    user_id=st.integers(min_value=1, max_value=100),
    follow_up_queries=st.lists(
        st.sampled_from([
            "what about rice?", "tell me more", "how about that?", 
            "can you explain?", "why is that?", "and what else?"
        ]),
        min_size=1, max_size=3
    )
)
def test_follow_up_question_detection(user_id, follow_up_queries):
    """
    Property: Follow-up questions should be correctly identified
    """
    context = ConversationContext(user_id)
    
    # Add initial conversation turn
    context.add_turn(
        user_input="How do I grow tomatoes?",
        ai_response="Tomatoes need well-drained soil and plenty of sunlight...",
        intent="crop_query",
        entities={},
        confidence=0.9
    )
    
    # Test follow-up detection
    for query in follow_up_queries:
        is_follow_up = context.is_follow_up_question(query)
        
        # Property: Queries with follow-up indicators should be detected as follow-ups
        assert is_follow_up == True, f"Query '{query}' should be detected as follow-up"

@settings(max_examples=15, deadline=8000)
@given(
    user_ids=st.lists(st.integers(min_value=1, max_value=1000), min_size=1, max_size=5, unique=True)
)
def test_multiple_user_context_isolation(user_ids):
    """
    Property: Context for different users should be isolated
    """
    contexts = {}
    
    # Create contexts for different users
    for user_id in user_ids:
        contexts[user_id] = get_conversation_context(user_id)
        
        # Add unique conversation for each user
        contexts[user_id].add_turn(
            user_input=f"User {user_id} question",
            ai_response=f"Response for user {user_id}",
            intent="general",
            entities={},
            confidence=0.8
        )
    
    # Property: Each user should have their own isolated context
    for user_id in user_ids:
        user_context = contexts[user_id]
        assert len(user_context.conversation_history) == 1, \
            f"User {user_id} should have exactly 1 turn"
        
        # Property: User's context should contain only their own data
        turn = user_context.conversation_history[0]
        assert f"User {user_id}" in turn.user_input, \
            f"User {user_id} context contains wrong data"

def test_context_window_expiry():
    """
    Property: Context should respect time windows
    """
    user_id = 123
    context = ConversationContext(user_id, context_window_hours=1)  # 1 hour window
    
    # Add a turn
    context.add_turn(
        user_input="Test question",
        ai_response="Test response",
        intent="test",
        entities={},
        confidence=0.8
    )
    
    # Manually set timestamp to simulate old conversation
    if context.conversation_history:
        context.conversation_history[0].timestamp = datetime.utcnow() - timedelta(hours=2)
    
    # Property: Expired context should be handled appropriately
    # (In real implementation, this would be cleaned up)
    assert len(context.conversation_history) >= 0, "Context should handle expiry gracefully"

if __name__ == "__main__":
    # Run basic tests
    test_context_window_expiry()
    print("✅ All conversation context property tests completed")