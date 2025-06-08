from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import uvicorn
import logging
import hashlib
import json
from datetime import datetime, timedelta
from openai import OpenAI

# Configuration du logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Cache simple en mémoire pour les réponses fréquentes
response_cache = {}
CACHE_DURATION = timedelta(hours=1)  # Cache valide pendant 1 heure

# Clé API DeepSeek (à remplacer par votre clé)
DEEPSEEK_API_KEY = "YOUR_DEEPSEEK_API_KEY"  # Remplacez par votre clé API

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
    temperature: float = 0.3  # Réduire pour des réponses plus cohérentes et rapides
    max_tokens: Optional[int] = 512  # Limiter la longueur pour la rapidité
    stream: bool = False
    # Nouveaux paramètres d'optimisation
    top_p: float = 0.8  # Échantillonnage nucleus pour la rapidité
    frequency_penalty: float = 0.1  # Réduire les répétitions
    presence_penalty: float = 0.1  # Encourager la diversité

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

def create_cache_key(messages: List[Dict], temperature: float, max_tokens: Optional[int]) -> str:
    """Créer une clé de cache basée sur les messages et paramètres"""
    cache_data = {
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens
    }
    return hashlib.md5(json.dumps(cache_data, sort_keys=True).encode()).hexdigest()

def is_cache_valid(timestamp: datetime) -> bool:
    """Vérifier si le cache est encore valide"""
    return datetime.now() - timestamp < CACHE_DURATION

def optimize_messages(messages: List[Dict]) -> List[Dict]:
    """Optimiser l'historique des messages pour réduire les tokens"""
    # Garder seulement les 10 derniers messages pour réduire le contexte
    if len(messages) > 10:
        # Garder le premier message (souvent le system prompt) et les 9 derniers
        return [messages[0]] + messages[-9:] if messages else messages
    return messages

@app.post("/v1/chat/completions", response_model=ChatResponse)
async def chat_completion(request: ChatRequest):
    try:
        logger.info(f"Requête reçue pour le modèle: {request.model}")
        logger.info(f"Nombre de messages: {len(request.messages)}")
        
        # Convertir les messages au bon format
        messages = [{"role": msg.role, "content": msg.content} for msg in request.messages]
        
        # Optimiser les messages pour réduire les tokens
        optimized_messages = optimize_messages(messages)
        
        # Vérifier le cache
        cache_key = create_cache_key(optimized_messages, request.temperature, request.max_tokens)
        
        if cache_key in response_cache:
            cached_response, timestamp = response_cache[cache_key]
            if is_cache_valid(timestamp):
                logger.info("Réponse récupérée depuis le cache")
                return cached_response
            else:
                # Supprimer le cache expiré
                del response_cache[cache_key]
        
        # Appeler l'API DeepSeek avec les paramètres optimisés
        response = client.chat.completions.create(
            model=request.model,
            messages=optimized_messages,
            temperature=request.temperature,
            max_tokens=request.max_tokens,
            top_p=request.top_p,
            frequency_penalty=request.frequency_penalty,
            presence_penalty=request.presence_penalty,
            stream=request.stream
        )
        
        # Extraire et retourner le résultat
        response_content = response.choices[0].message.content
        usage = {
            "prompt_tokens": response.usage.prompt_tokens,
            "completion_tokens": response.usage.completion_tokens,
            "total_tokens": response.usage.total_tokens
        }
        
        result = ChatResponse(
            content=response_content,
            model=request.model,
            usage=usage
        )
        
        # Mettre en cache la réponse
        response_cache[cache_key] = (result, datetime.now())
        
        logger.info(f"Réponse générée de {len(response_content)} caractères")
        logger.info(f"Tokens utilisés: {usage['total_tokens']}")
        
        return result
        
    except Exception as e:
        logger.error(f"Erreur lors de l'appel à l'API DeepSeek: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de l'appel à l'API DeepSeek: {str(e)}"
        )

# Endpoint pour nettoyer le cache manuellement
@app.post("/admin/clear-cache")
async def clear_cache():
    """Nettoyer le cache des réponses"""
    global response_cache
    cache_size = len(response_cache)
    response_cache.clear()
    return {"message": f"Cache nettoyé. {cache_size} entrées supprimées."}

# Endpoint pour obtenir des statistiques
@app.get("/admin/stats")
async def get_stats():
    """Obtenir des statistiques sur le cache et l'utilisation"""
    valid_entries = 0
    expired_entries = 0
    
    for cache_key, (_, timestamp) in response_cache.items():
        if is_cache_valid(timestamp):
            valid_entries += 1
        else:
            expired_entries += 1
    
    return {
        "cache_entries": len(response_cache),
        "valid_entries": valid_entries,
        "expired_entries": expired_entries,
        "cache_duration_hours": CACHE_DURATION.total_seconds() / 3600
    }

if __name__ == "__main__":
    print("Démarrage du service DeepSeek sur http://localhost:8088...")
    uvicorn.run("deepseek_service:app", host="0.0.0.0", port=8088, reload=True)
