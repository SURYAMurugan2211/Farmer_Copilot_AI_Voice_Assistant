import os
from typing import List, Dict

def ingest_chunks(chunks: List[Dict]) -> Dict:
    """
    Ingest document chunks into Weaviate or fallback storage
    
    Args:
        chunks: List of chunk dictionaries from chunk_and_meta.py
    
    Returns:
        Dictionary with ingestion results
    """
    try:
        # Try Weaviate ingestion
        return _ingest_to_weaviate(chunks)
    except Exception as e:
        print(f"Weaviate ingestion failed: {e}")
        # Fallback to local storage
        return _ingest_to_fallback(chunks)

def _ingest_to_weaviate(chunks: List[Dict]) -> Dict:
    """Ingest chunks to Weaviate database"""
    try:
        import weaviate
        from sentence_transformers import SentenceTransformer
        
        # Initialize Weaviate client (new v4 syntax)
        client = weaviate.connect_to_local(host=os.getenv("WEAVIATE_URL", "http://localhost:8080"))
        embed = SentenceTransformer(os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2"))
        
        # Create collection if it doesn't exist
        if not client.collections.exists("DocChunk"):
            client.collections.create(
                name="DocChunk",
                vectorizer_config=weaviate.classes.config.Configure.Vectorizer.none(),
                properties=[
                    weaviate.classes.config.Property(name="text", data_type=weaviate.classes.config.DataType.TEXT),
                    weaviate.classes.config.Property(name="source", data_type=weaviate.classes.config.DataType.TEXT),
                    weaviate.classes.config.Property(name="title", data_type=weaviate.classes.config.DataType.TEXT),
                    weaviate.classes.config.Property(name="category", data_type=weaviate.classes.config.DataType.TEXT),
                    weaviate.classes.config.Property(name="language", data_type=weaviate.classes.config.DataType.TEXT),
                    weaviate.classes.config.Property(name="chunk_index", data_type=weaviate.classes.config.DataType.INT),
                ]
            )
        
        collection = client.collections.get("DocChunk")
        
        # Ingest chunks
        ingested_count = 0
        for chunk in chunks:
            try:
                vector = embed.encode(chunk["text"]).tolist()
                
                collection.data.insert(
                    properties={
                        "text": chunk["text"],
                        "source": chunk["metadata"].get("filename", "unknown"),
                        "title": chunk["metadata"].get("title", ""),
                        "category": chunk["metadata"].get("category", "general"),
                        "language": chunk["metadata"].get("language", "en"),
                        "chunk_index": chunk["chunk_index"]
                    },
                    vector=vector
                )
                ingested_count += 1
                
            except Exception as e:
                print(f"Error ingesting chunk {chunk.get('id', 'unknown')}: {e}")
        
        client.close()
        
        return {
            "status": "success",
            "chunks_processed": ingested_count,
            "total_chunks": len(chunks),
            "storage": "weaviate"
        }
        
    except ImportError:
        raise Exception("Weaviate client not available")
    except Exception as e:
        raise Exception(f"Weaviate ingestion error: {e}")

def _ingest_to_fallback(chunks: List[Dict]) -> Dict:
    """Fallback ingestion to local file storage"""
    try:
        import json
        
        fallback_dir = "storage/fallback_knowledge"
        os.makedirs(fallback_dir, exist_ok=True)
        
        # Save chunks to JSON file
        filename = f"chunks_{chunks[0]['metadata'].get('file_id', 'unknown')}.json"
        filepath = os.path.join(fallback_dir, filename)
        
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(chunks, f, indent=2, ensure_ascii=False)
        
        return {
            "status": "fallback",
            "chunks_processed": len(chunks),
            "total_chunks": len(chunks),
            "storage": "local_file",
            "file_path": filepath
        }
        
    except Exception as e:
        return {
            "status": "error",
            "chunks_processed": 0,
            "total_chunks": len(chunks),
            "error": str(e)
        }

def ingest_sample_data():
    """Ingest sample agricultural data"""
    ingestion = WeaviateIngestion()
    
    sample_docs = [
        {
            "text": "Rice cultivation requires well-drained soil with pH between 5.5-7.0. Plant during monsoon season for best results.",
            "title": "Rice Cultivation Guide",
            "category": "crops",
            "language": "en",
            "source": "agriculture_handbook.pdf"
        },
        {
            "text": "Urea fertilizer should be applied in split doses - 50% at planting, 25% at tillering, 25% at panicle initiation.",
            "title": "Fertilizer Application",
            "category": "fertilizers", 
            "language": "en",
            "source": "fertilizer_guide.pdf"
        },
        {
            "text": "Current market price for onions in Chennai mandi is ₹25-30 per kg. Quality grade A commands premium prices.",
            "title": "Market Prices Update",
            "category": "market",
            "language": "en", 
            "source": "market_report.pdf"
        }
    ]
    
    ingestion.ingest_documents(sample_docs)
    print("✅ Sample data ingested successfully!")

if __name__ == "__main__":
    ingest_sample_data()