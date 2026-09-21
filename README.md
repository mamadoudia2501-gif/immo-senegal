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

## Comptes

Tout est local (SharedPreferences). **Aucun SMS WhatsApp ni paiement réel.**

| Rôle | Comment entrer | Droits |
| --- | --- | --- |
| **Visiteur** | Aucun compte | Parcourir les annonces ; une demande ouvre le chat après confirmation du n° (OTP mock) |
| **Annonceur** | N’importe quel n° sénégalais `7x xx xx xx xx` + code WhatsApp de démo **123456** (affiché à l’écran pour ce rôle) | **4 annonces gratuites**, puis **100 FCFA** / annonce (tap de paiement mock) |
| **Administrateur** | Identifiants fournis **hors application** / au propriétaire. Ils ne sont pas affichés dans l’app ni dans ce README. | Publication **gratuite illimitée**, modération (activer / masquer) |

CTA **Publier une annonce** (accueil et profil) : mène à l’inscription si vous n’êtes pas connecté.

## Fonctionnalités du MVP

- **Accueil** : catégories Location / Vente / Terrain, **statuts / stories** (anneaux), biens en vedette, villes populaires, publication
- **Statuts** : stories image/vidéo mock, expiration **24 h**, abonnement annonceur **2 000 FCFA / mois** (30 jours, mock), validation admin avant visibilité publique
- **Profil annonceur** : page publique (tél., WhatsApp, adresse) à compléter après inscription
- **Recherche** : Location / Vente avec type de bien (appartement, villa, studio…), typologie **F2–F6** ou style de villa, loyer mensuel ou prix de vente en FCFA, ville (Dakar, Pikine, Rufisque…) et annonces récentes
- **Fiche bien** : détails, courtier associé, **Faire une demande** ou **Continuer la discussion**, lien vers le profil de l’annonceur
- **Courtiers** : annuaire, fiche, appel, WhatsApp (lien mock) et e-mail
- **Discussions** : après une demande, un **chat in-app** (messages texte, horodatage, statut Envoyé) est créé et persisté localement. Demandeur et annonceur écrivent dans l’app ; WhatsApp reste un raccourci secondaire. L’onglet **Mes discussions** liste les fils.
- **Profil** : visiteur, annonceur (quota, abo stories) ou admin, langue FR, devise FCFA
- **Publication** : formulaire terrain / location / vente, **1 à 4 photos** mock, quota puis paiement mock
- **Admin** : modération des annonces, liste des annonceurs, file des demandes de story

Les photos des annonces du catalogue d’exemple sont des **placeholders** colorés. Les annonces publiées stockent jusqu’à 4 photos mock (vues prédéfinies). Session, quota, annonces, stories et **discussions** sont persistés avec `shared_preferences`.

### Parcours discussion (auth)

La demande peut être rédigée sans compte. À l’envoi, la conversation est créée et un **code WhatsApp mock** est demandé sur le numéro saisi, puis le chat s’ouvre. Si vous êtes déjà connecté, nom et téléphone sont repris du compte et le chat s’ouvre tout de suite. Il faut le même numéro pour revoir le fil plus tard (onglet Discussions).

## Structure du projet

```
lib/
  main.dart                 # Point d’entrée
  app.dart                  # MaterialApp, providers, i18n FR
  core/                     # Thème, constantes, routes, formatage FCFA
  data/
    models/                 # Listing, Broker, Inquiry, Conversation, AppUser
    mock/sample_data.dart   # Annonces et courtiers d’exemple
    repositories/           # Accès données (mock + persistance locale)
  features/
    home / search / listings / brokers / inquiries / profile / auth / admin / stories / shell
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
