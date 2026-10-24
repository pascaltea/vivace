# Tests

Servir l'app en local depuis la racine du dépôt : `python3 -m http.server 8765 --bind 127.0.0.1`

- `python3 tests/e2e_seance.py` : un robot fait l'accueil, un bilan complet puis une séance du jour, change les réglages et vérifie qu'aucune erreur ne survient.
- `python3 tests/accessibilite.py` : scan axe-core (WCAG 2.1 AA) de tous les écrans en clair et en sombre, et des zones tactiles de moins de 44 px. Prérequis : `cd tests && npm i axe-core@4.10.2`.

Prérequis communs : `pip install playwright && playwright install chromium`.
