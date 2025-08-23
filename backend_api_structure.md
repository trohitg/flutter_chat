# Backend API Structure for Flutter Chat

## Base Configuration
```
Base URL: http://localhost:8000 (development)
          https://api.your-domain.com (production)
API Version: /api/v1
Content-Type: application/json
```

## Core Endpoints

### 1. **Chat Completion (Current Implementation)**

#### POST /chat
Send message and get AI response (backward compatible)
```json
Request:
{
  "messages": [
    {"role": "user", "content": "Hello"},
    {"role": "assistant", "content": "Hi there!"}
  ],
  "max_tokens": 1000,
  "temperature": 0.7
}

Response:
{
  "response": "AI generated response text",
  "usage": {
    "prompt_tokens": 100,
    "completion_tokens": 150,
    "total_tokens": 250
  }
}
```

### 2. **Session-Based Chat (Recommended)**

#### POST /api/v1/sessions
Create new chat session
```json
Request:
{
  "model": "cerebras-gpt-oss-120b",
  "temperature": 0.7,
  "max_tokens": 1000
}

Response:
{
  "session_id": "sess_abc123",
  "created_at": "2025-01-23T10:00:00Z",
  "expires_in": 3600
}
```

#### POST /api/v1/sessions/{session_id}/messages
Send message in existing session
```json
Request:
{
  "message": "What is the weather today?",
  "stream": false
}

Response:
{
  "id": "msg_xyz789",
  "content": "I cannot provide real-time weather information...",
  "role": "assistant",
  "created_at": "2025-01-23T10:01:00Z",
  "usage": {
    "prompt_tokens": 50,
    "completion_tokens": 100,
    "total_tokens": 150
  }
}
```

#### GET /api/v1/sessions/{session_id}/messages
Get conversation history
```json
Response:
{
  "messages": [
    {
      "id": "msg_001",
      "role": "user",
      "content": "Hello",
      "created_at": "2025-01-23T10:00:30Z"
    },
    {
      "id": "msg_002",
      "role": "assistant",
      "content": "Hello! How can I help you today?",
      "created_at": "2025-01-23T10:00:32Z"
    }
  ],
  "total_count": 2
}
```

#### DELETE /api/v1/sessions/{session_id}
Delete session and clear history
```json
Response:
{
  "message": "Session deleted successfully"
}
```

### 3. **Streaming Support**

#### POST /api/v1/sessions/{session_id}/messages/stream
Stream response using Server-Sent Events (SSE)
```
Request:
{
  "message": "Tell me a story"
}

Response (SSE stream):
data: {"chunk": "Once", "id": "msg_123"}
data: {"chunk": " upon", "id": "msg_123"}
data: {"chunk": " a", "id": "msg_123"}
data: {"chunk": " time", "id": "msg_123"}
data: [DONE]
```

### 4. **Health & Status**

#### GET /api/v1/health
Health check endpoint
```json
Response:
{
  "status": "healthy",
  "model": "cerebras-gpt-oss-120b",
  "version": "1.0.0"
}
```

#### GET /api/v1/status
Get service status and limits
```json
Response:
{
  "active_sessions": 42,
  "requests_today": 1337,
  "rate_limit": {
    "requests_per_minute": 60,
    "requests_remaining": 55
  }
}
```

## Error Response Format
```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later.",
    "retry_after": 30
  },
  "timestamp": "2025-01-23T10:00:00Z"
}
```

## Error Codes
- `400` - Bad Request (invalid parameters)
- `401` - Unauthorized (missing/invalid API key)
- `404` - Not Found (session not found)
- `429` - Rate Limit Exceeded
- `500` - Internal Server Error
- `503` - Service Unavailable

## Headers

### Request Headers
```
Content-Type: application/json
Accept: application/json
X-Session-ID: sess_abc123 (optional, for session tracking)
X-Request-ID: req_xyz789 (optional, for debugging)
```

### Response Headers
```
X-Request-ID: req_xyz789
X-Rate-Limit-Limit: 60
X-Rate-Limit-Remaining: 55
X-Rate-Limit-Reset: 1706007600
```

## Implementation Notes

### Session Management
- Sessions expire after 1 hour of inactivity
- Maximum 100 messages per session
- Session IDs should be UUIDs or secure random strings

### Rate Limiting
- 60 requests per minute per IP (development)
- 10 requests per minute per IP (production)
- Implement exponential backoff on client

### Performance
- Use connection pooling for database
- Cache session data in Redis/memory
- Implement request queuing for high load

### Security
- CORS configuration for web clients
- Input validation and sanitization
- SQL injection prevention
- Rate limiting by IP and session

## Migration Path

### Phase 1: Current Implementation
Keep existing `/chat` endpoint for backward compatibility

### Phase 2: Add Session Support
1. Implement session endpoints alongside existing API
2. Update Flutter app to use sessions
3. Monitor and test both APIs in parallel

### Phase 3: Deprecate Old API
1. Mark `/chat` endpoint as deprecated
2. Redirect traffic to new session-based API
3. Remove old endpoint after migration period

## Example Backend Implementation (FastAPI)

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Optional
import uuid
from datetime import datetime

app = FastAPI()

# Models
class ChatRequest(BaseModel):
    messages: List[Dict[str, str]]
    max_tokens: int = 1000
    temperature: float = 0.7

class SessionRequest(BaseModel):
    model: str = "cerebras-gpt-oss-120b"
    temperature: float = 0.7
    max_tokens: int = 1000

class MessageRequest(BaseModel):
    message: str
    stream: bool = False

# Endpoints
@app.post("/chat")
async def chat_completion(request: ChatRequest):
    """Backward compatible endpoint"""
    # Process with Cerebras API
    return {
        "response": "AI response here",
        "usage": {"prompt_tokens": 100, "completion_tokens": 150}
    }

@app.post("/api/v1/sessions")
async def create_session(request: SessionRequest):
    session_id = f"sess_{uuid.uuid4().hex[:12]}"
    return {
        "session_id": session_id,
        "created_at": datetime.utcnow().isoformat() + "Z",
        "expires_in": 3600
    }

@app.post("/api/v1/sessions/{session_id}/messages")
async def send_message(session_id: str, request: MessageRequest):
    # Validate session, send to Cerebras, store in DB
    return {
        "id": f"msg_{uuid.uuid4().hex[:12]}",
        "content": "AI response",
        "role": "assistant",
        "created_at": datetime.utcnow().isoformat() + "Z"
    }

@app.get("/api/v1/health")
async def health_check():
    return {"status": "healthy", "model": "cerebras-gpt-oss-120b"}
```