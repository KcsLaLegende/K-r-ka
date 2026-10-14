# agent.md — Prototype mobile Kôrôba

> Document de référence du prototype **Kôrôba** (Flutter / Android).
> Il s'adresse à tout développeur ou agent IA qui doit **comprendre, modifier, présenter ou étendre** le prototype.
> Dernière mise à jour : 14 octobre 2026 — version `0.1.0`.

---

## 1. Le projet en bref

**Kôrôba — « La Grande Sœur Digitale des Artisanes Ivoiriennes »** est un projet candidat au concours **Miss Informatique Côte d'Ivoire 2026** (problématique n°26 : gestion simplifiée des commandes et des finances).

- **Slogan :** « Mon activité, mon argent, mon avenir. »
- **Cible :** couturières, coiffeuses, restauratrices, artisanes et commerçantes de l'économie informelle. Partenaires visés : IMF (microfinances), coopératives féminines, associations.
- **Problèmes adressés :**
  1. Le carnet papier (acomptes oubliés, cahiers abîmés, litiges sur les soldes).
  2. Aucune distinction entre chiffre d'affaires et bénéfice net.
  3. Aucune preuve comptable à présenter pour obtenir un crédit.
- **4 fonctionnalités clés du projet complet :**
  1. Dictée vocale intelligente (français, puis langues locales).
  2. Calculateur de bénéfice net.
  3. Relances WhatsApp et Pay-Link (Wave / Orange Money).
  4. « Pass Bilan Microfinance » : rapport d'activité à présenter aux IMF.
- **Modèle économique envisagé :** abonnement B2B payé par les IMF, et 1 % de commission sur les liens d'encaissement Mobile Money.

Le prototype ne couvre qu'une **démonstration fonctionnelle** de ce projet (voir §2).

---

## 2. Périmètre du prototype

### Ce qui fonctionne réellement
| Fonctionnalité | Détail |
|---|---|
| Inscription / connexion | Un compte par appareil (nom, prénom, mot de passe) |
| Choix du métier | Couture, Coiffure, Restauration, Artisanat — adapte certains libellés |
| Tableau de bord | Recettes, dépenses, bénéfice estimé, commandes en cours, actions rapides |
| Commandes | Création, liste, fiche détaillée, passage en « terminée / soldée » |
| Dépenses | Ajout manuel, liste |
| Bilan | Cartes de synthèse + graphique en barres |
| Pass Bilan PDF | Génération, aperçu, enregistrement, partage |
| Relance WhatsApp | Ouvre WhatsApp avec un message pré-rédigé |
| Dictée vocale | Reconnaissance en français via le micro (`speech_to_text`) |
| Sauvegarde locale | Les données persistent après fermeture de l'app |

### Ce qui est simulé
- **Pay-Link** : le lien `https://pay.koroba.ci/p/<id>` est fictif, aucun paiement n'a lieu.
- **Mode démo de la dictée** : si la reconnaissance n'est pas disponible (ou via le bouton « Essayer la phrase d'exemple »), une phrase d'exemple est « reconnue ».

### Ce qui n'existe pas (encore)
- Serveur / base de données distante, comptes multiples, synchronisation.
- Reconnaissance des langues locales (baoulé, dioula…).
- Vraie certification du Pass Bilan (QR de vérification, signature).
- Sélecteur de mois sur le bilan (le bilan et le PDF portent sur **toutes** les données).
- Vrai paiement Mobile Money.
- Notifications de rappel, mode hors-ligne avancé, multi-appareils.

---

## 3. Stack technique

| Élément | Choix |
|---|---|
| Framework | Flutter (Dart ≥ 3.3), Material 3 |
| Cible principale | Android (le projet génère aussi iOS/web/desktop, non testés) |
| État | `provider` (`ChangeNotifier`) |
| Persistance | `shared_preferences` (JSON sérialisé) |
| Dates / formats | `intl` |
| PDF | `pdf` + `printing` |
| WhatsApp | `url_launcher` (liens `https://wa.me/...`) |
| Voix | `speech_to_text` (≥ 7.x, avec `SpeechListenOptions`) |

