from fastapi import APIRouter, UploadFile, File, HTTPException, Form
from pydantic import BaseModel
from typing import List, Optional
import uuid
import os
import aiofiles
from services.ingestion.extract_text import extract_text_from_file
from services.ingestion.chunk_and_meta import chunk_text
from services.ingestion.ingest_to_weaviate import ingest_chunks
from services.rag.retriever import semantic_search

router = APIRouter()

UPLOAD_DIR = "storage/documents"
os.makedirs(UPLOAD_DIR, exist_ok=True)

class DocumentInfo(BaseModel):
    title: str
    description: Optional[str] = None
    category: Optional[str] = "general"
    language: str = "en"

@router.post("/upload")
async def upload_document(
    title: str = Form(...),
    description: Optional[str] = Form(None),
    category: str = Form("general"),
    language: str = Form("en"),
    file: UploadFile = File(...)
):
    """
    Upload and process agricultural documents
    Supports: PDF, TXT, DOCX files
    """
    try:
        # Validate file type
        allowed_types = [".pdf", ".txt", ".docx", ".doc"]
        file_ext = os.path.splitext(file.filename)[1].lower()
        
        if file_ext not in allowed_types:
            raise HTTPException(
                status_code=400, 
                detail=f"File type {file_ext} not supported. Allowed: {allowed_types}"
            )
        
        # Save uploaded file
        file_id = str(uuid.uuid4())
        file_path = f"{UPLOAD_DIR}/{file_id}_{file.filename}"
        
        async with aiofiles.open(file_path, "wb") as f:
            content = await file.read()
            await f.write(content)
        
        # Extract text from file
        try:
            extracted_text = extract_text_from_file(file_path)
        except Exception as e:
            # Fallback for unsupported files - read as text
            if file_ext == ".txt":
                with open(file_path, "r", encoding="utf-8") as f:
                    extracted_text = f.read()
            else:
                raise HTTPException(status_code=400, detail=f"Could not extract text: {str(e)}")
        
        # Chunk the text
        chunks = chunk_text(extracted_text, {
            "title": title,
            "description": description,
            "category": category,
            "language": language,
            "filename": file.filename,
            "file_id": file_id
        })
        
        # Try to ingest to Weaviate (fallback gracefully if not available)
        try:
            ingest_result = ingest_chunks(chunks)
            weaviate_status = "success"
        except Exception as e:
            print(f"Weaviate ingestion failed: {e}")
            weaviate_status = "fallback_mode"
            ingest_result = {"chunks_processed": len(chunks)}
        
        return {
            "success": True,
            "file_id": file_id,
            "filename": file.filename,
            "title": title,
            "chunks_created": len(chunks),
            "text_length": len(extracted_text),
            "weaviate_status": weaviate_status,
            "ingest_result": ingest_result
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Document upload failed: {str(e)}")

@router.get("/search")
async def search_documents(query: str, limit: int = 10):
    """
    Search through uploaded documents
    """
    try:
        results = semantic_search(query, k=limit)
        
        return {
            "success": True,
            "query": query,
            "results_count": len(results),
            "results": results
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Document search failed: {str(e)}")

@router.get("/categories")
async def get_document_categories():
    """
    Get available document categories
    """
    return {
        "categories": [
            {"id": "crops", "name": "Crop Management", "description": "Information about different crops and cultivation"},
            {"id": "livestock", "name": "Livestock", "description": "Animal husbandry and livestock management"},
            {"id": "soil", "name": "Soil Management", "description": "Soil health, fertilizers, and soil care"},
            {"id": "irrigation", "name": "Irrigation", "description": "Water management and irrigation systems"},
            {"id": "pests", "name": "Pest Control", "description": "Pest and disease management"},
            {"id": "organic", "name": "Organic Farming", "description": "Organic and sustainable farming practices"},
            {"id": "technology", "name": "Farm Technology", "description": "Modern farming tools and techniques"},
            {"id": "market", "name": "Market Information", "description": "Pricing, selling, and market trends"},
            {"id": "weather", "name": "Weather & Climate", "description": "Weather patterns and climate information"},
            {"id": "general", "name": "General", "description": "General agricultural information"}
        ]
    }

@router.get("/stats")
async def get_document_stats():
    """
    Get statistics about uploaded documents
    """
    try:
        # Count files in upload directory
        uploaded_files = len([f for f in os.listdir(UPLOAD_DIR) if os.path.isfile(os.path.join(UPLOAD_DIR, f))])
        
        # Test search to get knowledge base size
        test_results = semantic_search("farming", k=100)
        
        return {
            "uploaded_files": uploaded_files,
            "knowledge_base_entries": len(test_results),
            "storage_path": UPLOAD_DIR,
            "supported_formats": [".pdf", ".txt", ".docx", ".doc"]
        }
        
    except Exception as e:
        return {
            "uploaded_files": 0,
            "knowledge_base_entries": 0,
            "error": str(e)
        }