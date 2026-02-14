from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional, List
from sqlalchemy.orm import Session

from services.db.session import get_db
from services.db.user_service import UserService, QueryService, FeedbackService
from services.db.models import User, Query

router = APIRouter()

class UserCreate(BaseModel):
    phone_number: str
    name: Optional[str] = None
    language: str = "en"
    location: Optional[str] = None

class UserResponse(BaseModel):
    id: int
    phone_number: str
    name: str
    language: str
    location: Optional[str]
    created_at: str
    
    class Config:
        from_attributes = True

class QueryResponse(BaseModel):
    id: int
    original_text: str
    response_text: str
    intent: Optional[str]
    confidence: Optional[float]
    language: str
    audio_url: Optional[str]
    processing_time: Optional[float]
    created_at: str
    
    class Config:
        from_attributes = True

class FeedbackCreate(BaseModel):
    query_id: int
    rating: int  # 1-5
    helpful: bool
    comment: Optional[str] = None

@router.post("/register", response_model=UserResponse)
async def register_user(user_data: UserCreate):
    """Register a new user or get existing user"""
    try:
        user = UserService.create_or_get_user(
            phone_number=user_data.phone_number,
            name=user_data.name,
            language=user_data.language,
            location=user_data.location
        )
        
        return UserResponse(
            id=user.id,
            phone_number=user.phone_number,
            name=user.name,
            language=user.language,
            location=user.location,
            created_at=user.created_at.isoformat()
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"User registration failed: {str(e)}")

@router.get("/profile/{user_id}", response_model=UserResponse)
async def get_user_profile(user_id: int):
    """Get user profile by ID"""
    user = UserService.get_user_by_id(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return UserResponse(
        id=user.id,
        phone_number=user.phone_number,
        name=user.name,
        language=user.language,
        location=user.location,
        created_at=user.created_at.isoformat()
    )

@router.get("/phone/{phone_number}", response_model=UserResponse)
async def get_user_by_phone(phone_number: str):
    """Get user by phone number"""
    user = UserService.get_user_by_phone(phone_number)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return UserResponse(
        id=user.id,
        phone_number=user.phone_number,
        name=user.name,
        language=user.language,
        location=user.location,
        created_at=user.created_at.isoformat()
    )

@router.put("/language/{user_id}")
async def update_user_language(user_id: int, language: str):
    """Update user's preferred language"""
    success = UserService.update_user_language(user_id, language)
    if not success:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {"success": True, "message": f"Language updated to {language}"}

@router.get("/queries/{user_id}", response_model=List[QueryResponse])
async def get_user_queries(user_id: int, limit: int = 10):
    """Get user's recent queries"""
    queries = QueryService.get_user_queries(user_id, limit)
    
    return [
        QueryResponse(
            id=q.id,
            original_text=q.original_text,
            response_text=q.response_text,
            intent=q.intent,
            confidence=q.confidence,
            language=q.language,
            audio_url=q.audio_url,
            processing_time=q.processing_time,
            created_at=q.created_at.isoformat()
        ) for q in queries
    ]

@router.get("/stats/{user_id}")
async def get_user_stats(user_id: int):
    """Get user statistics"""
    try:
        stats = QueryService.get_user_stats(user_id)
        return {
            "success": True,
            "user_id": user_id,
            "stats": stats
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get stats: {str(e)}")

@router.post("/feedback")
async def submit_feedback(feedback: FeedbackCreate):
    """Submit feedback for a query"""
    try:
        # Verify query exists
        query = QueryService.get_query_by_id(feedback.query_id)
        if not query:
            raise HTTPException(status_code=404, detail="Query not found")
        
        # Save feedback
        saved_feedback = FeedbackService.save_feedback(
            query_id=feedback.query_id,
            user_id=query.user_id,
            rating=feedback.rating,
            helpful=feedback.helpful,
            comment=feedback.comment
        )
        
        return {
            "success": True,
            "feedback_id": saved_feedback.id,
            "message": "Feedback submitted successfully"
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to submit feedback: {str(e)}")

@router.get("/feedback/average")
async def get_average_rating():
    """Get average rating across all feedback"""
    try:
        avg_rating = FeedbackService.get_average_rating()
        return {
            "average_rating": round(avg_rating, 2),
            "total_feedback_count": "Available on request"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get average rating: {str(e)}")

@router.delete("/user/{user_id}")
async def delete_user(user_id: int):
    """Delete user and all associated data (GDPR compliance)"""
    # This is a placeholder - implement based on your privacy policy
    return {
        "message": "User deletion requested. This feature requires additional implementation for GDPR compliance."
    }