**`pubspec.yaml` — point d'attention :** il contient un `dependency_overrides` qui fixe `image: 4.5.4`. Sans lui, la compilation échoue (`decodeLazy` introuvable) car `image 4.11.0` (tirée par `pdf`/`printing`) est incompatible avec `archive 4.0.9`. À retirer seulement quand les dépendances se résolvent correctement (`archive` ≥ 4.4.0).

---

## 4. Arborescence

```
koroba/
├── pubspec.yaml                 # dépendances, assets, override image
├── README.md                    # démarrage rapide
├── agent.md                     # ce document
├── android_manifest_ajouts.xml  # lignes à copier dans AndroidManifest.xml
├── assets/images/
│   ├── couturiere.png           # illustration (accueil, liste vide)
│   └── silhouette.png           # logo / avatar (fond transparent)
└── lib/
    ├── main.dart                # point d'entrée + aiguillage (Root)
    ├── theme.dart               # couleurs, thème, helpers fcfa() et dateFr()
    ├── models.dart              # Metier, UserProfile, Commande, Depense
    ├── store.dart               # AppStore : état, persistance, calculs
    ├── widgets.dart             # KGradientBg, KLogo
    ├── relance.dart             # message WhatsApp, Pay-Link simulé, numéro
    ├── voice_parser.dart        # analyse de la phrase dictée
    ├── pdf_bilan.dart           # génération du PDF Pass Bilan
    └── screens/
        ├── auth.dart            # WelcomeScreen, AuthScreen, MetierScreen
        ├── home.dart            # HomeShell, DashboardTab, ProfilTab, StatCard
        ├── commandes.dart       # CommandesTab, NouvelleCommandeScreen, FicheCommandeScreen
        ├── finances.dart        # FinancesTab, showAjoutDepense()
        └── voice.dart           # VoiceScreen (assistant vocal)
```

Les dossiers `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` sont **générés par `flutter create`** : ce n'est pas du code métier. Le fichier `test/widget_test.dart` généré par défaut référence une classe `MyApp` qui n'existe pas : **il faut le supprimer**.

---

## 5. Architecture

### 5.1 Principe général
- **Une seule source de vérité : `AppStore`** (`lib/store.dart`). Tous les écrans lisent via `context.watch<AppStore>()` et écrivent via `context.read<AppStore>()`.
- Les écrans **ne touchent jamais** à `shared_preferences` directement.
- Chaque modification du store appelle `_save()` qui écrit sur le disque puis `notifyListeners()`, ce qui redessine les écrans concernés.
- Le jour où un backend sera branché, **seul `store.dart` devrait changer** (les écrans appellent des méthodes métier : `inscrire`, `addCommande`, etc.).

### 5.2 Navigation et aiguillage
`lib/main.dart` → `Root` observe le store et choisit l'écran affiché :

```
non connecté                         → WelcomeScreen  (→ AuthScreen en push)
connecté, métier non choisi          → MetierScreen
connecté, métier choisi              → HomeShell (4 onglets)
```

Il n'y a pas de routes nommées : la navigation se fait avec `Navigator.push`. Après une inscription ou une connexion réussie, `AuthScreen` fait `popUntil((r) => r.isFirst)` et c'est `Root` qui bascule tout seul grâce au store.

`HomeShell` (`screens/home.dart`) porte la `NavigationBar` à 4 onglets :

| Index | Onglet | Widget |
|---|---|---|
| 0 | Accueil | `DashboardTab` |
| 1 | Commandes | `CommandesTab` |
| 2 | Finances | `FinancesTab` (titre « Mon bilan ») |
| 3 | Profil | `ProfilTab` |

Le bouton « Voir mon bilan » du tableau de bord change d'onglet via le callback `onVoirBilan` (index 2).

### 5.3 Parcours utilisateur
```
Accueil (Commencer / Se connecter)
  → Inscription (nom, prénom, mot de passe)  |  Connexion (prénom, mot de passe)
  → Choix du métier
  → Tableau de bord
      ├─ Nouvelle commande → Fiche de commande (récapitulatif)
      │                        ├─ Relancer sur WhatsApp
      │                        └─ Marquer comme terminée et soldée
      ├─ Ajouter une dépense (boîte de dialogue)
      ├─ Voir mon bilan → onglet Finances → Télécharger mon rapport PDF
      └─ Parler à Kôrôba → dictée → commande pré-remplie
```

### 5.4 Modèles de données (`lib/models.dart`)

