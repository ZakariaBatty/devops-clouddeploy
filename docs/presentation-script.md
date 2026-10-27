# Script de présentation CloudDeploy — 5 minutes

Ce script distingue volontairement ce qui a été exécuté de ce qui est seulement préparé. Les parties « À dire » constituent le discours principal. Les autres éléments servent de repères pour la démonstration et les questions.

## 1. Introduction et objectifs — 30 secondes

### À dire

« Bonjour. Je vais vous présenter CloudDeploy, un projet pédagogique qui couvre une chaîne DevOps complète autour d’un site HTML et CSS. Mon objectif n’était pas simplement d’utiliser plusieurs outils, mais de séparer clairement leurs responsabilités : Docker rend l’application reproductible, GitHub Actions automatise les contrôles et la livraison, Terraform décrit l’infrastructure, et Ansible décrit la configuration du serveur. Aujourd’hui, la CI et la démonstration Local CD fonctionnent sur GitHub. La partie AWS est préparée et validée localement, mais elle n’est pas encore déployée. »

### À montrer à l’écran

- La page d’accueil du dépôt et le début du `README.md`.
- La matrice « Validation status », en pointant les lignes testées puis les lignes AWS en attente.

### Concepts à maîtriser

- Le DevOps cherche un flux reproductible et vérifiable entre code, livraison et exploitation.
- Une validation locale confirme la cohérence d’une configuration, pas le comportement réel d’une infrastructure distante.
- La transparence sur l’état du projet est plus importante qu’une fausse démonstration de production.

### Question probable

**Question : Pourquoi ce projet est-il DevOps et pas seulement un site conteneurisé ?**

**Réponse :** Parce qu’il relie le code, les tests automatisés, la livraison, l’Infrastructure as Code, la configuration idempotente, la sécurité et l’exploitation dans une chaîne cohérente.

## 2. Architecture et outils DevOps — 60 secondes

### À dire

« Voici l’architecture. Un push ou une pull request vers `main` déclenche la CI. Celle-ci valide les fichiers du site, construit l’image Docker, lance un conteneur et exige une réponse HTTP 200. Pour un push réussi et de confiance sur `main`, Local CD récupère exactement le SHA validé par la CI et refait un déploiement temporaire sur un runner GitHub.

La partie en pointillés représente la cible AWS. Terraform doit créer une instance Ubuntu 24.04 dans `eu-north-1`, avec une adresse publique, un volume chiffré et un security group. Ansible doit ensuite installer Docker, activer son service et préparer l’utilisateur. Enfin, le workflow EC2 prévu transférera l’image et vérifiera le service avec une possibilité de rollback. Cette branche n’a pas encore été exécutée. »

### À montrer à l’écran

- Le diagramme Mermaid « Architecture » du `README.md`.
- Le tableau « Technology stack » pour associer chaque outil à une responsabilité.
- Suivre visuellement le chemin plein GitHub → CI → Local CD, puis le chemin AWS en pointillés.

### Concepts à maîtriser

- CI : intégrer fréquemment et contrôler automatiquement le code.
- CD : automatiser une livraison ou un déploiement après validation.
- Terraform gère le cycle de vie de l’infrastructure ; Ansible configure l’état du système d’exploitation.
- La séparation des responsabilités facilite le diagnostic, la maintenance et l’audit.

### Question probable

**Question : Pourquoi utiliser Terraform et Ansible ensemble ?**

**Réponse :** Terraform crée les ressources AWS et leurs dépendances. Ansible configure ensuite l’OS de manière idempotente. Ils résolvent deux problèmes différents et complémentaires.

## 3. Docker et Nginx — 45 secondes

### À dire

« L’application est volontairement simple pour rendre la chaîne DevOps visible. L’image part de `nginx:alpine`, copie le site statique dans le répertoire servi par Nginx, expose le port 80 et définit un `HEALTHCHECK`. Le même artefact peut donc être construit sur mon Mac ou sur un runner Ubuntu. En local, je publie le port interne 80 sur `127.0.0.1:8080`, puis je vérifie la réponse avec curl. Cette isolation sur l’interface locale évite d’exposer inutilement le conteneur sur tout le réseau. »

### À montrer à l’écran

- Le `Dockerfile`, notamment `FROM`, `COPY`, `EXPOSE` et `HEALTHCHECK`.
- Le site dans le navigateur sur `http://127.0.0.1:8080`.
- Si le temps le permet : `docker ps` et une ligne de `docker logs` montrant une requête `GET /` avec le statut 200.

### Concepts à maîtriser

- Une image est un artefact immuable ; un conteneur est une instance en cours d’exécution.
- Le mapping `127.0.0.1:8080:80` relie le port local 8080 au port 80 du conteneur.
- Le health check Docker et le test HTTP du pipeline sont complémentaires : l’un décrit la santé du conteneur, l’autre décide du succès du job.

### Question probable

**Question : Pourquoi Nginx Alpine ?**

**Réponse :** Le site est statique ; Nginx est adapté à ce rôle et la variante Alpine fournit une image compacte. En production, je figerais aussi précisément la version ou le digest de l’image.

## 4. GitHub Actions CI/CD et démonstration — 90 secondes

### À dire

« La CI s’exécute sur les pushes et les pull requests vers `main`. Elle contrôle d’abord la présence et quelques éléments essentiels des fichiers HTML et CSS. Elle construit ensuite l’image, lance un conteneur sur le runner, exige HTTP 200 et supprime toujours le conteneur, même en cas d’échec.

Local CD est volontairement plus strict. Le trigger `workflow_run` attend la fin de CloudDeploy CI, puis la condition du job exige trois éléments : une conclusion `success`, un événement d’origine `push`, et la branche `main`. Cela empêche une pull request non fiable de déclencher ce déploiement. Le checkout utilise le `head_sha` exact qui a passé la CI et désactive la persistance des credentials.

