from fastapi import FastAPI, HTTPException, Depends, status, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional, Dict, Any
import uvicorn
import uuid
from datetime import datetime, timedelta
import jwt
import os
import shutil
import asyncio
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialisation de l'application
app = FastAPI(
    title="AI Chat API",
    description="API for the AI Multimodal Chatbot application",
    version="1.0.0"
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Dans un environnement de production, spécifiez les domaines exacts
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration JWT
SECRET_KEY = os.getenv("SECRET_KEY", "votre_clé_secrète_très_sécurisée")  # À remplacer par une vraie clé sécurisée en production
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24  # 24 hours

# Ensure media directories exist
MEDIA_ROOT = Path("./media")
MEDIA_ROOT.mkdir(exist_ok=True)
(MEDIA_ROOT / "images").mkdir(exist_ok=True)
(MEDIA_ROOT / "audio").mkdir(exist_ok=True)
(MEDIA_ROOT / "documents").mkdir(exist_ok=True)

# Mount static files
app.mount("/media", StaticFiles(directory="media"), name="media")

# ===== Modèles de données =====

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    user_id: Optional[str] = None

class UserIn(BaseModel):
    username: str
    email: EmailStr
    password: str

class UserOut(BaseModel):
    id: str
    username: str
    email: str

class MessageIn(BaseModel):
    content: str
    type: str = "text"
    media_urls: List[str] = []
    reply_to_id: Optional[str] = None

class Message(BaseModel):
    id: str
    content: str
    type: str
    sender: str
    timestamp: datetime
    status: str = "sent"
    media_urls: List[str] = []
    reply_to_id: Optional[str] = None
    importance_level: str = "normal"

class ChatIn(BaseModel):
    title: str

class Chat(BaseModel):
    id: str
    title: str
    created_at: datetime
    last_message_time: Optional[datetime] = None
    last_message_content: str = ""
    is_pinned: bool = False

# ===== Base de données simulée =====
fake_users_db: Dict[str, Dict[str, Any]] = {}
fake_chats_db: Dict[str, Dict[str, Any]] = {}
fake_messages_db: Dict[str, Dict[str, Any]] = {}

# ===== Fonctions d'authentification =====
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None or user_id not in fake_users_db:
            raise credentials_exception
        return fake_users_db[user_id]
    except jwt.PyJWTError as e:
        logger.error(f"JWT error: {e}")
        raise credentials_exception

# ===== AI Helper functions =====

async def generate_ai_response(message_content: str) -> str:
    """
    Generate an AI response. In a real app, this would call an AI service like OpenAI.
    """
    # Simulate AI processing time
    await asyncio.sleep(0.5)
    
    # Simple response generation - replace with actual AI call in production
    responses = {
        "hello": "Hello! How can I assist you today?",
        "help": "I'm here to help! Ask me anything.",
        "weather": "I don't have real-time weather data, but I can help with other questions!",
    }
    
    # Check for keyword matches
    for keyword, response in responses.items():
        if keyword in message_content.lower():
            return response
    
    # Default response
    return f"Thanks for your message: '{message_content}'. How can I assist you further?"

# ===== API Endpoints =====

@app.get("/")
async def root():
    return {"message": "Welcome to the AI Chatbot API. Access /docs for documentation."}

@app.post("/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    # Handle empty database case for initial setup
    if not fake_users_db:
        # Create a default user for testing
        user_id = str(uuid.uuid4())
        fake_users_db[user_id] = {
            "id": user_id,
            "username": "test",
            "email": "test@example.com",
            "password": "password"  # In a real app, hash this!
        }
        logger.info(f"Created default user: {user_id}")
    
    # Check credentials
    for user_id, user_data in fake_users_db.items():
        if user_data["username"] == form_data.username and user_data["password"] == form_data.password:
            access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
            access_token = create_access_token(
                data={"sub": user_id}, expires_delta=access_token_expires
            )
            return {"access_token": access_token, "token_type": "bearer"}
    
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Incorrect username or password",
        headers={"WWW-Authenticate": "Bearer"},
    )

@app.post("/users/", response_model=UserOut)
async def create_user(user: UserIn):
    # Check if username already exists
    for existing_user in fake_users_db.values():
        if existing_user["username"] == user.username:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Username already registered"
            )
    
    user_id = str(uuid.uuid4())
    fake_users_db[user_id] = {
        "id": user_id,
        "username": user.username,
        "email": user.email,
        "password": user.password  # In a real system, hash the password!
    }
    return {"id": user_id, "username": user.username, "email": user.email}

@app.get("/users/me", response_model=UserOut)
async def read_users_me(current_user: dict = Depends(get_current_user)):
    return {"id": current_user["id"], "username": current_user["username"], "email": current_user["email"]}

@app.post("/chats/", response_model=Chat)
async def create_chat(chat: ChatIn, current_user: dict = Depends(get_current_user)):
    chat_id = str(uuid.uuid4())
    now = datetime.now()
    chat_data = {
        "id": chat_id,
        "title": chat.title,
        "user_id": current_user["id"],
        "created_at": now,
        "last_message_time": now,
        "last_message_content": "",
        "is_pinned": False
    }
    fake_chats_db[chat_id] = chat_data
    logger.info(f"Created chat: {chat_id} for user: {current_user['id']}")
    return chat_data

@app.get("/chats/", response_model=List[Chat])
async def read_chats(current_user: dict = Depends(get_current_user)):
    user_chats = [
        {
            "id": chat["id"],
            "title": chat["title"],
            "created_at": chat["created_at"],
            "last_message_time": chat["last_message_time"],
            "last_message_content": chat["last_message_content"],
            "is_pinned": chat["is_pinned"]
        }
        for chat in fake_chats_db.values()
        if chat["user_id"] == current_user["id"]
    ]
    # Sort by last message time (most recent first)
    user_chats.sort(key=lambda x: x["last_message_time"] or x["created_at"], reverse=True)
    return user_chats

