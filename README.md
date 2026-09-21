# Immo Sénégal

Application mobile Flutter (iOS et Android) pour le marché immobilier sénégalais : locations, ventes, terrains, courtiers, et publication d’annonces par compte.

Ce dépôt contient un **MVP hors ligne** : données d’exemple, interface en français, prix en **FCFA**. Aucun backend, WhatsApp réel ou prestataire de paiement n’est requis.

## Prérequis

- [Flutter](https://docs.flutter.dev/get-started/install) **3.41.6+** (Dart **3.11.4+**, SDK `>=3.11.0 <4.0.0`)
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

## Comptes de démo

Tout est local (SharedPreferences). **Aucun SMS WhatsApp ni paiement réel.**

| Rôle | Comment entrer | Droits |
| --- | --- | --- |
| **Visiteur** | Aucun compte | Parcourir les annonces, faire une demande |
| **Annonceur** | N’importe quel n° sénégalais `7x xx xx xx xx` + code **123456** | **4 annonces gratuites**, puis **100 FCFA** / annonce (tap de paiement mock) |
| **Administrateur** | `77 000 00 00` (`+221 77 000 00 00`) + code **123456** | Publication **gratuite illimitée**, modération (activer / masquer) |

Le code WhatsApp de test est toujours affiché à l’écran : **123456**.

CTA **Publier une annonce** (accueil et profil) : mène à l’inscription si vous n’êtes pas connecté.

## Fonctionnalités du MVP

- **Accueil** : catégories Location / Vente / Terrain, biens en vedette, villes populaires, publication
- **Recherche** : filtre par ville, type de bien et fourchette de prix (FCFA)
- **Fiche bien** : détails, courtier associé, bouton **Faire une demande**
- **Courtiers** : annuaire, fiche, appel, WhatsApp (lien mock) et e-mail
- **Demandes** : formulaire (nom, téléphone sénégalais, message) enregistré **localement**
- **Profil** : visiteur, annonceur (quota) ou admin, langue FR, devise FCFA
- **Publication** : formulaire terrain / location / vente, quota puis paiement mock

Les photos des annonces sont des **placeholders** colorés (pas de CDN). Session, quota et annonces utilisateur sont persistés avec `shared_preferences`.

## Structure du projet

```
lib/
  main.dart                 # Point d’entrée
  app.dart                  # MaterialApp, providers, i18n FR
  core/                     # Thème, constantes, routes, formatage FCFA
  data/
    models/                 # Listing, Broker, Inquiry, AppUser
    mock/sample_data.dart   # Annonces et courtiers d’exemple
    repositories/           # Accès données (mock + persistance locale)
  features/
    home / search / listings / brokers / inquiries / profile / auth / admin / shell
  shared/widgets/           # Cartes, badges, CTA publication
```

## Prochaines étapes

Hors périmètre de cette version :

1. Vrai WhatsApp / OTP et backend d’auth
2. PSP réel (Wave, Orange Money, carte)
3. Cartes (clé SDK Maps à provisionner)
4. Notifications push et back-office distant

## Licence

Usage interne / projet pédagogique tant qu’aucune licence n’est précisée.