Le conteneur est ensuite lancé sur le runner. Le contrôle curl utilise des tentatives bornées, un délai court et `--retry-all-errors` pour absorber la course de démarrage Nginx, tout en exigeant exactement le code 200. Les logs sont affichés et le conteneur est toujours supprimé. Je peux montrer ici les deux exécutions GitHub réussies. Local CD démontre bien l’automatisation, mais ce n’est pas un hébergement : le runner disparaît à la fin du job. »

### À montrer à l’écran

1. Dans GitHub Actions, ouvrir une exécution réussie de `CloudDeploy CI` et montrer les étapes vertes.
2. Ouvrir l’exécution automatique correspondante de `CloudDeploy Local CD`.
3. Montrer le SHA, l’étape HTTP 200, les logs Nginx et l’étape de nettoyage.
4. Dans `.github/workflows/local-cd.yml`, pointer la condition du job, `ref: head_sha`, `permissions: contents: read` et `if: always()`.

### Concepts à maîtriser

- Un workflow réussi ne suffit pas : il faut aussi vérifier son événement d’origine et sa branche.
- Déployer le SHA testé évite un écart entre la version validée et la version exécutée.
- `if: always()` garantit l’observabilité et le nettoyage après un échec précédent.
- Les retries doivent être bornés ; ils rendent le test tolérant au démarrage, pas permissif sur le résultat attendu.
- Une livraison éphémère prouve le pipeline, mais n’apporte ni disponibilité ni persistance.

### Question probable

**Question : Pourquoi reconstruire l’image dans Local CD au lieu de réutiliser celle de la CI ?**

**Réponse :** Pour cette démonstration courte, il n’y a pas encore de registre d’images. Le SHA exact garantit la même source, mais une architecture plus mature publierait une image immuable signée en CI puis déploierait son digest sans la reconstruire.

## 5. Terraform, Ansible et architecture AWS EC2 — 45 secondes

### À dire

« Pour la cible cloud, Terraform décrit une instance `t3.micro` Ubuntu 24.04 à Stockholm, dans le VPC par défaut. Le port HTTP 80 est public, mais SSH est limité à un CIDR de confiance et la variable refuse explicitement `0.0.0.0/0`. Le volume racine est chiffré et IMDSv2 est obligatoire.

Après le provisionnement, Ansible doit installer Docker et les utilitaires, démarrer et activer le service, puis ajouter l’utilisateur SSH au groupe Docker. Le playbook est idempotent. À ce stade, `terraform validate` et le contrôle de syntaxe Ansible ont réussi localement, mais aucun `terraform apply` ni aucune configuration EC2 n’a été exécuté, car la vérification du compte AWS est toujours en attente. »

### À montrer à l’écran

- `terraform/main.tf` : instance, règles HTTP/SSH, chiffrement et `http_tokens = "required"`.
- `terraform/variables.tf` : région `eu-north-1` et validation du CIDR SSH.
- `ansible/playbook.yml` : installation, service Docker et groupe utilisateur.

### Concepts à maîtriser

- `terraform validate` vérifie la configuration ; il ne prouve ni les permissions AWS ni la création des ressources.
- L’idempotence signifie qu’une nouvelle exécution Ansible converge vers le même état sans refaire inutilement les changements.
- Le security group est un pare-feu virtuel avec des règles entrantes et sortantes explicites.

### Question probable

**Question : Pouvez-vous affirmer que l’infrastructure AWS fonctionne ?**

**Réponse :** Non. Je peux affirmer que la configuration Terraform est valide localement et que la syntaxe Ansible est correcte. Le plan réel, l’application, la connexion SSH et le déploiement restent à tester après validation du compte AWS.

## 6. Sécurité, limites et conclusion — 30 secondes

### À dire

« La sécurité est intégrée au flux : permissions GitHub minimales en lecture, aucun secret dans le dépôt, SHA vérifié, SSH restreint, host-key checking Ansible et vérification stricte de l’hôte prévue pour le CD EC2. Les limites sont assumées : état Terraform local, HTTP sans TLS, une seule instance et aucun déploiement AWS réel à ce jour. La prochaine étape est de créer un plan Terraform avec le compte vérifié, provisionner EC2, exécuter Ansible, configurer les secrets GitHub, puis tester le health check et le rollback avant d’activer le CD automatique. CloudDeploy démontre ainsi une démarche DevOps progressive, testable et honnête. »

### À montrer à l’écran

- La section « Security practices and limitations » du `README.md`.
- Terminer sur la matrice de validation : vert pour CI/Local CD, en attente pour AWS.

### Concepts à maîtriser

- Le moindre privilège réduit l’impact d’un token ou d’un compte compromis.
- Les secrets doivent être injectés au moment de l’exécution et ne jamais être versionnés.
- Une limite documentée devient un risque gérable et une prochaine étape mesurable.

### Question probable

**Question : Quelle serait votre priorité avant une mise en production ?**

**Réponse :** Ajouter TLS et un registre d’images immuables, sécuriser l’état Terraform à distance, valider réellement AWS et le rollback, puis traiter la haute disponibilité, la supervision et la maîtrise des coûts.

## Checklist juste avant la présentation

- Ouvrir à l’avance le `README.md`, le `Dockerfile`, les deux workflows réussis et les fichiers Terraform/Ansible utiles.
- Préparer le site local sur le port `8080`, sans lancer une longue construction pendant les cinq minutes.
- Garder sous la main les logs GitHub contenant HTTP 200 et le nettoyage.
- Ne pas présenter les pointillés AWS comme un environnement existant.
- Respecter les transitions et les durées ; privilégier l’explication du flux plutôt qu’une lecture exhaustive du YAML.
