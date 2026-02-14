from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
from collections import defaultdict, Counter
import json
import os
from services.db.user_service import QueryService, UserService, FeedbackService
from services.db.session import get_db_session
from services.db.models import Query, User, Feedback
from sqlalchemy import func, desc

class UsageAnalytics:
    """Advanced analytics for Farmer Copilot usage patterns"""
    
    def __init__(self):
        self.analytics_cache = {}
        self.cache_expiry = timedelta(minutes=15)  # Cache analytics for 15 minutes
    
    def _get_cached_or_compute(self, cache_key: str, compute_func) -> Any:
        """Get cached analytics or compute new ones"""
        now = datetime.utcnow()
        
        if cache_key in self.analytics_cache:
            cached_data, timestamp = self.analytics_cache[cache_key]
            if now - timestamp < self.cache_expiry:
                return cached_data
        
        # Compute new data
        result = compute_func()
        self.analytics_cache[cache_key] = (result, now)
        return result
    
    def get_user_engagement_metrics(self, days: int = 7) -> Dict[str, Any]:
        """Get user engagement metrics for the last N days"""
        def compute():
            db = get_db_session()
            try:
                cutoff_date = datetime.utcnow() - timedelta(days=days)
                
                # Total active users
                active_users = db.query(User.id).join(Query).filter(
                    Query.created_at >= cutoff_date
                ).distinct().count()
                
                # Total queries
                total_queries = db.query(Query).filter(
                    Query.created_at >= cutoff_date
                ).count()
                
                # Average queries per user
                avg_queries_per_user = total_queries / active_users if active_users > 0 else 0
                
                # New users
                new_users = db.query(User).filter(
                    User.created_at >= cutoff_date
                ).count()
                
                # Returning users (users with queries in multiple days)
                returning_users_query = db.query(Query.user_id).filter(
                    Query.created_at >= cutoff_date
                ).group_by(Query.user_id, func.date(Query.created_at)).having(
                    func.count(func.distinct(func.date(Query.created_at))) > 1
                ).distinct().count()
                
                return {
                    "period_days": days,
                    "active_users": active_users,
                    "new_users": new_users,
                    "returning_users": returning_users_query,
                    "total_queries": total_queries,
                    "avg_queries_per_user": round(avg_queries_per_user, 2),
                    "user_retention_rate": round((returning_users_query / active_users * 100) if active_users > 0 else 0, 2)
                }
            finally:
                db.close()
        
        return self._get_cached_or_compute(f"engagement_{days}d", compute)
    
    def get_query_analytics(self, days: int = 7) -> Dict[str, Any]:
        """Get query analytics and patterns"""
        def compute():
            db = get_db_session()
            try:
                cutoff_date = datetime.utcnow() - timedelta(days=days)
                
                # Most common intents
                intent_counts = db.query(Query.intent, func.count(Query.id)).filter(
                    Query.created_at >= cutoff_date,
                    Query.intent.isnot(None)
                ).group_by(Query.intent).order_by(desc(func.count(Query.id))).limit(10).all()
                
                # Language distribution
                language_counts = db.query(Query.language, func.count(Query.id)).filter(
                    Query.created_at >= cutoff_date
                ).group_by(Query.language).order_by(desc(func.count(Query.id))).all()
                
                # Average processing time
                avg_processing_time = db.query(func.avg(Query.processing_time)).filter(
                    Query.created_at >= cutoff_date,
                    Query.processing_time.isnot(None)
                ).scalar() or 0
                
                # Peak usage hours
                hourly_usage = db.query(
                    func.extract('hour', Query.created_at).label('hour'),
                    func.count(Query.id).label('count')
                ).filter(
                    Query.created_at >= cutoff_date
                ).group_by(func.extract('hour', Query.created_at)).order_by('hour').all()
                
                return {
                    "period_days": days,
                    "top_intents": [{"intent": intent, "count": count} for intent, count in intent_counts],
                    "language_distribution": [{"language": lang, "count": count} for lang, count in language_counts],
                    "avg_processing_time_seconds": round(avg_processing_time, 2),
                    "hourly_usage_pattern": [{"hour": int(hour), "queries": count} for hour, count in hourly_usage]
                }
            finally:
                db.close()
        
        return self._get_cached_or_compute(f"queries_{days}d", compute)
    
    def get_performance_metrics(self, days: int = 7) -> Dict[str, Any]:
        """Get system performance metrics"""
        def compute():
            db = get_db_session()
            try:
                cutoff_date = datetime.utcnow() - timedelta(days=days)
                
                # Processing time statistics
                processing_times = db.query(Query.processing_time).filter(
                    Query.created_at >= cutoff_date,
                    Query.processing_time.isnot(None)
                ).all()
                
                times = [t.processing_time for t in processing_times if t.processing_time]
                
                if times:
                    times.sort()
                    n = len(times)
                    p50 = times[n // 2]
                    p95 = times[int(n * 0.95)]
                    p99 = times[int(n * 0.99)]
                else:
                    p50 = p95 = p99 = 0
                
                # Error rate (queries with very high processing time might indicate errors)
                error_threshold = 30  # seconds
                error_queries = db.query(Query).filter(
                    Query.created_at >= cutoff_date,
                    Query.processing_time > error_threshold
                ).count()
                
                total_queries = db.query(Query).filter(
                    Query.created_at >= cutoff_date
                ).count()
                
                error_rate = (error_queries / total_queries * 100) if total_queries > 0 else 0
                
                return {
                    "period_days": days,
                    "total_queries": total_queries,
                    "avg_processing_time": round(sum(times) / len(times), 2) if times else 0,
                    "p50_processing_time": round(p50, 2),
                    "p95_processing_time": round(p95, 2),
                    "p99_processing_time": round(p99, 2),
                    "error_rate_percent": round(error_rate, 2),
                    "slow_queries_count": error_queries
                }
            finally:
                db.close()
        
        return self._get_cached_or_compute(f"performance_{days}d", compute)
    
    def get_feedback_analytics(self, days: int = 30) -> Dict[str, Any]:
        """Get feedback and satisfaction analytics"""
        def compute():
            db = get_db_session()
            try:
                cutoff_date = datetime.utcnow() - timedelta(days=days)
                
                # Rating distribution
                rating_counts = db.query(Feedback.rating, func.count(Feedback.id)).filter(
                    Feedback.created_at >= cutoff_date
                ).group_by(Feedback.rating).order_by(Feedback.rating).all()
                
                # Average rating
                avg_rating = db.query(func.avg(Feedback.rating)).filter(
                    Feedback.created_at >= cutoff_date
                ).scalar() or 0
                
                # Helpful vs not helpful
                helpful_counts = db.query(Feedback.helpful, func.count(Feedback.id)).filter(
                    Feedback.created_at >= cutoff_date
                ).group_by(Feedback.helpful).all()
                
                # Feedback by intent
                feedback_by_intent = db.query(
                    Query.intent, 
                    func.avg(Feedback.rating).label('avg_rating'),
                    func.count(Feedback.id).label('feedback_count')
                ).join(Feedback, Query.id == Feedback.query_id).filter(
                    Feedback.created_at >= cutoff_date
                ).group_by(Query.intent).order_by(desc('avg_rating')).all()
                
                return {
                    "period_days": days,
                    "total_feedback": sum(count for _, count in rating_counts),
                    "average_rating": round(avg_rating, 2),
                    "rating_distribution": [{"rating": rating, "count": count} for rating, count in rating_counts],
                    "helpful_distribution": [{"helpful": helpful, "count": count} for helpful, count in helpful_counts],
                    "feedback_by_intent": [
                        {"intent": intent, "avg_rating": round(float(avg_rating), 2), "feedback_count": count}
                        for intent, avg_rating, count in feedback_by_intent
                    ]
                }
            finally:
                db.close()
        
        return self._get_cached_or_compute(f"feedback_{days}d", compute)
    
    def get_content_analytics(self, days: int = 7) -> Dict[str, Any]:
        """Get content and topic analytics"""
        def compute():
            db = get_db_session()
            try:
                cutoff_date = datetime.utcnow() - timedelta(days=days)
                
                # Most common query patterns (simplified)
                queries = db.query(Query.original_text).filter(
                    Query.created_at >= cutoff_date
                ).all()
                
                # Extract common keywords
                all_words = []
                for query in queries:
                    if query.original_text:
                        words = query.original_text.lower().split()
                        # Filter out common stop words
                        stop_words = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'is', 'are', 'was', 'were', 'how', 'what', 'when', 'where', 'why', 'can', 'do', 'does', 'did', 'will', 'would', 'should', 'could', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'my', 'your', 'his', 'her', 'its', 'our', 'their'}
                        filtered_words = [word for word in words if word not in stop_words and len(word) > 2]
                        all_words.extend(filtered_words)
                
                # Count word frequency
                word_counts = Counter(all_words)
                top_keywords = word_counts.most_common(20)
                
                return {
                    "period_days": days,
                    "total_queries_analyzed": len(queries),
                    "top_keywords": [{"keyword": word, "frequency": count} for word, count in top_keywords],
                    "unique_keywords": len(word_counts),
                    "avg_query_length": round(sum(len(q.original_text.split()) for q in queries if q.original_text) / len(queries), 2) if queries else 0
                }
            finally:
                db.close()
        
        return self._get_cached_or_compute(f"content_{days}d", compute)
    
    def get_comprehensive_dashboard(self, days: int = 7) -> Dict[str, Any]:
        """Get comprehensive analytics dashboard"""
        return {
            "generated_at": datetime.utcnow().isoformat(),
            "period_days": days,
            "user_engagement": self.get_user_engagement_metrics(days),
            "query_analytics": self.get_query_analytics(days),
            "performance_metrics": self.get_performance_metrics(days),
            "feedback_analytics": self.get_feedback_analytics(days),
            "content_analytics": self.get_content_analytics(days)
        }
    
    def export_analytics_report(self, days: int = 7, output_dir: str = "storage/reports") -> str:
        """Export comprehensive analytics report to JSON file"""
        os.makedirs(output_dir, exist_ok=True)
        
        report = self.get_comprehensive_dashboard(days)
        
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        filename = f"farmer_copilot_analytics_{timestamp}.json"
        filepath = os.path.join(output_dir, filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        return filepath
    
    def clear_cache(self):
        """Clear analytics cache"""
        self.analytics_cache.clear()

# Global analytics instance
usage_analytics = UsageAnalytics()