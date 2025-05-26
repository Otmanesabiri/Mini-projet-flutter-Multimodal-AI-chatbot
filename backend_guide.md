# AI Chatbot Backend Developer Guide

This guide provides instructions for setting up and extending the Python backend for the AI Chatbot Flutter application.

## Getting Started

### Prerequisites

- Python 3.9+
- pip (Python package manager)
- Virtual environment tool (venv, conda, etc.)

### Quick Setup

1. **Create and activate a virtual environment**:

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. **Install required packages**:

```bash
pip install fastapi uvicorn pydantic python-jose[cryptography] passlib[bcrypt] python-multipart
```

3. **Run the development server**:

```bash
# For the simple backend
cd cote_backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Or for the alternative version with WebSockets
uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

4. **Verify the server is running**:
   - Access the API documentation at http://localhost:8000/docs

## Backend Architecture

We provide two backend options:

1. **`cote_backend/main.py`**: Simple REST API with JWT authentication
2. **`app.py`**: More advanced backend with WebSocket support for real-time chat

Choose the one that best fits your development needs. The Flutter app is configured to work with both (endpoint adjustments may be needed).

## API Endpoints

### Authentication

- **POST `/token`**: Obtain JWT access token
  - Body: `username`, `password` (form data)
  - Returns: `access_token`, `token_type`

### User Management

- **POST `/users/`**: Create new user
  - Body: `username`, `email`, `password`
  - Returns: User object

- **GET `/users/me`**: Get current user profile
  - Auth: Bearer token
  - Returns: User object

### Chat Management

- **GET `/chats/`**: List all chats for current user
  - Auth: Bearer token
  - Returns: Array of Chat objects

- **POST `/chats/`**: Create a new chat
  - Auth: Bearer token
  - Body: `title`
  - Returns: Chat object

- **GET `/chats/{chat_id}`**: Get chat details
  - Auth: Bearer token
  - Returns: Chat object

- **GET `/chats/{chat_id}/messages/`**: Get messages for a specific chat
  - Auth: Bearer token
  - Returns: Array of Message objects

- **POST `/chats/{chat_id}/messages/`**: Send a message in a specific chat
  - Auth: Bearer token
  - Body: `content`, `type`, `media_urls` (optional)
  - Returns: Message object

## Data Models

### User
```python
{
  "id": "string (UUID)",
  "username": "string",
  "email": "string"
}
```

### Chat
```python
{
  "id": "string (UUID)",
  "title": "string",
  "created_at": "datetime",
  "last_message_time": "datetime",
  "last_message_content": "string",
  "is_pinned": "boolean"
}
```

### Message
```python
{
  "id": "string (UUID)",
  "content": "string",
  "type": "string (text, image, audio, etc.)",
  "sender": "string (user, ai)",
  "timestamp": "datetime",
  "status": "string (sent, delivered, read)",
  "media_urls": ["string"],
  "reply_to_id": "string (UUID, optional)",
  "importance_level": "string"
}
```

## WebSocket Support (app.py only)

Connect to `/ws?token=your_token` for real-time updates on:
- New messages
- Message read status
- Typing indicators

## Extending the Backend

### Adding a New Endpoint

1. Define a new function with appropriate HTTP decorator:

```python
@app.get("/new-endpoint")
async def new_endpoint(current_user: dict = Depends(get_current_user)):
    # Implementation here
    return {"data": "response"}
```

2. If it requires a request body, define a Pydantic model:

```python
class NewRequestModel(BaseModel):
    field1: str
    field2: int
    field3: Optional[str] = None
```

### Integrating AI Models

To add real AI responses (instead of the current mock responses):

1. Install the appropriate packages:

```bash
pip install openai transformers torch
```

2. Create an AI service file (e.g., `ai_service.py`):

```python
from openai import OpenAI

client = OpenAI(api_key="your-openai-key")  # Replace with actual key

async def generate_ai_response(user_message: str) -> str:
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": user_message}
        ],
        max_tokens=500
    )
    return response.choices[0].message.content
```

3. Use this service in your message endpoint:

```python
from ai_service import generate_ai_response

@app.post("/chats/{chat_id}/messages/")
async def create_message(chat_id: str, message: MessageIn, current_user: dict = Depends(get_current_user)):
    # ...existing code...
    
    # Replace mock response with real AI
    ai_response_content = await generate_ai_response(message.content)
    
    ai_response = {
        "id": ai_response_id,
        "content": ai_response_content,
        "type": "text",
        "sender": "ai",
        # ...rest of the fields...
    }
    # ...existing code...
```

## Security Considerations

1. **Store secrets properly**: Use environment variables for API keys and JWT secrets
2. **Validate all inputs**: Use Pydantic for robust input validation
3. **Rate limiting**: Add rate limiting for authentication and message endpoints
4. **Database security**: When adding a real database, use parameterized queries

## Testing

Use pytest for testing your backend:

```bash
pip install pytest httpx
pytest
```

Sample test:

```python
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_read_main():
    response = client.get("/")
    assert response.status_code == 200
```

## Database Integration

To replace the in-memory data store with a real database:

1. Install database packages:
```bash
pip install sqlalchemy alembic psycopg2-binary
```

2. Create database models using SQLAlchemy
3. Update repository methods to use the database
4. Use migrations to manage schema changes

## Containerization

For production deployment, containerize your application:

```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Build and run:
```bash
docker build -t ai-chatbot-backend .
docker run -p 8000:8000 ai-chatbot-backend
```

## Common Issues and Troubleshooting

- **CORS errors**: Ensure the CORS middleware is properly configured
- **Authentication failures**: Check token expiration and signing key
- **Performance issues**: Use async endpoints and consider database query optimization

## Next Steps

1. Replace in-memory storage with a proper database (PostgreSQL recommended)
2. Add file upload support for handling images and other media
3. Integrate with a real AI service (OpenAI, HuggingFace, etc.)
4. Add user sessions and proper authentication flow
5. Implement WebSockets for real-time communication