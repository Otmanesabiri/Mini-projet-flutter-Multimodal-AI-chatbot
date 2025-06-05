# TODO List – Développement d'un Chatbot Multimodal Flutter utilisant DeepSeek LLM

## 1. Initialisation du Projet Flutter
- [ ] Créer un nouveau projet Flutter :  
  `flutter create DWM_bot`
- [ ] Ouvrir et explorer la structure du projet, notamment `main.dart`.

## 2. Authentification (Login)
- [ ] Créer une page de login séparée (`login_page.dart`) comme `StatelessWidget`.
- [ ] Ajouter deux champs (`TextFormField`): utilisateur et mot de passe, avec `TextEditingController`.
- [ ] Ajouter bouton de connexion (`ElevatedButton`) avec logique simple (ex: admin/1234).
- [ ] Gérer la navigation vers la page du chatbot après connexion réussie.

## 3. Navigation
- [ ] Déclarer les routes (`'/'` pour login, `'/bot'` pour chatbot) dans `MaterialApp`.
- [ ] Utiliser `Navigator.pushNamed(context, '/bot')` après connexion.
- [ ] Ajouter un bouton de déconnexion sur la page chatbot (`IconButton`).

## 4. Page Chatbot (UI)
- [ ] Créer la page chatbot (`chatbot.dart`) en `StatefulWidget`.
- [ ] Définir une liste dynamique pour les messages (avec `role` et `content`).
- [ ] Utiliser `ListView.builder` pour afficher la liste des messages.
- [ ] Ajouter la zone de saisie (`TextFormField`) + bouton d’envoi (`IconButton`).
- [ ] Gérer l’ajout de messages utilisateur et assistant à la liste.
- [ ] Personnaliser l’affichage des messages selon le rôle (alignement/couleur).

## 5. Défilement Automatique
- [ ] Ajouter un `ScrollController` et l’attacher au `ListView`.
- [ ] Utiliser `scrollController.jumpTo(scrollController.position.maxScrollExtent)` après ajout de message.

## 6. Interaction avec le LLM (DeepSeek)
- [ ] Ajouter la dépendance `http` dans `pubspec.yaml`.
- [ ] Créer un service Dart pour l’API DeepSeek :
    - [ ] Définir l’URL : `https://api.deepseek.com/v1/chat/completions` (à vérifier selon la doc DeepSeek).
    - [ ] Gérer les headers :
      - `Content-Type: application/json`
      - `Authorization: Bearer <DeepSeek API Key>`
    - [ ] Construire le corps de la requête avec :
      - `model: "deepseek-chat"`
      - `messages: List<Map>`, chaque message ayant `role` et `content`.
      - Envoyer tout l’historique de la conversation à chaque requête.
    - [ ] Utiliser `http.post()` pour envoyer la requête, parser la réponse JSON.
    - [ ] Extraire la réponse assistant (ex: `response['choices'][0]['message']['content']`).
    - [ ] Ajouter la réponse à la liste des messages et rafraîchir l’UI.

## 7. Multimodalité (Extension)
- [ ] Préparer la gestion des messages images/audio (si DeepSeek LLM le supporte) :
    - [ ] Ajouter la possibilité de joindre/envoyer des images (ex: via `ImagePicker`).
    - [ ] Adapter la liste de messages pour afficher des images ou du texte.
    - [ ] Prévoir l’encodage et l’envoi des images si l’API DeepSeek le permet.

## 8. Gestion des Erreurs
- [ ] Gérer les erreurs HTTP et afficher un message à l’utilisateur.
- [ ] Prévoir une indication de chargement lors de la requête.

## 9. Finitions
- [ ] Nettoyer le code, factoriser les widgets réutilisables.
- [ ] Styliser l’application (thème, bulles de chat, etc.).
- [ ] Tester l’application sur différents appareils.

---

### Exemples de code pour interaction avec DeepSeek

```python
# Python (pour référence, à adapter en Dart)
from openai import OpenAI

client = OpenAI(api_key="<DeepSeek API Key>", base_url="https://api.deepseek.com")

response = client.chat.completions.create(
    model="deepseek-chat",
    messages=[
        {"role": "system", "content": "You are a helpful assistant"},
        {"role": "user", "content": "Hello"},
    ],
    stream=False
)
print(response.choices[0].message.content)
```

En Dart (pseudo-code Flutter) :
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<String> sendToDeepSeek(List<Map> messages) async {
  final url = Uri.parse('https://api.deepseek.com/v1/chat/completions');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer <DeepSeek API Key>',
  };
  final body = jsonEncode({
    'model': 'deepseek-chat',
    'messages': messages,
    'stream': false,
  });
  final response = await http.post(url, headers: headers, body: body);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  } else {
    throw Exception('Erreur DeepSeek: ${response.body}');
  }
}
```

---

**Conseil** : Pour chaque message envoyé, l’historique complet de la conversation doit être renvoyé à l’API DeepSeek.

---

### Pour aller plus loin
- Ajouter la gestion du multimodal (images/audio) si l’API DeepSeek le permet.
- Ajouter la persistance locale de l’historique des conversations (SQLite, Hive…).
- Sécuriser la gestion de la clé API (ne pas la mettre en dur dans l’application).

---

> Ce plan permet de développer un chatbot Flutter simple (et évolutif) interfacé avec DeepSeek LLM, et sert de base pour ajouter des fonctionnalités multimodales.