# AI Multimodal Chatbot Application

A sophisticated Flutter-based AI chatbot application that enables multimodal interaction with Large Language Models (LLMs) through text, voice, and images. Built with modern architecture principles and designed for seamless real-time communication.

## 🌟 Overview

This AI chatbot app provides an intelligent conversational experience where users can interact with an AI assistant through multiple input methods. The application features a clean, modern UI with smooth animations, real-time messaging capabilities, and comprehensive accessibility support.

## 🎯 What This Chatbot Does

### **Core Functionality**
- **Intelligent Conversations**: Engage in natural language conversations with a powerful AI assistant
- **Multimodal Input**: Communicate through text typing, voice commands, or image uploads
- **Real-time Responses**: Get instant AI responses with live typing indicators and message status updates
- **Context Awareness**: The AI maintains conversation context and can reference previous messages
- **Smart Analysis**: Send images for AI-powered analysis, description, and question answering

### **Key Capabilities**
- **Text Chat**: Traditional messaging with rich formatting and emoji support
- **Voice Interaction**: 
  - Speech-to-text for hands-free message input
  - Text-to-speech for audio responses (accessibility)
- **Image Processing**: Upload and analyze images with AI vision capabilities
- **Conversation Management**: Create, organize, and search through chat histories
- **Offline Support**: Access previous conversations even without internet connection

## ✨ Features

### **User Experience**
- **Modern Interface**: Clean, intuitive design with Material Design principles
- **Responsive Layout**: Optimized for mobile, tablet, and desktop screens
- **Theme Support**: Dark/Light modes with automatic switching based on system preferences
- **Smooth Animations**: Elegant transitions and micro-interactions throughout the app
- **Accessibility**: 
  - High contrast mode for better visibility
  - Dyslexia-friendly font options
  - Reduced motion settings
  - Screen reader compatibility
  - Adjustable text sizing

### **Communication Features**
- **Real-time Messaging**: Instant message delivery via WebSocket connections
- **Typing Indicators**: See when the AI is generating a response
- **Message Status**: Track message delivery and read receipts
- **Rich Interactions**:
  - Reply to specific messages
  - Edit and delete your messages
  - Bookmark important conversations
  - React to messages with emojis
  - Copy and share message content

### **Advanced Functionality**
- **Context Panel**: Side panel showing conversation context, sources, and references
- **Search**: Find specific messages or topics across all conversations
- **Export**: Save or share conversation histories
- **Privacy Controls**: Manage data retention and privacy settings

## 🏗️ Technical Architecture

### **Frontend (Flutter)**
Built using Clean Architecture with MVVM pattern:

```
lib/
├── core/
│   ├── di/                 # Dependency injection setup
│   ├── network/            # API clients and WebSocket handling
│   ├── routes/             # App navigation and routing
│   ├── constants/          # App-wide constants
│   ├── errors/             # Error handling and exceptions
│   └── utils/              # Utility functions and helpers
├── features/
│   ├── chat/
│   │   ├── data/           # Data sources and repositories
│   │   ├── domain/         # Business logic and entities
│   │   └── presentation/   # UI components and state management
│   ├── home/               # Main navigation and tabs
│   └── settings/           # App configuration and preferences
└── main.dart               # Application entry point
```

### **State Management**
- **BLoC Pattern**: Reactive state management for predictable UI updates
- **Dependency Injection**: Clean separation of concerns with GetIt
- **Repository Pattern**: Abstract data layer for flexible backend integration

### **Communication Layer**
- **REST API**: Standard HTTP requests for authentication and data retrieval
- **WebSocket**: Real-time bidirectional communication for live messaging
- **File Upload**: Multipart form data handling for image and audio files

## 🔧 Backend Integration

The app is designed to work with a Flask-based backend providing:

### **API Endpoints**
- **Authentication**: Login, registration, token refresh
- **Chat Management**: Send messages, retrieve history, manage conversations
- **LLM Integration**: Text generation, streaming responses, context handling
- **File Processing**: Image upload, audio processing, document handling
- **Real-time Events**: WebSocket for live messaging and presence

### **Expected Backend Capabilities**
- **Large Language Model**: Integration with models like GPT, Claude, or open-source alternatives
- **Vision AI**: Image analysis and description capabilities
- **Speech Processing**: Speech-to-text and text-to-speech conversion
- **Context Management**: Conversation memory and context tracking
- **User Management**: Authentication, profiles, and preferences

## 🚀 Getting Started

