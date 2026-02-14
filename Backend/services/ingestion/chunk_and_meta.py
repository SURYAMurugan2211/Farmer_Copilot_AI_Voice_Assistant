from typing import List, Dict, Any
import uuid

def chunk_text(text: str, metadata: Dict[str, Any], chunk_size: int = 1000, overlap: int = 200) -> List[Dict[str, Any]]:
    """
    Split text into chunks with metadata
    
    Args:
        text: The text to chunk
        metadata: Metadata to attach to each chunk
        chunk_size: Maximum size of each chunk
        overlap: Number of characters to overlap between chunks
    
    Returns:
        List of chunks with metadata
    """
    if not text or not text.strip():
        return []
    
    chunks = []
    text = text.strip()
    
    # Simple sentence-aware chunking
    sentences = text.split('. ')
    current_chunk = ""
    
    for sentence in sentences:
        # Add sentence to current chunk
        test_chunk = current_chunk + sentence + ". "
        
        if len(test_chunk) <= chunk_size:
            current_chunk = test_chunk
        else:
            # Save current chunk if it has content
            if current_chunk.strip():
                chunks.append({
                    "id": str(uuid.uuid4()),
                    "text": current_chunk.strip(),
                    "metadata": metadata.copy(),
                    "chunk_index": len(chunks),
                    "char_count": len(current_chunk)
                })
            
            # Start new chunk with overlap
            if overlap > 0 and current_chunk:
                # Take last part of current chunk as overlap
                overlap_text = current_chunk[-overlap:] if len(current_chunk) > overlap else current_chunk
                current_chunk = overlap_text + sentence + ". "
            else:
                current_chunk = sentence + ". "
    
    # Add final chunk
    if current_chunk.strip():
        chunks.append({
            "id": str(uuid.uuid4()),
            "text": current_chunk.strip(),
            "metadata": metadata.copy(),
            "chunk_index": len(chunks),
            "char_count": len(current_chunk)
        })
    
    return chunks