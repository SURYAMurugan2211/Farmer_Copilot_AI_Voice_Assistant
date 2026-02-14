from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from services.api.routes import asr_route, ask_route, tts_route, mobile_route, documents_route, users_route, analytics_route
import os

app = FastAPI(title="Farmer Copilot API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Ensure audio directory exists
audio_dir = os.path.abspath("storage/audio")
os.makedirs(audio_dir, exist_ok=True)

# Mount static files for audio serving
app.mount("/audio", StaticFiles(directory=audio_dir), name="audio")

# Register routers
app.include_router(asr_route.router, prefix="/api/asr", tags=["ASR"])
app.include_router(ask_route.router, prefix="/api/ask", tags=["Assistant"])
app.include_router(tts_route.router, prefix="/api/tts", tags=["TTS"])
app.include_router(mobile_route.router, prefix="/api/mobile", tags=["Mobile"])
app.include_router(documents_route.router, prefix="/api/documents", tags=["Documents"])
app.include_router(users_route.router, prefix="/api/users", tags=["Users"])
app.include_router(analytics_route.router, prefix="/api/analytics", tags=["Analytics"])

@app.get("/")
def root():
    return {
        "message": "Farmer Copilot API",
        "status": "running",
        "version": "2.0.0",
        "endpoints": {
            "health": "/health",
            "asr": "/api/asr",
            "ask": "/api/ask",
            "tts": "/api/tts",
            "mobile": "/api/mobile",
            "documents": "/api/documents",
            "users": "/api/users",
            "analytics": "/api/analytics",
            "docs": "/docs"
        },
        "features": [
            "voice_to_voice_queries",
            "multi_language_support", 
            "document_upload",
            "semantic_search",
            "local_llm_processing",
            "user_management",
            "query_history",
            "feedback_system",
            "conversation_context",
            "smart_caching",
            "advanced_analytics",
            "performance_monitoring"
        ]
    }

@app.get("/health")
def health():
    """Comprehensive health check for all system components"""
    from services.db.session import get_db_session
    from services.ai.smart_cache import smart_cache
    import time
    
    health_status = {
        "status": "healthy",
        "timestamp": time.time(),
        "version": "2.0.0",
        "services": {}
    }
    
    # Check database connection
    try:
        from sqlalchemy import text
        db = get_db_session()
        db.execute(text("SELECT 1"))
        db.close()
        health_status["services"]["database"] = {"status": "healthy", "type": "SQLite/PostgreSQL"}
    except Exception as e:
        health_status["services"]["database"] = {"status": "unhealthy", "error": str(e)}
        health_status["status"] = "degraded"
    
    # Check AI services
    try:
        from services.asr.asr_service import transcribe
        health_status["services"]["asr"] = {"status": "healthy", "type": "Whisper"}
    except Exception as e:
        health_status["services"]["asr"] = {"status": "unhealthy", "error": str(e)}
        health_status["status"] = "degraded"
    
    try:
        from services.tts.tts_service import synthesize_tts
        health_status["services"]["tts"] = {"status": "healthy", "type": "gTTS"}
    except Exception as e:
        health_status["services"]["tts"] = {"status": "unhealthy", "error": str(e)}
        health_status["status"] = "degraded"
    
    try:
        from services.rag.retriever import semantic_search
        health_status["services"]["retriever"] = {"status": "healthy", "type": "Weaviate + SentenceTransformers"}
    except Exception as e:
        health_status["services"]["retriever"] = {"status": "unhealthy", "error": str(e)}
        health_status["status"] = "degraded"
    
    try:
        from services.translate.translator import translate
        health_status["services"]["translator"] = {"status": "healthy", "type": "Multi-language"}
    except Exception as e:
        health_status["services"]["translator"] = {"status": "unhealthy", "error": str(e)}
        health_status["status"] = "degraded"
    
    # Check cache
    try:
        cache_stats = smart_cache.get_cache_stats()
        health_status["services"]["cache"] = {
            "status": "healthy", 
            "type": "Smart Cache",
            "stats": cache_stats
        }
    except Exception as e:
        health_status["services"]["cache"] = {"status": "unhealthy", "error": str(e)}
        health_status["status"] = "degraded"
    
    # Check conversation context
    try:
        from services.ai.conversation_context import get_conversation_context
        health_status["services"]["context"] = {"status": "healthy", "type": "Conversation Memory"}
    except Exception as e:
        health_status["services"]["context"] = {"status": "unhealthy", "error": str(e)}
        health_status["status"] = "degraded"
    
    return health_status
