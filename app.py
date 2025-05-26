from fastapi import FastAPI, WebSocket, Depends, HTTPException, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from typing import List, Dict, Any, Optional
from datetime import datetime
import json
import uuid
import asyncio

app = FastAPI()

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory storage for chats and messages (in a real app, use a database)
chats = {}
messages = {}

# Active WebSocket connections
active_connections: Dict[str, WebSocket] = {}

# Auth helper (in a real app, use JWT tokens)
async def get_user_id(token: str = None):
    if token == "fake_token":
        return "user_123"
    raise HTTPException(status_code=401, detail="Invalid token")

# WebSocket authentication
async def get_user_from_ws(websocket: WebSocket):
    try:
        token = websocket.query_params.get("token")
        if token == "fake_token":
            return "user_123"
        await websocket.close(code=1008, reason="Invalid token")
    except:
        await websocket.close(code=1008, reason="Authentication failed")
        raise HTTPException(status_code=401, detail="Authentication failed")

# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}
    
    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections[user_id] = websocket
    
    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
    
    async def send_personal_message(self, message: Dict, user_id: str):
        if user_id in self.active_connections:
            await self.active_connections[user_id].send_text(json.dumps(message))
    
    async def broadcast(self, message: Dict, exclude_user: str = None):
        for user_id, connection in self.active_connections.items():
            if user_id != exclude_user:
                await connection.send_text(json.dumps(message))

manager = ConnectionManager()

# API Endpoints
@app.get("/api/v1/chats")
async def get_chats(user_id: str = Depends(get_user_id)):
    user_chats = [chat for chat in chats.values() if chat["user_id"] == user_id]
    return {"data": user_chats}

@app.post("/api/v1/chats")
async def create_chat(data: Dict[str, Any], user_id: str = Depends(get_user_id)):
    chat_id = str(uuid.uuid4())
    new_chat = {
        "id": chat_id,
        "title": data["title"],
        "user_id": user_id,
        "created_at": datetime.now().isoformat(),
        "last_message_time": datetime.now().isoformat(),
        "last_message_content": "Chat created",
        "is_pinned": False,
        "is_archived": False,
    }
    chats[chat_id] = new_chat
    return {"data": new_chat}

@app.get("/api/v1/chats/{chat_id}")
async def get_chat(chat_id: str, user_id: str = Depends(get_user_id)):
    if chat_id in chats and chats[chat_id]["user_id"] == user_id:
        return {"data": chats[chat_id]}
    raise HTTPException(status_code=404, detail="Chat not found")

@app.get("/api/v1/chats/{chat_id}/messages")
async def get_messages(chat_id: str, user_id: str = Depends(get_user_id)):
    if chat_id in chats and chats[chat_id]["user_id"] == user_id:
        chat_messages = [msg for msg in messages.values() if msg["chat_id"] == chat_id]
        chat_messages.sort(key=lambda x: x["timestamp"])
        return {"data": chat_messages}
    raise HTTPException(status_code=404, detail="Chat not found")

@app.post("/api/v1/chats/{chat_id}/messages")
async def send_message(chat_id: str, data: Dict[str, Any], user_id: str = Depends(get_user_id)):
    if chat_id not in chats or chats[chat_id]["user_id"] != user_id:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    msg_id = str(uuid.uuid4())
    timestamp = datetime.now().isoformat()
    
    new_message = {
        "id": msg_id,
        "chat_id": chat_id,
        "content": data["content"],
        "type": data.get("type", "text"),
        "sender": "user",
        "timestamp": timestamp,
        "status": "sent",
        "media_urls": data.get("media_urls", []),
    }
    
    messages[msg_id] = new_message
    
    # Update chat with last message
    chats[chat_id]["last_message_time"] = timestamp
    chats[chat_id]["last_message_content"] = data["content"]
    
    # Simulate AI response after a delay
    asyncio.create_task(generate_ai_response(chat_id, new_message))
    
    return {"data": new_message}

@app.post("/api/v1/upload")
async def upload_file(user_id: str = Depends(get_user_id)):
    # In a real app, handle file upload and storage
    # For this example, return a fake URL
    return {"url": f"https://fake-file-storage.com/files/{uuid.uuid4()}.jpg"}

@app.delete("/api/v1/chats/{chat_id}")
async def delete_chat(chat_id: str, user_id: str = Depends(get_user_id)):
    if chat_id in chats and chats[chat_id]["user_id"] == user_id:
        del chats[chat_id]
        # Delete associated messages
        global messages
        messages = {k: v for k, v in messages.items() if v["chat_id"] != chat_id}
        return {"success": True}
    raise HTTPException(status_code=404, detail="Chat not found")

@app.put("/api/v1/messages/{message_id}/read")
async def mark_message_as_read(message_id: str, user_id: str = Depends(get_user_id)):
    if message_id in messages:
        message = messages[message_id]
        chat_id = message["chat_id"]
        
        if chat_id in chats and chats[chat_id]["user_id"] == user_id:
            messages[message_id]["status"] = "read"
            return {"success": True}
    
    raise HTTPException(status_code=404, detail="Message not found")

# WebSocket endpoint
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    user_id = await get_user_from_ws(websocket)
    await manager.connect(websocket, user_id)
    
    try:
        while True:
            data = await websocket.receive_text()
            event = json.loads(data)
            
            if event["type"] == "typing":
                # Broadcast typing status to AI (in a real app)
                pass
            elif event["type"] == "read":
                # Update message read status
                message_id = event["data"]["message_id"]
                if message_id in messages:
                    messages[message_id]["status"] = "read"
    
    except WebSocketDisconnect:
        manager.disconnect(user_id)

# Helper function to simulate AI response
async def generate_ai_response(chat_id: str, user_message: Dict):
    # Wait to simulate processing time
    await asyncio.sleep(1.5)
    
    # Generate AI response based on user message
    content = f"This is an AI response to: {user_message['content']}"
    
    msg_id = str(uuid.uuid4())
    timestamp = datetime.now().isoformat()
    
    ai_message = {
        "id": msg_id,
        "chat_id": chat_id,
        "content": content,
        "type": "text",
        "sender": "ai",
        "timestamp": timestamp,
        "status": "sent",
        "media_urls": [],
    }
    
    messages[msg_id] = ai_message
    
    # Update chat with last message
    chats[chat_id]["last_message_time"] = timestamp
    chats[chat_id]["last_message_content"] = content
    
    # Send message via WebSocket
    user_id = chats[chat_id]["user_id"]
    await manager.send_personal_message(
        {"type": "message", "data": ai_message},
        user_id
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)