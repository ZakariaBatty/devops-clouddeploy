# Démonstration live CI → Local CD — 2 minutes

Ce guide correspond aux workflows actuellement présents dans `.github/workflows/ci.yml` et `.github/workflows/local-cd.yml`. Il ne déclenche ni AWS ni le workflow EC2.

## Préparation avant la soutenance

Ouvrir ces onglets avant de commencer, déjà positionnés sur les informations utiles :

1. **Dépôt GitHub — onglet Actions** : `https://github.com/<owner>/<repository>/actions`.
2. **Page du workflow CloudDeploy CI** : `https://github.com/<owner>/<repository>/actions/workflows/ci.yml`.
3. **Une exécution réussie de CloudDeploy CI** dont l’événement est `push` et la branche `main`, pas une exécution de pull request.
4. **Page du workflow CloudDeploy Local CD** : `https://github.com/<owner>/<repository>/actions/workflows/local-cd.yml`.
5. **L’exécution Local CD créée automatiquement après cette CI**, avec le même commit SHA.
6. **Page du commit correspondant** : cliquer sur le SHA affiché par GitHub pour pouvoir comparer rapidement les révisions.

Remplacer `<owner>/<repository>` par le chemin réel du dépôt. Dans les deux exécutions, développer à l’avance le job unique et les étapes importantes. Conserver ces pages ouvertes : un onglet déjà chargé constitue la première protection contre un ralentissement de GitHub.

### Vérifications à faire avant de présenter

- La CI sélectionnée affiche un statut réussi, l’événement `push` et la branche `main`.
- Local CD affiche également un statut réussi et correspond au même SHA.
- Ne pas sélectionner une CI issue d’une pull request : le job Local CD serait volontairement ignoré par sa condition de sécurité.
- Les logs ne contiennent aucune donnée sensible.
- Préparer deux captures d’écran locales des exécutions réussies : une vue des étapes CI et une vue des étapes Local CD avec le SHA et HTTP 200 visibles.

## Déroulé chronométré

### 0:00–0:15 — Présenter la chaîne

**Afficher :** l’onglet Actions avec les exécutions `CloudDeploy CI` et `CloudDeploy Local CD` réussies.

**Dire :** « Un push sur `main` lance la CI. Si cette CI réussit et provient bien d’un push de confiance, Local CD démarre automatiquement sur le commit exact qui vient d’être testé. »

### 0:15–1:05 — Montrer CloudDeploy CI

Ouvrir le job **Validate and test container** et parcourir les étapes suivantes :

1. **Validate static website** : montrer les contrôles de présence du HTML, du CSS, du doctype, du titre et du lien vers la feuille de style.
2. **Build Docker image** : montrer la commande `docker build --tag clouddeploy:ci .` et la fin réussie du build Docker.
3. **Start test container** : montrer `docker run`, le mapping `127.0.0.1:8080:80` et l’identifiant du conteneur imprimé par Docker.
4. **Verify HTTP response** : expliquer que `curl` récupère le statut puis que `test "$status_code" = "200"` rend l’étape invalide pour toute autre valeur.
5. **Clean up test container** : montrer que l’étape est verte et utilise `if: always()`, donc qu’elle s’exécute même après un échec antérieur.

**Dire :** « La CI ne se contente pas de construire l’image : elle exécute réellement Nginx et refuse le job si la réponse n’est pas 200. Dans ce workflow, la valeur 200 n’est pas imprimée ; c’est le succès de l’étape conditionnée par `test` qui constitue la preuve. Le nettoyage est toujours exécuté. »

Ne pas annoncer une ligne de log `HTTP 200` dans la CI : le YAML actuel ne fait aucun `echo` de cette valeur.

### 1:05–1:50 — Montrer CloudDeploy Local CD

Ouvrir le job **Deploy on GitHub runner** et montrer :

1. **Check out the verified commit** : repérer le SHA utilisé par `actions/checkout`. Le workflow fournit `github.event.workflow_run.head_sha` et désactive `persist-credentials`.
2. **Build Docker image** : montrer le tag `clouddeploy:local-<SHA>`, qui relie l’image à la révision testée.
3. **Deploy container on runner** : montrer le lancement du conteneur `clouddeploy-local` sur `127.0.0.1:8080`.
4. **Verify deployment** : rechercher la ligne `CloudDeploy <SHA> returned HTTP 200.` et comparer ce SHA à celui de la CI.
5. **Display deployment logs** : montrer `docker ps` et, si elle apparaît, la ligne d’accès Nginx `GET / HTTP/1.1` avec le statut `200`.
6. **Clean up container** : montrer l’étape verte exécutée avec `if: always()`.

