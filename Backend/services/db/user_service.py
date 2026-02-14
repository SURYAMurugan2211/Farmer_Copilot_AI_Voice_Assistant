"""
Database Service Layer — CRUD operations for Users, Queries, Feedback, Documents.
All audio files are stored on disk; only file paths are saved in the database.
"""

from sqlalchemy.orm import Session
from sqlalchemy import desc, func
from typing import Optional, List, Dict, Any
from datetime import datetime, timedelta

from .models import User, Query, Document, Feedback
from .session import get_db_session


class UserService:
    """Service for managing users."""

    @staticmethod
    def create_or_get_user(phone_number: str, name: str = None,
                           language: str = "en", location: str = None) -> User:
        """Create a new user or get existing user by phone number."""
        db = get_db_session()
        try:
            user = db.query(User).filter(User.phone_number == phone_number).first()

            if user:
                if name:
                    user.name = name
                if language:
                    user.language = language
                if location:
                    user.location = location
                db.commit()
                db.refresh(user)
                return user

            user = User(
                phone_number=phone_number,
                name=name or f"User_{phone_number[-4:]}",
                language=language,
                location=location,
            )
            db.add(user)
            db.commit()
            db.refresh(user)
            return user
        finally:
            db.close()

    @staticmethod
    def get_user_by_id(user_id: int) -> Optional[User]:
        db = get_db_session()
        try:
            return db.query(User).filter(User.id == user_id).first()
        finally:
            db.close()

    @staticmethod
    def get_user_by_phone(phone_number: str) -> Optional[User]:
        db = get_db_session()
        try:
            return db.query(User).filter(User.phone_number == phone_number).first()
        finally:
            db.close()

    @staticmethod
    def update_user_language(user_id: int, language: str) -> bool:
        db = get_db_session()
        try:
            user = db.query(User).filter(User.id == user_id).first()
            if user:
                user.language = language
                db.commit()
                return True
            return False
        finally:
            db.close()


class QueryService:
    """Service for managing user queries and responses."""

    @staticmethod
    def save_query(
        user_id: int,
        original_text: str,
        translated_text: str,
        intent: str,
        confidence: float,
        response_text: str,
        response_text_en: str = None,
        input_audio_url: str = None,
        response_audio_url: str = None,
        language: str = "en",
        detected_language: str = None,
        processing_time: float = 0.0,
        source_count: int = 0,
        query_type: str = "text",
        # Legacy parameter — maps to response_audio_url
        audio_url: str = None,
    ) -> Query:
        """
        Save a complete user query with all pipeline data.

        Args:
            user_id: User who made the query
            original_text: User's original input (in their language)
            translated_text: English translation of input
            intent: Detected intent (pest_control, fertilizer, etc.)
            confidence: Intent detection confidence
            response_text: AI response in user's language
            response_text_en: AI response in English (for analytics)
            input_audio_url: Path to saved user voice recording
            response_audio_url: Path to TTS response audio
            language: User's preferred language code
            detected_language: Auto-detected language from input
            processing_time: Total pipeline processing time
            source_count: Number of RAG sources retrieved
            query_type: "voice" or "text"
            audio_url: Legacy param (mapped to response_audio_url)
        """
        # Handle legacy audio_url parameter
        if audio_url and not response_audio_url:
            response_audio_url = audio_url

        db = get_db_session()
        try:
            query = Query(
                user_id=user_id,
                original_text=original_text,
                translated_text=translated_text,
                input_audio_url=input_audio_url,
                intent=intent,
                confidence=confidence,
                detected_language=detected_language or language,
                response_text=response_text,
                response_text_en=response_text_en,
                response_audio_url=response_audio_url,
                language=language,
                processing_time=processing_time,
                source_count=source_count,
                query_type=query_type,
            )
            db.add(query)
            db.commit()
            db.refresh(query)
            return query
        finally:
            db.close()

    @staticmethod
    def get_user_queries(user_id: int, limit: int = 10) -> List[Query]:
        """Get recent queries for a user."""
        db = get_db_session()
        try:
            return (
                db.query(Query)
                .filter(Query.user_id == user_id)
                .order_by(desc(Query.created_at))
                .limit(limit)
                .all()
            )
        finally:
            db.close()

    @staticmethod
    def get_query_by_id(query_id: int) -> Optional[Query]:
        db = get_db_session()
        try:
            return db.query(Query).filter(Query.id == query_id).first()
        finally:
            db.close()

    @staticmethod
    def get_user_stats(user_id: int) -> Dict[str, Any]:
        """Get user statistics."""
        db = get_db_session()
        try:
            total_queries = db.query(Query).filter(Query.user_id == user_id).count()

            week_ago = datetime.utcnow() - timedelta(days=7)
            recent_queries = (
                db.query(Query)
                .filter(Query.user_id == user_id, Query.created_at >= week_ago)
                .count()
            )

            intent_query = (
                db.query(Query.intent)
                .filter(Query.user_id == user_id)
                .all()
            )
            intents = [q.intent for q in intent_query if q.intent]
            most_common_intent = max(set(intents), key=intents.count) if intents else None

            avg_time_query = (
                db.query(Query.processing_time)
                .filter(Query.user_id == user_id, Query.processing_time.isnot(None))
                .all()
            )
            avg_processing_time = (
                sum(q.processing_time for q in avg_time_query) / len(avg_time_query)
                if avg_time_query
                else 0
            )

            # Voice vs text breakdown
            voice_count = (
                db.query(Query)
                .filter(Query.user_id == user_id, Query.query_type == "voice")
                .count()
            )
            text_count = total_queries - voice_count

            # Languages used
            lang_query = (
                db.query(Query.detected_language, func.count(Query.id))
                .filter(Query.user_id == user_id)
                .group_by(Query.detected_language)
                .all()
            )
            languages_used = {lang: count for lang, count in lang_query if lang}

            return {
                "total_queries": total_queries,
                "recent_queries": recent_queries,
                "voice_queries": voice_count,
                "text_queries": text_count,
                "most_common_intent": most_common_intent,
                "average_processing_time": round(avg_processing_time, 2),
                "languages_used": languages_used,
            }
        finally:
            db.close()

    @staticmethod
    def get_conversation_history(user_id: int, limit: int = 20) -> List[Dict[str, Any]]:
        """Get full conversation history for a user (for display in app)."""
        db = get_db_session()
        try:
            queries = (
                db.query(Query)
                .filter(Query.user_id == user_id)
                .order_by(desc(Query.created_at))
                .limit(limit)
                .all()
            )
            return [
                {
                    "id": q.id,
                    "query_type": q.query_type or "text",
                    "original_text": q.original_text,
                    "detected_language": q.detected_language,
                    "response_text": q.response_text,
                    "input_audio_url": q.input_audio_url,
                    "response_audio_url": q.response_audio_url,
                    "intent": q.intent,
                    "processing_time": q.processing_time,
                    "created_at": q.created_at.isoformat() if q.created_at else None,
                }
                for q in reversed(queries)  # Chronological order
            ]
        finally:
            db.close()


