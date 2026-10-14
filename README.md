# Kôrôba — prototype Flutter

## Lancer
1. Placez ce dossier, puis dans le dossier : `flutter create . --org ci.koroba --project-name koroba`
   (génère android/ et ios/ sans écraser lib/ ni pubspec.yaml). Supprimez ensuite `test/widget_test.dart`.
2. Ouvrez `android/app/src/main/AndroidManifest.xml` et ajoutez les lignes de `android_manifest_ajouts.xml` (micro, WhatsApp).
3. `flutter pub get`
4. `flutter run`

## Contenu
- Inscription / connexion (compte unique sur l'appareil), choix du métier
- Tableau de bord, commandes (nouvelle commande, fiche, statut), dépenses, bilan
- Pass Bilan : export PDF global (aperçu, enregistrement, partage) via les packages pdf + printing
- Relance WhatsApp (message pré-rédigé + Pay-Link simulé) depuis la fiche de commande
- Dictée vocale réelle en français (speech_to_text), avec repli démo
- Assistant vocal simulé
- Sauvegarde locale (shared_preferences) via `lib/store.dart`

## Limites du prototype
Mot de passe stocké en clair en local, reconnaissance vocale en français uniquement (internet requis en général), Pay-Link simulé, pas de Pay-Link réel ni de certification du PDF.
