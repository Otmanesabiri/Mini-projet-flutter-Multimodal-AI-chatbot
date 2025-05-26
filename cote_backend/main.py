from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel
from typing import List, Optional
import uvicorn
import uuid
from datetime import datetime, timedelta
import jwt

# Initialisation de l'application
app = FastAPI(title="AI Chat API")

# Configuration CORS pour permettre les requêtes depuis Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Dans un environnement de production, spécifiez les domaines exacts
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration JWT
SECRET_KEY = "votre_clé_secrète_très_sécurisée"  # À remplacer par une vraie clé sécurisée en production
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# Modèles de données
class Token(BaseModel):
    access_token: str
    token_type: str

class UserIn(BaseModel):
    username: str
    email: str
    password: str

class User(BaseModel):
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
    last_message_time: datetime = None
    last_message_content: str = ""
    is_pinned: bool = False

# Base de données simulée
fake_users_db = {}
fake_chats_db = {}
fake_messages_db = {}

# Fonctions d'authentification
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
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
    except jwt.PyJWTError:
        raise credentials_exception
    return fake_users_db[user_id]

# Endpoints
@app.post("/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
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

@app.post("/users/", response_model=User)
async def create_user(user: UserIn):
    user_id = str(uuid.uuid4())
    fake_users_db[user_id] = {
        "id": user_id,
        "username": user.username,
        "email": user.email,
        "password": user.password  # Dans un vrai système, hachez le mot de passe !
    }
    return {"id": user_id, "username": user.username, "email": user.email}

@app.get("/users/me", response_model=User)
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
    return chat_data

@app.get("/chats/", response_model=List[Chat])
async def read_chats(current_user: dict = Depends(get_current_user)):
    user_chats = []
    for chat_id, chat in fake_chats_db.items():
        if chat["user_id"] == current_user["id"]:
            user_chats.append({
                "id": chat["id"],
                "title": chat["title"],
                "created_at": chat["created_at"],
                "last_message_time": chat["last_message_time"],
                "last_message_content": chat["last_message_content"],
                "is_pinned": chat["is_pinned"]
            })
    return user_chats

@app.post("/chats/{chat_id}/messages/", response_model=Message)
async def create_message(chat_id: str, message: MessageIn, current_user: dict = Depends(get_current_user)):
    if chat_id not in fake_chats_db:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    # Vérifier que l'utilisateur a accès à ce chat
    if fake_chats_db[chat_id]["user_id"] != current_user["id"]:
        raise HTTPException(status_code=403, detail="Not authorized to access this chat")
    
    message_id = str(uuid.uuid4())
    now = datetime.now()
    
    # Créer le message utilisateur
    user_message = {
        "id": message_id,
        "content": message.content,
        "type": message.type,
        "sender": "user",
        "timestamp": now,
        "status": "sent",
        "media_urls": message.media_urls,
        "reply_to_id": message.reply_to_id,
        "importance_level": "normal"
    }
    fake_messages_db[message_id] = user_message
    
    # Mettre à jour le dernier message du chat
    fake_chats_db[chat_id]["last_message_time"] = now
    fake_chats_db[chat_id]["last_message_content"] = message.content
    
    # Simuler une réponse d'IA
    ai_response_id = str(uuid.uuid4())
    ai_response = {
        "id": ai_response_id,
        "content": f"This is an AI response to: {message.content}",
        "type": "text",
        "sender": "ai",
        "timestamp": datetime.now(),
        "status": "sent",
        "media_urls": [],
        "reply_to_id": None,
        "importance_level": "normal"
    }
    fake_messages_db[ai_response_id] = ai_response
    
    return user_message

@app.get("/chats/{chat_id}/messages/", response_model=List[Message])
async def read_messages(chat_id: str, current_user: dict = Depends(get_current_user)):
    if chat_id not in fake_chats_db:
        raise HTTPException(status_code=404, detail="Chat not found")
    
    # Vérifier que l'utilisateur a accès à ce chat
    if fake_chats_db[chat_id]["user_id"] != current_user["id"]:
        raise HTTPException(status_code=403, detail="Not authorized to access this chat")
    
    # Dans un vrai système, vous récupéreriez les messages de ce chat depuis la base de données
    # Ici, nous simulons simplement quelques messages
    messages = [msg for msg in fake_messages_db.values()]
    return messages

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)