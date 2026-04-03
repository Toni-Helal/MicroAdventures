# Guide néophyte — MicroAdventures

Ce guide explique la base de code de l’application iOS **MicroAdventures** en termes simples.

## 1) À quoi sert l’app ?

L’app aide l’utilisateur à choisir **une micro‑aventure réaliste pour aujourd’hui**, avec le moins de friction possible.

Concrètement :
- l’app propose un “pick du jour” ;
- on peut relancer (`Reroll Today`) ;
- on peut marquer l’activité comme faite (`Done`) ;
- la recommandation tient compte du contexte (temps disponible, énergie, météo, moment de la journée, distance, etc.).

## 2) Architecture générale (vision simple)

Pense l’app comme 3 couches :

1. **Entrée de l’app**
   - `MicroAdventuresApp.swift` lance l’écran principal `ContentView`.

2. **UI (écrans et composants SwiftUI)**
   - `ContentView.swift` : écran principal (carte + en‑tête + carte aventure).
   - `AdventureCardView.swift` : carte de la recommandation actuelle.
   - `AdventureDetailView.swift` : détails d’une aventure + ouverture Apple Maps.
   - `AdventureFiltersView.swift` : filtres (catégories, effort, énergie, météo, durée).
   - `NoPickCardView.swift` : état vide quand aucun résultat ne passe les filtres.

3. **Logique métier + données**
   - `ContentViewModel.swift` : cerveau de recommandation + persistance + gestion du pick du jour.
   - `Adventure.swift` : modèle `Adventure`, enums métier, et données de seed.
   - `UserLocationManager.swift` : accès localisation utilisateur (Core Location).

## 3) Le flux principal d’exécution

1. L’app démarre (`MicroAdventuresApp`) et affiche `ContentView`.
2. `ContentView` instancie `ContentViewModel`.
3. `ContentView` demande la localisation via `UserLocationManager`.
4. `ContentViewModel.ensureDailyPick(...)` vérifie s’il faut conserver le pick du jour ou recalculer.
5. La vue affiche l’aventure courante sur la carte + carte résumé.
6. Les actions utilisateur (filtres, reroll, done) modifient le `ViewModel`, qui persiste en local.

## 4) Les concepts importants à comprendre en premier

### a) `Adventure` (le modèle central)

Le struct `Adventure` contient :
- le contenu visible (titre, description, highlights, tips),
- les infos de décision (effort, énergie recommandée, fenêtre horaire, durée),
- les coordonnées géographiques (point de départ/arrivée, localisation principale),
- l’état utilisateur (`isCompleted`, dernières dates d’affichage/complétion).

C’est **l’unité de base** de toute la logique de recommandation.

### b) Le `ContentViewModel` (le cerveau)

Il gère notamment :
- les filtres actifs (catégories, effort, énergie, météo, durée),
- la sélection du pick quotidien,
- les fallbacks (exact match / near match / best available),
- la persistance locale (`UserDefaults`),
- l’impact de la localisation utilisateur sur le scoring.

Quand tu apprends le projet, c’est le fichier le plus important à lire après `Adventure.swift`.

### c) La persistance locale

Pas de backend ici :
- les aventures et le pick du jour sont stockés localement (`UserDefaults`).
- donc l’app fonctionne en mode “local-first”.

### d) L’UI SwiftUI orientée état

`ContentView` observe le `ViewModel` (`@StateObject` + `@Published`).
Dès qu’un état change dans le `ViewModel`, la vue se met à jour automatiquement.

## 5) Repères de lecture recommandés (ordre conseillé)

Pour monter en compétence rapidement :

1. `README.md` pour le contexte produit.
2. `Adventure.swift` pour comprendre la data et les enums.
3. `ContentViewModel.swift` pour la logique de sélection/recommandation.
4. `ContentView.swift` pour voir comment l’UI consomme ce `ViewModel`.
5. `AdventureDetailView.swift` et `AdventureFiltersView.swift` pour les écrans secondaires.
6. `UserLocationManager.swift` pour le lien avec Core Location.

## 6) Ce qu’il faut savoir avant de modifier

- Le comportement “pick du jour” est un choix produit central.
- Les filtres fonctionnent en mode “draft + apply”.
- Le fallback évite de renvoyer zéro résultat tant qu’il reste des candidats.
- Le dataset est un seed MVP (région de Colombes), donc attention aux conclusions de “qualité algo”.

## 7) Premiers exercices d’apprentissage (très concrets)

1. Ajouter une nouvelle aventure dans `AdventureSamples.all`.
2. Changer une pondération de scoring dans `ContentViewModel` et observer l’impact.
3. Ajouter une nouvelle option de filtre simple (ex: “indoor only”).
4. Afficher un champ supplémentaire dans `AdventureCardView`.
5. Vérifier que la persistance survit au redémarrage de l’app.

## 8) En résumé

Si tu ne dois retenir que 3 points :

1. **`Adventure.swift` définit le vocabulaire métier.**
2. **`ContentViewModel.swift` décide “quoi recommander”.**
3. **`ContentView.swift` orchestre l’expérience utilisateur autour de cette décision.**