**`Metier`** (enum) : `couture`, `coiffure`, `restauration`, `artisanat`. Chaque valeur porte : `label`, `icone`, `couleur`, `matiereLabel` (Tissu / Produits / Ingrédients / Matière première) et `exemple` (texte d'aide du champ « type de commande »).

**`UserProfile`** : `nom`, `prenom`, `motDePasse` (en clair, voir §10), `metier?`.

**`Commande`** :
| Champ | Rôle |
|---|---|
| `id` | identifiant (microsecondes depuis l'epoch, en texte) |
| `cliente`, `description` | qui, et quoi (ex. « Robe de cérémonie ») |
| `prix`, `acompte` | montants en FCFA |
| `matiere`, `coutMatiere` | matière utilisée et son coût |
| `livraison`, `creeLe` | dates |
| `telephone` | facultatif, pour la relance WhatsApp (défaut `''`) |
| `terminee` | `true` = commande terminée et soldée |
| `reste` *(calculé)* | `max(prix − acompte, 0)` |
| `encaisse` *(calculé)* | `terminee ? prix : acompte` |

**`Depense`** : `id`, `libelle`, `montant`, `date`.

Toutes les classes ont `toJson()` / `fromJson()`. Pour ajouter un champ : l'ajouter au constructeur, à `toJson`, et à `fromJson` avec une **valeur par défaut** (`j['x'] ?? ...`) afin de ne pas casser les données déjà enregistrées.

### 5.5 Persistance (`shared_preferences`)
| Clé | Contenu |
|---|---|
| `user` | JSON de `UserProfile` |
| `connecte` | booléen (session ouverte) |
| `commandes` | liste de JSON (`StringList`) |
| `depenses` | liste de JSON (`StringList`) |

### 5.6 Règles de calcul (dans `AppStore`)
| Valeur | Formule |
|---|---|
| `recettes` | somme des `encaisse` de toutes les commandes |
| `totalDepenses` | somme des dépenses saisies **+** somme des `coutMatiere` de toutes les commandes |
| `benefice` | `recettes − totalDepenses` |
| `enCours` / `terminees` | nombre de commandes non terminées / terminées |
| `enAttente` | somme des `reste` des commandes **non** terminées |

Conséquence : le coût de la matière d'une commande est comptabilisé comme dépense dès la création de la commande, même si elle n'est pas encore payée.

---

## 6. Rôle de chaque fichier

### `lib/main.dart`
Initialise Flutter, charge le store (`await store.load()`), injecte-le avec `ChangeNotifierProvider.value`, lance `KorobaApp` (MaterialApp avec le thème de `buildTheme()`). Contient `Root` (aiguillage décrit en §5.2).

### `lib/theme.dart`
- `KColors` : palette (violet `0xFF6A1B9A`, rose `0xFFD81B8A`, orange `0xFFF59E0B`, vert, bleu, fond).
- `buildTheme()` : thème Material 3 (boutons arrondis « stadium », champs blancs arrondis, AppBar transparente).
- `fcfa(num)` : formate un montant (`15 000 FCFA`, séparateur d'espace).
- `dateFr(DateTime)` : `jj/MM/aaaa`.

> Les helpers `fcfa` et `dateFr` vivent ici par commodité. Pour un refactor propre, les déplacer dans un fichier `format.dart`.

### `lib/models.dart`
Modèles décrits en §5.4. Contient aussi `KColorsRef`, une **copie des couleurs** nécessaire parce que l'enum `Metier` exige des constantes. Si on change une couleur de la palette, penser à la changer aussi ici (dette technique connue).

### `lib/store.dart` — `AppStore`
| Méthode | Rôle |
|---|---|
| `load()` | lit les données au démarrage |
| `_save()` | écrit tout sur le disque et notifie les écrans |
| `inscrire(nom, prenom, mdp)` | crée le compte, **remet commandes et dépenses à zéro**, ouvre la session |
| `connecter(prenom, mdp)` | vérifie prénom (insensible à la casse) et mot de passe ; renvoie `bool` |
| `deconnecter()` | ferme la session (les données restent) |
| `setMetier(m)` | enregistre le métier choisi |
| `addCommande(...)` | crée une commande (en tête de liste) et la renvoie |
| `basculerTerminee(c)` | alterne terminée / en cours |
| `addDepense(libelle, montant)` | ajoute une dépense |
| getters | `recettes`, `totalDepenses`, `benefice`, `enCours`, `terminees`, `enAttente` |

### `lib/widgets.dart`
- `KGradientBg` : fond dégradé rose pâle → blanc (accueil, assistant vocal).
- `KLogo` : silhouette au turban + « Kôrôba » avec dégradé violet → rose.

### `lib/relance.dart`
- `payLinkSimule(commande)` : lien fictif `https://pay.koroba.ci/p/<8 derniers caractères de l'id>`.
- `messageRelance(commande, utilisateur)` : texte WhatsApp (nom de la cliente, commande, reste, acompte, livraison, lien).
- `numeroWhatsApp(saisie)` : ne garde que les chiffres, retire un préfixe `00`, et ajoute `225` si le numéro compte 10 ou 8 chiffres. Renvoie `null` si vide.
- `relancerWhatsApp(commande, utilisateur)` : ouvre `https://wa.me/<numéro>?text=...` (ou `https://wa.me/?text=...` sans numéro, WhatsApp laisse alors choisir le contact). Renvoie `false` en cas d'échec.

### `lib/voice_parser.dart`
`analyserDictee(texte)` → `DicteeResultat { cliente, montant, type }` (tous facultatifs, `vide` si rien trouvé).
- **Montant :** d'abord en chiffres (`5000`, `5 000`, `5.000`, `5 mille`, `5k`), sinon en mots français (« cinq mille », « deux cent cinquante », « quatre-vingt-dix »). Les montants en mots inférieurs à 100 sont ignorés pour éviter les faux positifs (« une robe »).
- **Cliente :** premier mot qui suit « de », « d' », « chez », « madame », « mme », « dame » ou « cliente », hors liste d'exclusion (`la`, `robe`, `francs`…).
- **Type :** ce qui suit « commande de / d' / du / des » (ex. « robe », « robe de mariage »).
- Limites : français uniquement, repérage du nom approximatif. Les listes `_mots` et `_arret` sont le point d'ajustement.

### `lib/pdf_bilan.dart`
`genererBilanPdf(store)` → `Future<Uint8List>`. Une page A4 (multi-pages si besoin) : en-tête Kôrôba / Pass Bilan, titulaire, période couverte (de la plus ancienne à la plus récente donnée), synthèse financière, tableau des commandes, tableau des dépenses (matières incluses), pied de page avec mention « données déclarées, non certifiées » et identifiant `KOR-xxxx`.
**Contrainte :** police PDF standard, donc **textes sans accents** et sans caractères hors Latin-1 (tirets longs, apostrophes courbes) pour éviter un rendu cassé. Pour avoir les accents partout, embarquer une police TTF dans `assets/` et la charger avec `pw.Font.ttf`.

### `lib/screens/auth.dart`
- `WelcomeScreen` : accueil (logo, illustration, boutons « Commencer » et « Se connecter »).
- `AuthScreen(inscription: bool)` : formulaire. Inscription : nom, prénom, mot de passe (≥ 4 caractères). Connexion : prénom + mot de passe ; message d'erreur si aucun compte ou identifiants faux.
- `MetierScreen` : grille de 4 métiers, bouton « Continuer » actif après sélection.

### `lib/screens/home.dart`
- `HomeShell` : barre de navigation à 4 onglets.
- `StatCard` : carte de statistique réutilisée (accueil et bilan).
- `DashboardTab` : bandeau de bienvenue, 4 cartes, actions rapides (Nouvelle commande, Ajouter une dépense, Voir mon bilan), bouton « Parler à Kôrôba ».
- `ProfilTab` : identité, métier, bouton « Se déconnecter ».

### `lib/screens/commandes.dart`
- `CommandesTab` : liste des commandes (état vide illustré), bouton flottant « Nouvelle commande ».
- `NouvelleCommandeScreen` : formulaire (cliente, téléphone, type, prix, acompte, **reste calculé en direct**, matière, coût de la matière, date de livraison). Paramètres optionnels `clienteInitiale`, `acompteInitial`, `descriptionInitiale` pour le pré-remplissage depuis la dictée. Validations : champs obligatoires, acompte ≤ prix. À l'enregistrement, remplace l'écran par la fiche.
- `FicheCommandeScreen` : récapitulatif complet ; si la commande n'est pas soldée, carte « Relance de paiement » (Pay-Link simulé + bouton WhatsApp) ; bouton « Marquer comme terminée et soldée » / « Rouvrir ».

### `lib/screens/finances.dart`
- `FinancesTab` : 5 cartes (recettes, dépenses, bénéfice, commandes terminées, paiements en attente), graphique en barres (Recettes, Dépenses, Bénéfice, Attente), bouton « Télécharger mon rapport PDF » (via `Printing.layoutPdf`), liste des dépenses saisies, bouton flottant « Dépense ».
- `showAjoutDepense(context)` : boîte de dialogue (libellé + montant), aussi appelée depuis le tableau de bord.

### `lib/screens/voice.dart`
`VoiceScreen` : micro cliquable.
1. `_demarrer()` initialise `SpeechToText`, choisit la langue (`fr_CI` si disponible, sinon la première `fr*`), puis écoute (25 s max, pause de 3 s).
2. Le texte reconnu s'affiche en direct ; `_terminer()` appelle `analyserDictee`.
3. Les éléments compris (cliente, montant, commande) sont affichés ; « Valider la commande » ouvre `NouvelleCommandeScreen` pré-rempli.
4. Si la reconnaissance est indisponible, ou via « Essayer la phrase d'exemple (démo) », `_lancerDemo()` simule la phrase *« Kôrôba, j'ai reçu 5000 francs d'Aminata pour sa commande de robe »*.

---

## 7. Où modifier quoi (guide rapide)

| Je veux… | Fichier / endroit |
|---|---|
| Changer les couleurs | `theme.dart` (`KColors`) **et** `models.dart` (`KColorsRef`) |
| Changer le logo ou les illustrations | `assets/images/` (mêmes noms de fichiers) ; usage dans `widgets.dart`, `auth.dart`, `home.dart`, `commandes.dart` |
| Ajouter un métier | `models.dart` (enum `Metier`) — l'écran de choix et les libellés s'adaptent seuls |
| Changer un libellé selon le métier | `models.dart` (`matiereLabel`, `exemple`) |
| Ajouter un champ à une commande | `models.dart` → `store.dart` (`addCommande`) → `commandes.dart` (formulaire + fiche) → éventuellement `pdf_bilan.dart` |
| Modifier une règle de calcul (bénéfice, recettes…) | `store.dart` (section « Calculs du bilan ») |
| Changer le message WhatsApp | `relance.dart` → `messageRelance` |
| Changer le format du lien de paiement | `relance.dart` → `payLinkSimule` |
| Améliorer la compréhension vocale | `voice_parser.dart` (`_mots`, `_arret`, expressions régulières) |
| Changer le comportement du micro (langue, durée) | `screens/voice.dart` → `_demarrer()` |
| Modifier le contenu ou la mise en page du PDF | `pdf_bilan.dart` |
| Ajouter un onglet | `screens/home.dart` (`pages` + `destinations`) |
| Ajouter un écran | nouveau fichier dans `screens/`, puis `Navigator.push` depuis l'écran appelant |
| Brancher un backend | `store.dart` uniquement (remplacer la lecture/écriture locale) |
| Changer le format des montants / dates | `theme.dart` (`fcfa`, `dateFr`) |

---

## 8. Installation et lancement

1. Dans le dossier du projet : `flutter create . --org ci.koroba --project-name koroba` (génère `android/`, `ios/`… sans écraser `lib/` ni `pubspec.yaml`).
2. **Supprimer** `test/widget_test.dart`.
3. **Windows :** activer le *Mode développeur* (`start ms-settings:developers`), sinon les plugins ne peuvent pas être construits (erreur « symlink support »).
4. Copier les lignes de `android_manifest_ajouts.xml` dans `android/app/src/main/AndroidManifest.xml` :
   - permissions `INTERNET`, `RECORD_AUDIO`, `BLUETOOTH` (≤ API 30), `BLUETOOTH_CONNECT`, avant `<application>` ;
   - bloc `<queries>` (service de reconnaissance vocale + liens `https`) à l'intérieur de `<manifest>`.
   Sans cela, **la dictée et la relance WhatsApp ne fonctionnent pas sur Android**.
5. `flutter pub get` puis `flutter run`, de préférence sur un **téléphone Android** : sur le web (Edge/Chrome), la voix, WhatsApp et le PDF se comportent différemment.

### Problèmes connus
| Symptôme | Cause / solution |
|---|---|
| `decodeLazy isn't defined for ZLibDecoder` | incompatibilité `image 4.11.0` / `archive 4.0.9` → garder `dependency_overrides: image: 4.5.4` |
| « Building with plugins requires symlink support » | activer le Mode développeur Windows |
| Avertissements `withOpacity` / `localeId`, `listenFor`, `pauseFor` | déjà corrigés (`withValues(alpha:)`, `SpeechListenOptions`) |
| Dictée muette ou « indisponible » | permission micro / manifeste manquants, pas d'internet, ou service Google de reconnaissance absent → utiliser le mode démo |
| Erreur dans `test/widget_test.dart` | supprimer ce fichier |

---

## 9. Pistes d'évolution (par ordre de valeur pour le projet)

1. **Backend et comptes multiples** (Firebase, Supabase ou API maison) : remplacer la couche locale du `AppStore`, sécuriser les mots de passe (hachage côté serveur).
2. **Pass Bilan certifié** : filtre par mois / période, identifiant vérifiable, QR de vérification côté IMF, signature.
3. **Vrai Pay-Link** : intégration des API Wave / Orange Money, suivi automatique des paiements reçus.
4. **Langues locales** : reconnaissance vocale en baoulé / dioula (modèle dédié ou service tiers), retours audio.
5. **Espace IMF** (B2B) : tableau de bord des artisanes suivies, scoring de crédit.
6. **Confort** : rappels de livraison, édition / suppression des commandes et dépenses, export CSV, mode hors-ligne avec synchronisation, accents dans le PDF via police embarquée.
7. **Qualité** : tests unitaires sur `AppStore`, `voice_parser.dart` et `numeroWhatsApp` (fonctions pures, faciles à tester).

---

## 10. Limites connues et dettes techniques

- **Sécurité :** le mot de passe est stocké **en clair** dans `shared_preferences`. Acceptable pour une démo, **inacceptable en production**.
- **Compte unique par appareil :** s'inscrire de nouveau **écrase le compte et efface les commandes et dépenses**.
- **Pas d'édition ni de suppression** de commande ou de dépense.
- **Bilan global :** pas de filtre par mois, contrairement à la maquette.
- **Couleurs dupliquées** (`KColors` et `KColorsRef`).
- **Helpers de formatage** placés dans `theme.dart`.
- **Dictée :** dépend du service de reconnaissance du téléphone (internet en général) ; le repérage du nom de la cliente est heuristique.
- **PDF :** textes sans accents (police standard).
- **Jamais compilé ni testé automatiquement** côté génération : la validation s'est faite sur la machine du développeur ; aucune suite de tests n'existe.

---

## 11. Consignes pour un agent IA qui reprend le projet

- **Lire d'abord** ce fichier, puis `store.dart` et `models.dart` : ils contiennent toute la logique métier.
- Respecter l'architecture : **les écrans passent par `AppStore`**, jamais directement par le stockage.
- Toute donnée persistée nouvelle doit avoir une **valeur par défaut au chargement** (compatibilité avec les données existantes).
- **Avant de modifier un fichier existant**, demander au développeur le contenu exact du fichier concerné plutôt que de le deviner (il l'enverra).
- **Pour une nouvelle fonctionnalité**, proposer d'abord un plan (existant, fichiers touchés, limites), et ne coder qu'après validation.
- Écrire les réponses et les textes de l'interface **en français**.
- Pour **présenter** le prototype : suivre le parcours du §5.3 en insistant sur trois moments forts — la **dictée vocale** qui pré-remplit une commande, la **fiche de commande** avec relance WhatsApp, et le **Pass Bilan PDF**. Annoncer honnêtement ce qui est simulé (Pay-Link) et ce qui reste à construire (§2 et §9).
- Les visuels de référence sont la maquette à 6 écrans (accueil, choix du métier, tableau de bord, nouvelle commande, assistant vocal, bilan financier) et la présentation du projet *« KÔRÔBA — 1Miss Informatique 2026 »*.
