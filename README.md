# AI Chatbot Application

## Nouveautés: Support DeepSeek

Cette application intègre désormais le support de DeepSeek AI! Vous pouvez choisir entre:

1. **Mode Client**: L'application Flutter communique directement avec DeepSeek
2. **Mode Serveur**: Le backend Python communique avec DeepSeek 

### Configuration DeepSeek

Pour utiliser DeepSeek avec votre application:

1. Démarrez le service DeepSeek:
   ```
   python deepseek_service.py
   ```

2. Dans l'application, ouvrez le menu et sélectionnez **Configuration IA avancée**

3. Sous **Mode IA Client**, sélectionnez "DeepSeek"

4. Sous **Mode IA Serveur**, sélectionnez "DeepSeek" 

### Dépannage

Si vous rencontrez des problèmes, utilisez la page de diagnostic:

1. Ouvrez l'application et allez dans le menu Déboggage > Statut du système
2. Vérifiez que les services sont connectés et que les configurations sont correctes
3. Consultez les logs pour plus de détails sur d'éventuelles erreurs

# Guide de démarrage rapide - AI Chatbot Multimodal

## Prérequis
- Python 3.8+ 
- Flutter 3.0+
- Dépendances Python installées (`pip install -r requirements.txt`)
- Dépendances Flutter installées (`flutter pub get`)

## Démarrage simple

L'application est désormais prête à l'emploi! Suivez ces étapes :

1. **Méthode recommandée - Script de démarrage automatique**

   Exécutez simplement :
   ```bash
   ./start_app.sh
   ```
   Ce script démarre automatiquement le serveur backend Python et l'application Flutter.

2. **Démarrage manuel**

   Si vous préférez démarrer les composants manuellement :

   a. Démarrez le backend Python :
   ```bash
   cd cote_backend
   python main.py
   ```

   b. Dans un autre terminal, démarrez l'application Flutter :
   ```bash
   cd cote_frontend
   flutter run
   ```

## Utilisation

- Connectez-vous avec l'utilisateur par défaut :
  - Username: `test`
  - Password: `password`

- Créez une nouvelle conversation après connexion
- Envoyez des messages et profitez de votre chatbot!

## Configuration IA

L'application supporte plusieurs modes IA :

1. **Mode Local** : Réponses prédéfinies basées sur des modèles simples (par défaut)
2. **Mode DeepSeek** : Utilise l'API DeepSeek pour des réponses IA avancées
3. **Mode OpenAI** : Utilise l'API OpenAI (configuration requise)

Pour configurer le mode IA, utilisez le menu Configuration IA dans l'application.

## Dépannage

Si l'application ne démarre pas correctement :

1. Vérifiez que le backend est accessible sur http://localhost:8000
2. Assurez-vous que toutes les dépendances sont installées
3. Consultez la page "Statut du système" dans l'application pour diagnostiquer les problèmes
