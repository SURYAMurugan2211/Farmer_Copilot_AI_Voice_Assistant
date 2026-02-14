import hashlib
import json
import time
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta
import os

class SmartCache:
    """Intelligent caching system for AI responses and computations"""
    
    def __init__(self, cache_dir: str = "storage/cache", max_age_hours: int = 24):
        self.cache_dir = cache_dir
        self.max_age_hours = max_age_hours
        os.makedirs(cache_dir, exist_ok=True)
        
        # In-memory cache for frequently accessed items
        self.memory_cache: Dict[str, Dict[str, Any]] = {}
        self.cache_stats = {
            "hits": 0,
            "misses": 0,
            "memory_hits": 0,
            "disk_hits": 0
        }
    
    def _generate_cache_key(self, query: str, context: str = "", language: str = "en") -> str:
        """Generate a unique cache key for the query"""
        cache_input = f"{query.lower().strip()}|{context}|{language}"
        return hashlib.md5(cache_input.encode()).hexdigest()
    
    def _get_cache_file_path(self, cache_key: str) -> str:
        """Get the file path for a cache key"""
        return os.path.join(self.cache_dir, f"{cache_key}.json")
    
    def _is_cache_valid(self, cache_data: Dict[str, Any]) -> bool:
        """Check if cached data is still valid"""
        if "timestamp" not in cache_data:
            return False
        
        cache_time = datetime.fromisoformat(cache_data["timestamp"])
        expiry_time = cache_time + timedelta(hours=self.max_age_hours)
        
        return datetime.utcnow() < expiry_time
    
    def get_cached_response(self, query: str, context: str = "", language: str = "en") -> Optional[Dict[str, Any]]:
        """Get cached response if available and valid"""
        cache_key = self._generate_cache_key(query, context, language)
        
        # Check memory cache first
        if cache_key in self.memory_cache:
            cache_data = self.memory_cache[cache_key]
            if self._is_cache_valid(cache_data):
                self.cache_stats["hits"] += 1
                self.cache_stats["memory_hits"] += 1
                return cache_data["response"]
            else:
                # Remove expired cache
                del self.memory_cache[cache_key]
        
        # Check disk cache
        cache_file = self._get_cache_file_path(cache_key)
        if os.path.exists(cache_file):
            try:
                with open(cache_file, 'r', encoding='utf-8') as f:
                    cache_data = json.load(f)
                
                if self._is_cache_valid(cache_data):
                    # Move to memory cache for faster access
                    self.memory_cache[cache_key] = cache_data
                    self.cache_stats["hits"] += 1
                    self.cache_stats["disk_hits"] += 1
                    return cache_data["response"]
                else:
                    # Remove expired cache file
                    os.remove(cache_file)
            except Exception as e:
                print(f"Error reading cache file {cache_file}: {e}")
        
        self.cache_stats["misses"] += 1
        return None
    
    def cache_response(self, query: str, response: Dict[str, Any], context: str = "", language: str = "en"):
        """Cache a response"""
        cache_key = self._generate_cache_key(query, context, language)
        
        cache_data = {
            "query": query,
            "response": response,
            "context": context,
            "language": language,
            "timestamp": datetime.utcnow().isoformat(),
            "access_count": 1
        }
        
        # Store in memory cache
        self.memory_cache[cache_key] = cache_data
        
        # Store in disk cache
        cache_file = self._get_cache_file_path(cache_key)
        try:
            with open(cache_file, 'w', encoding='utf-8') as f:
                json.dump(cache_data, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"Error writing cache file {cache_file}: {e}")
    
    def get_similar_queries(self, query: str, threshold: float = 0.8) -> List[Dict[str, Any]]:
        """Find similar cached queries (simple implementation)"""
        similar_queries = []
        query_words = set(query.lower().split())
        
        # Check memory cache
        for cache_key, cache_data in self.memory_cache.items():
            if not self._is_cache_valid(cache_data):
                continue
            
            cached_query = cache_data["query"]
            cached_words = set(cached_query.lower().split())
            
            # Simple Jaccard similarity
            intersection = len(query_words.intersection(cached_words))
            union = len(query_words.union(cached_words))
            
            if union > 0:
                similarity = intersection / union
                if similarity >= threshold:
                    similar_queries.append({
                        "query": cached_query,
                        "similarity": similarity,
                        "response": cache_data["response"]
                    })
        
        return sorted(similar_queries, key=lambda x: x["similarity"], reverse=True)
    
    def cleanup_expired_cache(self):
        """Remove expired cache entries"""
        expired_keys = []
        
        # Clean memory cache
        for cache_key, cache_data in self.memory_cache.items():
            if not self._is_cache_valid(cache_data):
                expired_keys.append(cache_key)
        
        for key in expired_keys:
            del self.memory_cache[key]
        
        # Clean disk cache
        if os.path.exists(self.cache_dir):
            for filename in os.listdir(self.cache_dir):
                if filename.endswith('.json'):
                    filepath = os.path.join(self.cache_dir, filename)
                    try:
                        with open(filepath, 'r', encoding='utf-8') as f:
                            cache_data = json.load(f)
                        
                        if not self._is_cache_valid(cache_data):
                            os.remove(filepath)
                    except Exception as e:
                        print(f"Error processing cache file {filepath}: {e}")
        
        print(f"Cleaned up {len(expired_keys)} expired cache entries")
    
    def get_cache_stats(self) -> Dict[str, Any]:
        """Get cache performance statistics"""
        total_requests = self.cache_stats["hits"] + self.cache_stats["misses"]
        hit_rate = (self.cache_stats["hits"] / total_requests * 100) if total_requests > 0 else 0
        
        return {
            "total_requests": total_requests,
            "cache_hits": self.cache_stats["hits"],
            "cache_misses": self.cache_stats["misses"],
            "hit_rate_percent": round(hit_rate, 2),
            "memory_hits": self.cache_stats["memory_hits"],
            "disk_hits": self.cache_stats["disk_hits"],
            "memory_cache_size": len(self.memory_cache),
            "disk_cache_files": len([f for f in os.listdir(self.cache_dir) if f.endswith('.json')]) if os.path.exists(self.cache_dir) else 0
        }
    
    def clear_cache(self):
        """Clear all cache data"""
        self.memory_cache.clear()
        
        if os.path.exists(self.cache_dir):
            for filename in os.listdir(self.cache_dir):
                if filename.endswith('.json'):
                    os.remove(os.path.join(self.cache_dir, filename))
        
        self.cache_stats = {"hits": 0, "misses": 0, "memory_hits": 0, "disk_hits": 0}
        print("Cache cleared successfully")

# Global cache instance
smart_cache = SmartCache()

class CachedResponseGenerator:
    """Response generator with intelligent caching"""
    
    @staticmethod
    def get_or_generate_response(query: str, context: str, language: str, generator_func) -> Dict[str, Any]:
        """Get cached response or generate new one"""
        
        # Try to get from cache first
        cached_response = smart_cache.get_cached_response(query, context, language)
        if cached_response:
            cached_response["from_cache"] = True
            return cached_response
        
        # Generate new response
        start_time = time.time()
        response = generator_func(query, context, language)
        processing_time = time.time() - start_time
        
        # Add metadata
        response["from_cache"] = False
        response["processing_time"] = round(processing_time, 2)
        response["generated_at"] = datetime.utcnow().isoformat()
        
        # Cache the response
        smart_cache.cache_response(query, response, context, language)
        
        return response