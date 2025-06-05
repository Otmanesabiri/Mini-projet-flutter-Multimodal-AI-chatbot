#!/bin/bash

echo "Checking AI services connectivity..."

# Test local backend
echo "Testing connection to local backend..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Local backend is accessible"
else
    echo "❌ Local backend is not accessible. Make sure your FastAPI server is running."
    echo "Run 'cd cote_backend && python main.py' to start it."
fi

# Test DeepSeek API
echo "Testing connection to DeepSeek API..."
curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer sk-c1211bf1366946d3a67b7c967bce1dc6" https://api.deepseek.com/v1/chat/completions > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ DeepSeek API is accessible"
else
    echo "❌ DeepSeek API is not accessible."
    echo "Check your API key or network connection."
    echo "The app will use the fallback local response generator."
fi

echo "Done."
chmod +x check_ai_services.sh