class FeedbackService:
    """Service for managing user feedback."""

    @staticmethod
    def save_feedback(query_id: int, user_id: int, rating: int,
                      helpful: bool, comment: str = None) -> Feedback:
        db = get_db_session()
        try:
            feedback = Feedback(
                query_id=query_id,
                user_id=user_id,
                rating=rating,
                helpful=helpful,
                comment=comment,
            )
            db.add(feedback)
            db.commit()
            db.refresh(feedback)
            return feedback
        finally:
            db.close()

    @staticmethod
    def get_query_feedback(query_id: int) -> Optional[Feedback]:
        db = get_db_session()
        try:
            return db.query(Feedback).filter(Feedback.query_id == query_id).first()
        finally:
            db.close()

    @staticmethod
    def get_average_rating() -> float:
        db = get_db_session()
        try:
            ratings = db.query(Feedback.rating).filter(Feedback.rating.isnot(None)).all()
            if ratings:
                return sum(r.rating for r in ratings) / len(ratings)
            return 0.0
        finally:
            db.close()


class DocumentService:
    """Service for managing ingested documents."""

    @staticmethod
    def save_document(title: str, content: str, source: str, language: str,
                      category: str, weaviate_id: str = None,
                      embedding_model: str = None) -> Document:
        db = get_db_session()
        try:
            document = Document(
                title=title,
                content=content,
                source=source,
                language=language,
                category=category,
                weaviate_id=weaviate_id,
                embedding_model=embedding_model,
            )
            db.add(document)
            db.commit()
            db.refresh(document)
            return document
        finally:
            db.close()

    @staticmethod
    def get_documents_by_category(category: str, limit: int = 10) -> List[Document]:
        db = get_db_session()
        try:
            return (
                db.query(Document)
                .filter(Document.category == category)
                .order_by(desc(Document.created_at))
                .limit(limit)
                .all()
            )
        finally:
            db.close()

    @staticmethod
    def get_document_stats() -> Dict[str, Any]:
        db = get_db_session()
        try:
            total_docs = db.query(Document).count()

            categories = (
                db.query(Document.category, func.count(Document.id))
                .group_by(Document.category)
                .all()
            )
            category_counts = {cat: count for cat, count in categories}

            languages = (
                db.query(Document.language, func.count(Document.id))
                .group_by(Document.language)
                .all()
            )
            language_counts = {lang: count for lang, count in languages}

            return {
                "total_documents": total_docs,
                "by_category": category_counts,
                "by_language": language_counts,
            }
        finally:
            db.close()