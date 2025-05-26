# AI Chatbot Application

A modern multimodal chatbot application built with Flutter and integrated with a Python Flask backend for LLM capabilities.

## 🌟 Overview

This AI chatbot app allows users to interact with a large language model (LLM) through text, voice, and images. The app features a modern, responsive UI with elegant animations and a clean design.

![App Screenshot](assets/screenshot.png)

## ✨ Features

- **Multimodal Interaction**: Chat with text, voice, and images
- **Real-time Messaging**: Instant responses with typing indicators
- **User Authentication**: Secure login and registration flow
- **Offline Support**: Cache conversations for offline viewing
- **Responsive UI**: Adaptable to mobile, tablet, and desktop screens
- **Dark/Light Mode**: Automatic and manual theme switching
- **Voice Recognition**: Speech-to-text and text-to-speech capabilities
- **Image Analysis**: Send and analyze images with the LLM

## 🏗️ Technical Architecture

### Frontend (Flutter)

The app follows Clean Architecture principles with a MVVM pattern:

```
lib/
├── core/
│   ├── config/             # App configuration
│   ├── constants/          # App-wide constants
│   ├── network/            # API and WebSocket clients
│   ├── theme/              # App theming
│   ├── utils/              # Utility functions
│   └── widgets/            # Reusable widgets
├── features/
│   ├── auth/               # Authentication feature
│   ├── chat/               # Chat feature
│   └── settings/           # App settings
└── main.dart               # Application entry point
```

### Backend (Flask API)

The app is designed to connect to a Flask backend with the following endpoints:

#### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/logout` - User logout
- `POST /api/auth/refresh` - Refresh authentication token

#### Chat
- `POST /api/chat/send` - Send a message
- `GET /api/chat/history` - Get chat history
- `POST /api/chat/conversation` - Create a new conversation
- `DELETE /api/chat/conversation` - Delete a conversation

#### LLM Integration
- `POST /api/llm/generate` - Generate text response
- `POST /api/llm/stream` - Stream text generation
- `POST /api/llm/speech-to-text` - Convert speech to text
- `POST /api/llm/text-to-speech` - Convert text to speech
- `POST /api/llm/analyze-image` - Analyze an image with LLM

#### File Upload
- `POST /api/files/upload/image` - Upload an image
- `POST /api/files/upload/audio` - Upload an audio file
- `POST /api/files/upload/document` - Upload a document

#### WebSocket
- `/socket.io/` - Main socket endpoint
- Socket events: 'message', 'typing', 'user_online', 'user_offline', etc.

## 🚀 Getting Started

### Prerequisites

- Flutter 3.16+ 
- Dart 3.0+
- Python 3.8+ (for backend)
- Flask 2.0+ (for backend)

### Flutter Setup

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/chatbot.git
   cd chatbot
   ```

2. Install dependencies
   ```bash
   flutter pub get
   ```

3. Run the app
   ```bash
   flutter run
   ```

### Backend Setup

The app requires a Flask API backend with LLM integration. Follow these steps to set up the backend:

1. Clone the backend repository (or create it based on our API specifications)
   ```bash
   git clone https://github.com/yourusername/chatbot-backend.git
   cd chatbot-backend
   ```

2. Create a virtual environment
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. Install dependencies
   ```bash
   pip install -r requirements.txt
   ```

4. Set up environment variables
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

5. Run the backend
   ```bash
   python app.py
   ```

## 📱 API Integration Guide

### Backend Developer Guide

To develop the backend for this app, you'll need to implement the following:

#### 1. Authentication API

```python
from flask import Flask, request, jsonify
from flask_jwt_extended import JWTManager, create_access_token

app = Flask(__name__)
app.config['JWT_SECRET_KEY'] = 'your-secret-key'
jwt = JWTManager(app)

@app.route('/api/auth/login', methods=['POST'])
def login():
    email = request.json.get('email')
    password = request.json.get('password')
    
    # Validate credentials
    # ...
    
    # Create token
    access_token = create_access_token(identity=user_id)
    
    return jsonify({
        'token': access_token,
        'user': {
            'id': user_id,
            'name': user_name,
            'email': email
        }
    })
```

#### 2. Chat API

```python
@app.route('/api/chat/send', methods=['POST'])
@jwt_required()
def send_message():
    user_id = get_jwt_identity()
    message = request.json.get('message')
    conversation_id = request.json.get('conversation_id')
    
    # Process the message with your LLM
    response = llm_service.generate_response(message)
    
    return jsonify({
        'message': response,
        'timestamp': datetime.now().isoformat()
    })
```

#### 3. LLM Integration

```python
@app.route('/api/llm/generate', methods=['POST'])
@jwt_required()
def generate_text():
    prompt = request.json.get('prompt')
    options = request.json.get('options', {})
    
    # Call your LLM service
    response = llm_service.generate(prompt, **options)
    
    return jsonify({
        'content': response,
        'usage': {
            'prompt_tokens': len(prompt) // 4,
            'completion_tokens': len(response) // 4,
            'total_tokens': (len(prompt) + len(response)) // 4
        }
    })
```

#### 4. WebSocket Implementation

```python
from flask_socketio import SocketIO, emit, join_room

socketio = SocketIO(app, cors_allowed_origins="*")

@socketio.on('connect')
def handle_connect():
    # Authenticate user
    # ...
    print('Client connected')

@socketio.on('message')
def handle_message(data):
    message = data.get('message')
    conversation_id = data.get('conversation_id')
    
    # Process with LLM
    response = llm_service.generate_response(message)
    
    # Send response to the client
    emit('message', {
        'message': response,
        'conversation_id': conversation_id,
        'timestamp': datetime.now().isoformat()
    })
```

### Example LLM Service

```python
class LLMService:
    def __init__(self, model_name="gpt-3.5-turbo"):
        self.model_name = model_name
        # Initialize your LLM here
        
    def generate_response(self, prompt):
        # Call LLM API
        # ...
        return response
    
    def analyze_image(self, image_path, prompt=None):
        # Call vision model
        # ...
        return description
```

## 🔧 Configuration

### Environment Variables

For local development, you'll need to configure:

1. Edit `lib/core/config/api_config.dart` to point to your backend:

```dart
static const String _devBaseUrl = 'http://localhost:5000';
static const String _devSocketUrl = 'ws://localhost:5000';
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Credits

Developed by [Your Name/Team]

---

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
