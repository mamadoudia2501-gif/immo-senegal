# Immo Sénégal

Application mobile Flutter (iOS et Android) pour le marché immobilier sénégalais : locations, ventes, terrains et mise en relation avec des courtiers.

Ce dépôt contient un **MVP hors ligne** : données d’exemple (Dakar, Petite-Côte, régions), interface en français, prix en **FCFA**. Aucun backend n’est requis.

## Prérequis

- [Flutter](https://docs.flutter.dev/get-started/install) 3.13+ (Dart 3)
- Xcode (pour iOS) ou Android Studio / SDK (pour Android)

Vérifiez l’installation :

```bash
flutter doctor
```

## Lancer l’application

À la racine du dépôt :

```bash
flutter pub get
flutter run
```

Choisir un simulateur iOS, un émulateur Android, ou un appareil physique. Pour cibler une plateforme :

```bash
flutter run -d ios
flutter run -d android
```

Un navigateur Chrome peut servir d’aperçu (`flutter run -d chrome`), mais le produit visé reste iOS et Android.

Analyse statique :

```bash
flutter analyze
flutter test
```

## Fonctionnalités du MVP

- **Accueil** : catégories Location / Vente / Terrain, biens en vedette, villes populaires
- **Recherche** : filtre par ville, type de bien et fourchette de prix (FCFA)
- **Fiche bien** : détails, courtier associé, bouton **Faire une demande**
- **Courtiers** : annuaire, fiche, appel, WhatsApp (lien mock) et e-mail
- **Demandes** : formulaire (nom, téléphone sénégalais, message) enregistré **localement** sur l’appareil
- **Profil** : mode visiteur, langue FR, devise FCFA

Les photos des annonces sont des **placeholders** colorés (pas de CDN). Les demandes sont persistées avec `shared_preferences` : elles survivent à un redémarrage de l’app, pas à une réinstallation.

## Structure du projet

```
lib/
  main.dart                 # Point d’entrée
  app.dart                  # MaterialApp, providers, i18n FR
  core/                     # Thème, constantes, routes, formatage FCFA
  data/
    models/                 # Listing, Broker, Inquiry
    mock/sample_data.dart   # Annonces et courtiers d’exemple
    repositories/           # Accès données (mock + persistance locale)
  features/
    home/ recherche / listings / brokers / inquiries / profile / shell
  shared/widgets/           # Cartes, badges, états vides
```

L’architecture est volontairement simple à étendre : les repositories pourront plus tard appeler une API sans changer les écrans.

## Prochaines étapes

Hors périmètre de cette version :

1. **Auth** — comptes locataires / acheteurs et espace courtier
2. **Cartes** — carte des biens (clé SDK Maps à provisionner)
3. **Backend** — API réelle, photos, messagerie, recherche full-text
4. Paiements, notifications push, back-office d’administration

## Licence

Usage interne / projet pédagogique tant qu’aucune licence n’est précisée.
