"""
Database Models — SQLAlchemy ORM models for all tables.
Stores users, queries (with audio paths), documents, and feedback.
"""

from sqlalchemy import Column, Integer, String, Text, DateTime, Float, Boolean, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from datetime import datetime

Base = declarative_base()


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    phone_number = Column(String(15), unique=True, index=True)
    name = Column(String(100))
    language = Column(String(10), default="en")
    location = Column(String(100))
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    queries = relationship("Query", back_populates="user")


class Query(Base):
    __tablename__ = "queries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))

    # --- Input ---
    original_text = Column(Text)          # User's spoken/typed text (original language)
    translated_text = Column(Text)        # English translation of user's input
    input_audio_url = Column(String(300)) # Path to user's voice recording (saved WAV/MP3)

    # --- NLU ---
    intent = Column(String(50))           # pest_control, fertilizer, market_query, etc.
    confidence = Column(Float)
    detected_language = Column(String(10))  # Auto-detected language code

    # --- Response ---
    response_text = Column(Text)          # AI response in user's language
    response_text_en = Column(Text)       # AI response in English (for analytics)
    response_audio_url = Column(String(300))  # Path to TTS audio response (MP3)

    # --- Metadata ---
    language = Column(String(10))         # User's preferred language
    processing_time = Column(Float)       # Pipeline processing time (seconds)
    source_count = Column(Integer)        # Number of RAG sources used
    query_type = Column(String(20))       # "voice" or "text"
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="queries")
    feedback = relationship("Feedback", back_populates="query", uselist=False)


class Document(Base):
    __tablename__ = "documents"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200))
    content = Column(Text)
    source = Column(String(200))
    language = Column(String(10))
    category = Column(String(50))

    # Vector store metadata
    weaviate_id = Column(String(100))
    embedding_model = Column(String(100))

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Feedback(Base):
    __tablename__ = "feedback"

    id = Column(Integer, primary_key=True, index=True)
    query_id = Column(Integer, ForeignKey("queries.id"))
    user_id = Column(Integer, ForeignKey("users.id"))

    rating = Column(Integer)        # 1-5 stars
    helpful = Column(Boolean)       # Was the response helpful?
    comment = Column(Text)

    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    query = relationship("Query", back_populates="feedback")