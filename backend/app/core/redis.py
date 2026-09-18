import redis
from app.core.config import settings

try:
    redis_client = redis.from_url(settings.REDIS_URL, decode_responses=True)
except Exception as e:
    print(f"⚠️ Redis connection warning: {e}")
    redis_client = None


def get_redis():
    return redis_client
