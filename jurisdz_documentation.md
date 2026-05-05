# Documentation Technique et Fonctionnelle - JURISDZ

## 1. Introduction
**JURISDZ** est une plateforme mobile innovante développée avec **Flutter** et **Firebase**, destinée à faciliter l'accès aux services juridiques en Algérie. Elle connecte les citoyens algériens avec des avocats certifiés, tout en intégrant un assistant juridique basé sur l'Intelligence Artificielle (Google Gemini).

---

## 2. Architecture du Système
L'application repose sur une architecture moderne sans serveur (Serverless) :
*   **Frontend :** Flutter (Dart) - Offre une interface fluide, réactive et multiplateforme (iOS / Android).
*   **Backend (BaaS) :** Firebase
    *   **Firebase Authentication :** Gestion des inscriptions, connexions, et vérification par e-mail (Email Verification).
    *   **Cloud Firestore :** Base de données NoSQL en temps réel pour stocker les profils, les consultations, les demandes et les messages.
*   **Intelligence Artificielle :** API Google Gemini (`gemini-1.5-flash-latest`) pour l'assistance juridique automatisée.

---

## 3. Rôles et Acteurs
Le système isole strictement trois types d'utilisateurs pour garantir la sécurité et la cohérence des données :

1.  **Utilisateur Simple (Client) :** Peut rechercher des avocats, poser des questions à l'IA, publier des demandes juridiques et contacter des avocats.
2.  **Avocat :** Possède un profil détaillé (spécialité, wilaya, expérience). Il peut répondre aux consultations publiques, recevoir des messages privés et accumuler des points d'activité.
3.  **Administrateur :** Accède à un tableau de bord privé (Dashboard) pour valider ou révoquer l'identité des avocats inscrits (Badge de vérification).

---

## 4. Fonctionnalités Clés

### A. Intelligence Artificielle (AI Assistant)
*   Un chatbot intelligent capable d'analyser les requêtes des utilisateurs.
*   **Prompt Engineering :** L'IA est restreinte au domaine juridique algérien. Si l'utilisateur pose une question hors sujet (ex: "Salut", "Quelle est la météo ?"), l'IA est programmée pour recadrer la discussion vers le droit.

### B. Système de Consultations et Demandes (Feed)
*   **Flux public :** Les utilisateurs peuvent publier des questions anonymes ou des requêtes spécifiques.
*   **Filtre intelligent :** Les avocats voient les requêtes correspondant à leurs spécialités. Un avocat généraliste voit toutes les requêtes.
*   **Confidentialité :** Un utilisateur ne voit pas ses propres requêtes dans le flux public pour éviter toute confusion.

### C. Recherche et Filtrage Avancés
*   Les clients peuvent rechercher un avocat par **Wilaya** et par **Spécialité**.
*   **Badge de Confiance :** Les avocats validés par l'administration arborent un badge bleu/doré (Vérifié).

### D. Messagerie en Temps Réel (Chat)
*   Intégration d'un système de chat en direct entre le client et l'avocat utilisant les `Streams` de Firestore.
*   Historique des conversations conservé et accessible via la boîte de réception (Inbox).

### E. Panneau d'Administration (Admin Dashboard)
*   Connexion sécurisée cachée dans l'interface d'accueil.
*   Permet la gestion de l'état de vérification (`isVerified`) des avocats en un clic.
*   Intègre un "Seeder" pour générer des données factices (avocats virtuels) à des fins de test et de démonstration.

---

## 5. Sécurité et Optimisation

*   **Vérification des Emails :** Impossible d'accéder à l'application sans valider l'adresse email (protection contre les faux comptes).
*   **Validation des Formulaires (Regex) :** Le numéro de téléphone algérien doit obligatoirement commencer par 05, 06 ou 07 et contenir 10 chiffres. Les mots de passe exigent un minimum de 8 caractères.
*   **Mise en Cache des Images :** Utilisation de `cached_network_image` pour sauvegarder les photos de profil localement, ce qui réduit la consommation de données et accélère le chargement des listes.
*   **Séparation des collections Firestore :** Les `users` et les `lawyers` sont stockés dans des collections séparées, et la logique d'authentification empêche le croisement des rôles.

---
*Ce document résume le fonctionnement technique du projet et est prêt à être inclus dans le mémoire de fin d'études (PFE).*