@app.get("/chats/{chat_id}", response_model=Chat)
async def get_chat(chat_id: str, current_user: dict = Depends(get_current_user)):
    if chat_id not in fake_chats_db:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    chat = fake_chats_db[chat_id]
    if chat["user_id"] != current_user["id"]:
        raise HTTPException(status_code=403, detail="Not authorized to access this chat")
        
    return {
        "id": chat["id"],
        "title": chat["title"],
        "created_at": chat["created_at"],
        "last_message_time": chat["last_message_time"],
        "last_message_content": chat["last_message_content"],
        "is_pinned": chat["is_pinned"]
    }

@app.post("/chats/{chat_id}/messages/", response_model=Message)
async def create_message(chat_id: str, message: MessageIn, current_user: dict = Depends(get_current_user)):
    if chat_id not in fake_chats_db:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    # Verify user has access to this chat
    if fake_chats_db[chat_id]["user_id"] != current_user["id"]:
        raise HTTPException(status_code=403, detail="Not authorized to access this chat")
    
    message_id = str(uuid.uuid4())
    now = datetime.now()
    
    # Create user message
    user_message = {
        "id": message_id,
        "content": message.content,
        "type": message.type,
        "sender": "user",
        "timestamp": now,
        "status": "sent",
        "media_urls": message.media_urls,
        "reply_to_id": message.reply_to_id,
        "importance_level": "normal",
        "chat_id": chat_id  # Add chat_id to make filtering easier
    }
    fake_messages_db[message_id] = user_message
    
    # Update the chat's last message
    fake_chats_db[chat_id]["last_message_time"] = now
    fake_chats_db[chat_id]["last_message_content"] = message.content
    
    # Generate AI response asynchronously
    asyncio.create_task(create_ai_response(chat_id, message.content))
    
    logger.info(f"Message created: {message_id} in chat: {chat_id}")
    return user_message

@app.get("/chats/{chat_id}/messages/", response_model=List[Message])
async def read_messages(chat_id: str, current_user: dict = Depends(get_current_user)):
    if chat_id not in fake_chats_db:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    # Verify user has access to this chat
    if fake_chats_db[chat_id]["user_id"] != current_user["id"]:
        raise HTTPException(status_code=403, detail="Not authorized to access this chat")
    
    # Filter messages for this chat
    chat_messages = [
        msg for msg in fake_messages_db.values() 
        if msg.get("chat_id") == chat_id
    ]
    
    # Sort by timestamp
    chat_messages.sort(key=lambda x: x["timestamp"])
    
    return chat_messages

@app.post("/upload/")
async def upload_file(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    # Determine file type and appropriate directory
    content_type = file.content_type or "application/octet-stream"
    file_ext = os.path.splitext(file.filename)[1] if file.filename else ".bin"
    
    if content_type.startswith("image/"):
        directory = MEDIA_ROOT / "images"
    elif content_type.startswith("audio/"):
        directory = MEDIA_ROOT / "audio"
    else:
        directory = MEDIA_ROOT / "documents"
    
    # Generate unique filename
    unique_filename = f"{uuid.uuid4()}{file_ext}"
    file_path = directory / unique_filename
    
    # Save file
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # Generate URL
    file_url = f"/media/{directory.name}/{unique_filename}"
    
    logger.info(f"File uploaded: {file_url}")
    return {"url": file_url}

@app.delete("/chats/{chat_id}")
async def delete_chat(chat_id: str, current_user: dict = Depends(get_current_user)):
    if chat_id not in fake_chats_db:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    # Verify user has access to this chat
    if fake_chats_db[chat_id]["user_id"] != current_user["id"]:
        raise HTTPException(status_code=403, detail="Not authorized to access this chat")
    
    # Delete chat
    del fake_chats_db[chat_id]
    
    # Delete associated messages
    for msg_id, msg in list(fake_messages_db.items()):
        if msg.get("chat_id") == chat_id:
            del fake_messages_db[msg_id]
    
    logger.info(f"Chat deleted: {chat_id}")
    return {"success": True}

# ===== Helper functions =====

async def create_ai_response(chat_id: str, user_message: str):
    """Create an AI response to a user message in a specific chat."""
    # Generate AI response
    ai_content = await generate_ai_response(user_message)
    
    # Create AI message
    ai_message_id = str(uuid.uuid4())
    now = datetime.now()
    
    ai_message = {
        "id": ai_message_id,
        "content": ai_content,
        "type": "text",
        "sender": "ai",
        "timestamp": now,
        "status": "sent",
        "media_urls": [],
        "reply_to_id": None,
        "importance_level": "normal",
        "chat_id": chat_id
    }
    
    # Add to database
    fake_messages_db[ai_message_id] = ai_message
    
    # Update chat
    if chat_id in fake_chats_db:
        fake_chats_db[chat_id]["last_message_time"] = now
        fake_chats_db[chat_id]["last_message_content"] = ai_content
    
    logger.info(f"AI response created: {ai_message_id} in chat: {chat_id}")

# Initialize test data if needed
def init_test_data():
    if not fake_users_db:
        user_id = str(uuid.uuid4())
        fake_users_db[user_id] = {
            "id": user_id,
            "username": "test",
            "email": "test@example.com",
            "password": "password"  # In a real app, hash this!
        }
        logger.info("Created test user")

# Uncomment to initialize test data on startup
# init_test_data()

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)