**Dire :** « Local CD reconstruit et lance exactement le SHA validé par la CI. Le contrôle HTTP tolère un court délai de démarrage grâce à des retries bornés, mais il exige toujours 200. Les logs facilitent le diagnostic et le conteneur est supprimé dans tous les cas. »

### 1:50–2:00 — Clarifier la portée

**Dire :** « Ce déploiement est volontairement éphémère. Le conteneur vit uniquement pendant le job sur un runner GitHub-hosted, puis il est supprimé et le runner est détruit. Il n’existe donc aucune URL persistante. Ce n’est pas le déploiement AWS : EC2 n’a pas encore été provisionné. »

## Déclenchement optionnel sans changer l’application

La démonstration la plus fiable utilise les exécutions réussies déjà disponibles. Si une nouvelle exécution est réellement nécessaire, si les règles du dépôt autorisent un push direct sur `main`, et seulement avec l’accord de l’encadrant, un commit vide déclenche la CI sans modifier les fichiers ni le fonctionnement de l’application :

```bash
git switch main
git pull --ff-only
git status --short
git commit --allow-empty -m "chore: trigger CloudDeploy CI/CD demo"
git push origin main
```

Vérifier que `git status --short` est vide avant le commit. Le `push` déclenche `CloudDeploy CI`; après son succès, l’événement `workflow_run` déclenche automatiquement `CloudDeploy Local CD`. Ne pas utiliser cette option pendant la soutenance si la durée des runners est imprévisible, si la branche est protégée ou si des changements locaux sont présents. Un commit vide modifie l’historique Git, même s’il ne modifie aucun fichier.

Ces commandes sont cohérentes avec les triggers réels : la CI écoute les pushes sur `main`, tandis que Local CD exige une CI réussie dont l’événement d’origine est `push` et la branche `main`. Aucun secret, appel AWS ou workflow EC2 n’intervient.

## Plan de secours

### Si GitHub est lent

- Utiliser les onglets des exécutions réussies chargés avant la présentation.
- Ne pas rafraîchir les pages.
- Montrer le lien entre les deux exécutions avec le SHA déjà visible.

### Si GitHub est indisponible

- Afficher les captures locales préparées à partir des exécutions réussies : statut global, étapes CI, étape Local CD contenant `<SHA> returned HTTP 200`, logs Nginx et nettoyage.
- Ouvrir localement `.github/workflows/ci.yml` et `.github/workflows/local-cd.yml` pour expliquer les conditions qui ont produit ces résultats.
- Dire explicitement : « Je présente ici les preuves d’exécutions GitHub précédemment réussies ; je ne simule pas une nouvelle exécution. »
- Ne pas remplacer la preuve par un prétendu déploiement AWS. Une démonstration Docker locale peut illustrer le comportement du conteneur, mais elle ne prouve pas une nouvelle exécution GitHub Actions.

## Questions probables du professeur

### 1. Quelle est la différence entre la CI et Local CD dans ce projet ?

La CI valide le contenu, construit l’image et teste le service pour les pushes et les pull requests vers `main`. Local CD ne démarre qu’après une CI réussie issue d’un push sur `main`; il redéploie le SHA validé sur un runner temporaire, affiche les logs puis nettoie le conteneur.

### 2. Comment empêchez-vous une pull request non fiable de déclencher le déploiement ?

La condition Local CD exige simultanément `conclusion == 'success'`, `event == 'push'` et `head_branch == 'main'`. Une CI de pull request peut tester le code, mais son événement d’origine n’est pas `push`, donc le job de déploiement ne s’exécute pas.

### 3. Pourquoi Local CD ne fournit-il pas une URL permanente ?

Le conteneur écoute uniquement sur le runner GitHub-hosted pendant le job. L’étape finale le supprime, puis GitHub détruit le runner. Cette chaîne valide le mécanisme de livraison ; une disponibilité persistante nécessitera une cible durable, prévue ici sur AWS EC2 mais pas encore provisionnée.

## Messages à ne pas ambiguïser

- **Testé avec succès sur GitHub :** CI et Local CD.
- **Éphémère :** le conteneur Local CD et son runner.
- **Non testé dans le cloud :** Terraform n’a pas été appliqué, Ansible n’a pas configuré d’hôte EC2 et le workflow AWS n’a pas déployé l’application.
- **Aucune persistance :** Local CD n’est ni un environnement de production ni un substitut à EC2.
