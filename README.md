# Immo Sénégal

Application mobile Flutter (iOS et Android) pour le marché immobilier sénégalais : locations, ventes, terrains, courtiers, et publication d’annonces par compte.

Ce dépôt contient un **MVP** : interface en français, prix en **FCFA**. Par défaut tout tourne **hors ligne** (mock `shared_preferences`). Un backend **Supabase (test)** peut être branché via `--dart-define` sans mettre de secrets dans le code.

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

Sans variables Supabase, l’app utilise le **mock local**. Pour le projet test distant, voir [Supabase (environnement test)](#supabase-environnement-test).

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
- **Cycle de vie** : l’annonceur (et l’admin) peut **Marquer Loué** (location), **Marquer Vendu** (vente / terrain) ou **Supprimer** (confirmation). Loué / vendu : badge dans **Mes annonces**, retiré des recherches et du fil public. Supprimée : disparue partout.
- **Admin** : modération des annonces, liste des annonceurs, file des demandes de story

Les photos des annonces du catalogue d’exemple sont des **placeholders** colorés. Les annonces publiées stockent jusqu’à 4 photos mock (vues prédéfinies). Session, quota, annonces, stories et **discussions** sont persistés avec `shared_preferences`.

### Parcours discussion (auth)

La demande peut être rédigée sans compte. À l’envoi, la conversation est créée et un **code WhatsApp mock** est demandé sur le numéro saisi, puis le chat s’ouvre. Si vous êtes déjà connecté, nom et téléphone sont repris du compte et le chat s’ouvre tout de suite. Il faut le même numéro pour revoir le fil plus tard (onglet Discussions).

## Supabase (environnement test)

Le mock local reste le défaut. Quand `SUPABASE_URL` et `SUPABASE_ANON_KEY` (clé **anon / public** uniquement) sont fournis au compile, l’app bascule sur Supabase. **Ne jamais** mettre la clé `service_role` dans l’app, le README ou git.

### Étapes pour Mamadou (projet test)

1. Créer un projet gratuit sur [supabase.com](https://supabase.com) (région proche, ex. `eu-west`).
2. **Project Settings → API** : copier l’**URL** et la clé **`anon` `public`** (publishable). Ignorer `service_role`. L’app la lit via `SUPABASE_ANON_KEY`.
3. **SQL Editor** : coller et exécuter le fichier  
   `supabase/migrations/20260921180000_init.sql`  
   (tables `profiles`, `listings` + photos, `inquiries`, `conversations`, `chat_messages`, `stories`, `story_requests` (vue), `story_subscriptions`, RLS, buckets `listing-photos` et `story-media`).
4. **Authentication → Providers** : activer **Phone** (OTP) pour le login réel. En attendant, le mock local (`flutter run` sans dart-define) reste utilisable.
5. **Storage** : les buckets sont créés par le SQL. Vérifier `listing-photos` (public, images, 5 Mo) et `story-media` (public, image/vidéo, 20 Mo).
6. Compte **admin** : créer d’abord l’utilisateur dans Authentication, puis dans SQL (en remplaçant l’UUID, **sans** coller de numéro ni d’OTP dans le dépôt) :

```sql
update public.profiles
set role = 'admin'
where id = '<uuid-auth-du-compte>';
```

7. Lancer l’app **test** :

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

Pour forcer le mock malgré les clés : `--dart-define=IMMO_FORCE_LOCAL=true`.

### RLS (rappel)

- Annonceur : CRUD sur **ses** annonces (`owner_id = auth.uid()`).
- Public (`anon`) : lecture des annonces `status = 'active'` et `is_active = true` seulement (loué / vendu / supprimée invisibles).
- Admin : politiques `is_admin()` (rôle en base, pas dans l’app).
- Chat : lecture/écriture **participants** uniquement (admin en lecture).
- Stories publiques : `status = 'approved'` et `expires_at > now()`.

Les tests CI et `flutter test` n’ont pas de dart-define : ils restent sur le mock.

## Structure du projet

```
lib/
  main.dart                 # Point d’entrée
  app.dart                  # MaterialApp, providers, i18n FR
  core/                     # Thème, constantes, routes, formatage FCFA
  data/
    models/                 # Listing, Broker, Inquiry, Conversation, AppUser
    mock/sample_data.dart   # Annonces et courtiers d’exemple
    repositories/           # Mock locaux (SharedPreferences)
    supabase/               # Implémentations Supabase (si dart-define)
    mappers/                # Mapping lignes SQL ↔ modèles
    backend/                # Détection local vs Supabase
  features/
    home / search / listings / brokers / inquiries / profile / auth / admin / stories / shell
  shared/widgets/           # Cartes, badges, CTA publication
supabase/migrations/        # Schéma SQL + RLS + buckets
```

## Prochaines étapes

Hors périmètre immédiat :

1. Brancher les secrets du projet test Mamadou (clé anon seulement) et valider Phone OTP
2. Upload réel vers les buckets (4 photos max déjà côté SQL)
3. PSP réel (Wave, Orange Money, carte)
4. Cartes (clé SDK Maps à provisionner)
5. Notifications push

## Licence

Usage interne / projet pédagogique tant qu’aucune licence n’est précisée.
