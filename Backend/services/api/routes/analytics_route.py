from fastapi import APIRouter, HTTPException, Query as QueryParam
from typing import Optional
from services.analytics.usage_analytics import usage_analytics
from services.ai.smart_cache import smart_cache
from services.ai.conversation_context import cleanup_inactive_contexts

router = APIRouter()

@router.get("/dashboard")
async def get_analytics_dashboard(days: int = QueryParam(7, ge=1, le=365)):
    """Get comprehensive analytics dashboard"""
    try:
        dashboard = usage_analytics.get_comprehensive_dashboard(days)
        return {
            "success": True,
            "dashboard": dashboard
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to generate dashboard: {str(e)}")

@router.get("/user-engagement")
async def get_user_engagement(days: int = QueryParam(7, ge=1, le=365)):
    """Get user engagement metrics"""
    try:
        metrics = usage_analytics.get_user_engagement_metrics(days)
        return {
            "success": True,
            "metrics": metrics
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get engagement metrics: {str(e)}")

@router.get("/query-analytics")
async def get_query_analytics(days: int = QueryParam(7, ge=1, le=365)):
    """Get query analytics and patterns"""
    try:
        analytics = usage_analytics.get_query_analytics(days)
        return {
            "success": True,
            "analytics": analytics
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get query analytics: {str(e)}")

@router.get("/performance")
async def get_performance_metrics(days: int = QueryParam(7, ge=1, le=365)):
    """Get system performance metrics"""
    try:
        metrics = usage_analytics.get_performance_metrics(days)
        return {
            "success": True,
            "metrics": metrics
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get performance metrics: {str(e)}")

@router.get("/feedback")
async def get_feedback_analytics(days: int = QueryParam(30, ge=1, le=365)):
    """Get feedback and satisfaction analytics"""
    try:
        analytics = usage_analytics.get_feedback_analytics(days)
        return {
            "success": True,
            "analytics": analytics
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get feedback analytics: {str(e)}")

@router.get("/content")
async def get_content_analytics(days: int = QueryParam(7, ge=1, le=365)):
    """Get content and topic analytics"""
    try:
        analytics = usage_analytics.get_content_analytics(days)
        return {
            "success": True,
            "analytics": analytics
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get content analytics: {str(e)}")

@router.get("/cache-stats")
async def get_cache_statistics():
    """Get cache performance statistics"""
    try:
        stats = smart_cache.get_cache_stats()
        return {
            "success": True,
            "cache_stats": stats
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get cache stats: {str(e)}")

@router.post("/export-report")
async def export_analytics_report(days: int = QueryParam(7, ge=1, le=365)):
    """Export comprehensive analytics report"""
    try:
        filepath = usage_analytics.export_analytics_report(days)
        return {
            "success": True,
            "message": "Analytics report exported successfully",
            "file_path": filepath,
            "period_days": days
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to export report: {str(e)}")

@router.post("/clear-cache")
async def clear_system_cache():
    """Clear system cache (admin function)"""
    try:
        smart_cache.clear_cache()
        usage_analytics.clear_cache()
        return {
            "success": True,
            "message": "System cache cleared successfully"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to clear cache: {str(e)}")

@router.post("/cleanup-contexts")
async def cleanup_conversation_contexts():
    """Clean up inactive conversation contexts"""
    try:
        cleanup_inactive_contexts()
        return {
            "success": True,
            "message": "Inactive conversation contexts cleaned up"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to cleanup contexts: {str(e)}")

@router.get("/system-health")
async def get_system_health():
    """Get comprehensive system health metrics"""
    try:
        # Get various system metrics
        cache_stats = smart_cache.get_cache_stats()
        performance_metrics = usage_analytics.get_performance_metrics(1)  # Last 24 hours
        engagement_metrics = usage_analytics.get_user_engagement_metrics(1)
        
        # Determine system health status
        health_status = "healthy"
        issues = []
        
        # Check cache hit rate
        if cache_stats["hit_rate_percent"] < 20:
            issues.append("Low cache hit rate")
        
        # Check error rate
        if performance_metrics["error_rate_percent"] > 5:
            health_status = "warning"
            issues.append("High error rate")
        
        # Check average processing time
        if performance_metrics["avg_processing_time"] > 10:
            health_status = "warning"
            issues.append("High processing time")
        
        if performance_metrics["avg_processing_time"] > 20:
            health_status = "critical"
        
        return {
            "success": True,
            "health_status": health_status,
            "issues": issues,
            "metrics": {
                "cache_performance": cache_stats,
                "system_performance": performance_metrics,
                "user_activity": engagement_metrics
            },
            "recommendations": _get_health_recommendations(cache_stats, performance_metrics)
        }
    except Exception as e:
        return {
            "success": False,
            "health_status": "error",
            "error": str(e)
        }

def _get_health_recommendations(cache_stats: dict, performance_metrics: dict) -> list:
    """Generate health recommendations based on metrics"""
    recommendations = []
    
    if cache_stats["hit_rate_percent"] < 30:
        recommendations.append("Consider increasing cache size or adjusting cache expiry time")
    
    if performance_metrics["avg_processing_time"] > 5:
        recommendations.append("Consider optimizing AI model inference or adding more compute resources")
    
    if performance_metrics["error_rate_percent"] > 2:
        recommendations.append("Investigate and fix sources of processing errors")
    
    if cache_stats["memory_cache_size"] > 1000:
        recommendations.append("Consider clearing old cache entries to free up memory")
    
    return recommendations