# Intégration de DeepSeek AI

Ce document explique comment configurer et utiliser DeepSeek AI avec votre application de chatbot.

## Configuration

1. **Installez les dépendances Python:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Obtenez une clé API DeepSeek:**
   - Inscrivez-vous sur [DeepSeek AI](https://deepseek.com)
   - Obtenez une clé API dans votre tableau de bord

3. **Configurez votre clé API:**
   - Ouvrez le fichier `deepseek_service.py`
   - Remplacez `<DeepSeek API Key>` par votre clé API réelle

## Démarrer le service DeepSeek

Pour démarrer le service DeepSeek qui servira d'intermédiaire entre votre application Flutter et l'API DeepSeek:

```bash
python deepseek_service.py
```

Le service sera disponible à l'adresse `http://localhost:8088`.

## Utilisation dans l'application Flutter

1. Ouvrez l'application
2. Allez dans Paramètres > Sélection du modèle IA
3. Sélectionnez "DeepSeek"

## Dépannage

- **Erreur de connexion**: Assurez-vous que le service Python est en cours d'exécution
- **Erreur d'authentification**: Vérifiez que votre clé API est correcte
- **Réponses lentes**: Le modèle DeepSeek peut prendre plus de temps pour générer des réponses que les modèles plus légers

## Modèles disponibles

Par défaut, nous utilisons `deepseek-chat`, mais vous pouvez modifier cela dans le fichier `llm_service.dart` selon les modèles disponibles dans votre abonnement DeepSeek.

## Personnalisation des requêtes

Pour personnaliser davantage les requêtes envoyées à DeepSeek (comme ajuster la température ou définir un message système différent), modifiez la méthode `_getDeepSeekResponse` dans `llm_service.dart`.
