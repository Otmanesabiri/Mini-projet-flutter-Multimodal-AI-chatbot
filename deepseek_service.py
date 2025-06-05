from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import uvicorn
import logging
from openai import OpenAI

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Clé API DeepSeek (à remplacer par votre clé)
DEEPSEEK_API_KEY = "sk-c1211bf1366946d3a67b7c967bce1dc6"  # Remplacez par votre clé API

# Initialisation de l'application
app = FastAPI(
    title="DeepSeek AI Service",
    description="Service d'intégration pour l'API DeepSeek",
    version="1.0.0"
)

# Configuration CORS pour autoriser les requêtes depuis Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Pour la production, spécifiez les domaines exacts
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Client OpenAI configuré pour DeepSeek
client = OpenAI(api_key=DEEPSEEK_API_KEY, base_url="https://api.deepseek.com")

# Modèles de données
class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    model: str = "deepseek-chat"
    messages: List[Message]
    temperature: float = 0.7
    max_tokens: Optional[int] = None
    stream: bool = False

class ChatResponse(BaseModel):
    content: str
    model: str
    usage: Dict[str, int]

@app.get("/")
async def root():
    return {
        "service": "DeepSeek AI Service", 
        "status": "running", 
        "docs": "/docs"
    }

@app.post("/v1/chat/completions", response_model=ChatResponse)
async def chat_completion(request: ChatRequest):
    try:
        logger.info(f"Requête reçue pour le modèle: {request.model}")
        logger.info(f"Nombre de messages: {len(request.messages)}")
        
        # Convertir les messages au bon format
        messages = [{"role": msg.role, "content": msg.content} for msg in request.messages]
        
        # Appeler l'API DeepSeek
        response = client.chat.completions.create(
            model=request.model,
            messages=messages,
            temperature=request.temperature,
            max_tokens=request.max_tokens,
            stream=request.stream
        )
        
        # Extraire et retourner le résultat
        response_content = response.choices[0].message.content
        usage = {
            "prompt_tokens": response.usage.prompt_tokens,
            "completion_tokens": response.usage.completion_tokens,
            "total_tokens": response.usage.total_tokens
        }
        
        logger.info(f"Réponse générée de {len(response_content)} caractères")
        
        return ChatResponse(
            content=response_content,
            model=request.model,
            usage=usage
        )
        
    except Exception as e:
        logger.error(f"Erreur lors de l'appel à l'API DeepSeek: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de l'appel à l'API DeepSeek: {str(e)}"
        )

if __name__ == "__main__":
    print("Démarrage du service DeepSeek sur http://localhost:8088...")
    uvicorn.run("deepseek_service:app", host="0.0.0.0", port=8088, reload=True)
