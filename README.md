# Hibi 日々

« Jour après jour ». Dix minutes par jour pour garder l'esprit vif. Une web app d'entraînement cognitif pour les 40 ans et plus, gratuite, sans publicité, installable sur l'écran d'accueil.

Quatre exercices adaptatifs :

| Exercice | Capacité travaillée | Unité |
|---|---|---|
| Champ visuel | Vitesse de traitement | ms (plus bas = mieux) |
| Séquence | Mémoire de travail | cases |
| Aiguillage | Flexibilité mentale (6 niveaux) | points |
| Liste de courses | Mémoire des événements | mots |

Champ visuel ouvre chaque séance : c'est le type d'entraînement associé à une baisse du risque de démence dans l'étude ACTIVE (suivi sur 20 ans).

## Installer sur un téléphone

- **iPhone** : ouvrir le lien dans Safari, bouton Partager, puis « Sur l'écran d'accueil ».
- **Android** : ouvrir le lien dans Chrome, menu ⋮, puis « Installer l'application ».

## Groupes famille

L'onglet Famille permet de créer un groupe, d'inviter ses proches avec un code de 8 caractères et de suivre la régularité et les courbes de chacun. Sans compte ni e-mail : le code du groupe sert de clé.

### Activer le partage (une seule fois)

1. Créer un projet gratuit sur [supabase.com](https://supabase.com), région Europe.
2. Dans **SQL Editor**, coller le contenu de `supabase/schema.sql` et cliquer sur **Run**.
3. Dans **Project Settings → API**, copier la **Project URL** et la clé **anon public** dans `config.js`.

Sans cette étape, l'app fonctionne normalement mais les résultats restent sur chaque appareil.

Pour la sauvegarde personnelle (code de 12 caractères, sans compte), exécuter aussi `supabase/schema-v2-sauvegarde.sql` si la base a été créée avant la version 5.0.

## Programme

Inspiré de l'étude ACTIVE : 8 semaines de fondation (5 séances par semaine), puis entretien (2 par semaine) et une semaine de rappel aux 3e, 6e et 12e mois. Les rappels peuvent être ajoutés à l'agenda depuis les Réglages.

## Mise en ligne

Publié avec GitHub Pages depuis la branche `main`, dossier racine (Settings → Pages). Après chaque modification de l'app, incrémenter `VERSION` dans `sw.js` pour que les téléphones récupèrent la nouvelle version.

## Données

- Sur l'appareil : historique, niveaux et réglages (localStorage).
- Dans le groupe (si activé) : prénom, exercice, score et date de chaque partie. Rien d'autre.
- Quitter un groupe (Réglages) efface vos résultats partagés.

Design « épure » : un seul objet par écran (un disque d'aluminium qui se remplit au fil de la séance), monochrome, une seule couleur d'accent, mode sombre soigné.

Hibi n'est pas un dispositif médical.

## Voix

Les consignes sont des enregistrements (dossier `audio/`), générés avec la voix française Kokoro « Siwis », débit posé, intonation retravaillée (montée légère entre les phrases, descente nette en fin de consigne). Si une phrase est modifiée dans le code sans être régénérée, l'app revient à la voix du téléphone pour cette phrase.