### **Prerequisites**
- Flutter 3.16 or higher
- Dart 3.0 or higher
- Compatible backend API (Flask recommended)

### **Installation**
1. Clone the repository
2. Install Flutter dependencies: `flutter pub get`
3. Configure API endpoints in `lib/core/config/`
4. Run the application: `flutter run`

## 🎨 Design Philosophy

### **User-Centered Design**
- Intuitive navigation with minimal learning curve
- Consistent visual language throughout the app
- Focus on readability and content clarity
- Responsive design for various screen sizes

### **Accessibility First**
- WCAG compliance for inclusive design
- Support for assistive technologies
- Customizable interface for different needs
- Multiple input methods for diverse users

### **Performance Optimized**
- Efficient state management for smooth interactions
- Lazy loading for large conversation histories
- Optimized image handling and caching
- Minimal battery and data usage

## 🔐 Privacy & Security

- **Local Data Encryption**: Secure storage of conversation histories
- **Token-based Authentication**: JWT tokens for secure API access
- **Privacy Controls**: User control over data retention and sharing
- **Secure Communication**: HTTPS and WSS for encrypted data transmission

## 🤖 AI Capabilities

This chatbot serves as a frontend interface for various AI capabilities:

- **Natural Language Understanding**: Comprehend user intent and context
- **Conversational AI**: Maintain engaging, helpful dialogues
- **Multimodal Processing**: Handle text, speech, and visual inputs
- **Knowledge Integration**: Access and synthesize information from various sources
- **Personalization**: Adapt responses based on user preferences and history

## 🚀 Guide de développement du chatbot

### Architecture de l'application

Le développement de notre chatbot implique deux composants principaux:
1. **Frontend Flutter**: L'interface utilisateur interactive
2. **Backend Python**: L'API qui gère l'authentification et la communication avec les modèles LLM

### Développement Frontend avec Flutter

#### Structure de base
- L'application démarre avec `main.dart`, qui initialise les dépendances et lance le widget `MyApp`
- Utilisation de widgets stateful pour la gestion dynamique des conversations
- Organisation en couches suivant le principe du Clean Architecture

#### Pages principales
1. **SplashPage**: Écran de démarrage qui vérifie l'authentification
2. **LoginPage**: Gestion de l'authentification utilisateur
3. **ChatPage**: Interface principale du chatbot

#### Gestion des messages
- Utilisation de `ListView.builder` pour afficher la liste des messages
- Style différencié pour les messages utilisateur vs assistant
- Défilement automatique vers les nouveaux messages
- Support pour différents types de contenu (texte, images, code)

#### Interaction avec le backend
- Requêtes HTTP avec Dio pour communiquer avec l'API
- Gestion des tokens d'authentification JWT
- Stockage local avec SharedPreferences pour la session utilisateur

### Interaction avec les modèles LLM

Notre application peut interagir avec différents modèles de langage:

1. **Via notre backend Python**:
   - Les requêtes sont envoyées au backend qui communique avec le LLM
   - Le backend maintient le contexte de la conversation
   - Format JSON pour l'échange de données

2. **Connexion directe aux API LLM**:
   - Pour les modèles comme OpenAI: `https://api.openai.com/v1/chat/completions`
   - Pour les modèles locaux comme Ollama: `http://localhost:11434/v1/chat/completions`
   - Chaque requête doit inclure l'historique complet pour maintenir le contexte

#### Exemple de format de requête

```json
{
  "model": "gpt-3.5-turbo",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Hello!"},
    {"role": "assistant", "content": "Hi there! How can I help you today?"},
    {"role": "user", "content": "What's the weather like?"}
  ]
}
```

### Améliorations multimodales

Notre application va au-delà du simple texte pour offrir:
- **Reconnaissance vocale**: Conversion parole-texte via `speech_to_text`
- **Synthèse vocale**: Lecture des réponses via `flutter_tts`
- **Traitement d'images**: Envoi et analyse d'images
- **Partage de fichiers**: Support pour différents types de médias

### Conseils pour les développeurs

1. Utilisez `BLoC` pour séparer logique métier et interface
2. Implémentez le mécanisme de token refresh pour maintenir la session
3. Ajoutez des indicateurs de chargement pendant les communications avec l'API
4. Gérez correctement les erreurs réseau et serveur
5. Testez avec différentes tailles d'écran pour une interface responsive

*Cette application représente une approche moderne de l'interaction homme-IA, combinant technologie de pointe et design UX réfléchi pour créer un outil de communication puissant, accessible et intuitif.*
