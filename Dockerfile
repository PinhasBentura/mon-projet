# =============================================================================
# Dockerfile multi-stage (construction en plusieurs étapes)
# =============================================================================
# Un Dockerfile multi-stage permet de séparer les étapes de construction
# pour obtenir une image finale plus légère et optimisée.
# Chaque instruction "FROM" crée une nouvelle étape (stage).
# Seule la dernière étape (ou celle ciblée) devient l'image finale.
# =============================================================================


# ---------- Étape 1 : Base commune ----------
# Cette étape sert de fondation réutilisable pour toutes les autres étapes.
# "node:22-alpine" = image Node.js v22 basée sur Alpine Linux (très légère, ~50 Mo
# contre ~350 Mo pour l'image Debian classique).
# "AS base" = on donne un nom à cette étape pour la référencer plus tard.
FROM node:22-alpine AS base

# WORKDIR définit le répertoire de travail à l'intérieur du conteneur.
# Toutes les commandes suivantes (COPY, RUN, CMD) s'exécuteront depuis /app.
# Si le dossier n'existe pas, Docker le crée automatiquement.
WORKDIR /app


# ---------- Étape 2 : Installation des dépendances ----------
# On hérite de l'étape "base" (Node + WORKDIR déjà configurés).
# Cette étape est isolée pour profiter du cache Docker :
# tant que package.json et package-lock.json ne changent pas,
# Docker réutilise le cache et n'a pas besoin de réinstaller les dépendances.
FROM base AS deps

# COPY copie des fichiers depuis votre machine (hôte) vers le conteneur.
# On copie uniquement les fichiers de dépendances d'abord (avant le reste du code)
# pour optimiser la mise en cache (voir explication ci-dessus).
COPY package.json package-lock.json ./

# "npm ci" installe les dépendances de manière déterministe :
# - Utilise exactement les versions du package-lock.json (pas de mise à jour)
# - Plus rapide que "npm install" en CI/CD
# - Supprime node_modules existant avant l'installation
# C'est la commande recommandée pour les environnements automatisés (Docker, CI).
RUN npm ci


# ---------- Étape 3 : Développement (hot reload) ----------
# Cette étape est utilisée pendant le développement local.
# Elle hérite de "deps" (les dépendances sont déjà installées).
FROM deps AS dev

# On copie tout le code source dans le conteneur.
# Note : en développement, ce COPY est souvent "écrasé" par un volume Docker
# (voir compose.yaml) qui monte le code source de l'hôte dans le conteneur,
# permettant ainsi le rechargement à chaud (hot reload).
COPY . .

# EXPOSE documente le port sur lequel l'application écoute.
# ⚠️  EXPOSE ne publie PAS réellement le port ! C'est juste une indication.
# Pour rendre le port accessible, il faut utiliser "ports:" dans compose.yaml
# ou l'option "-p" de "docker run".
EXPOSE 3000

# CMD définit la commande exécutée au démarrage du conteneur.
# Ici on enchaîne 3 commandes avec "&&" :
#   1. "npx prisma migrate deploy" → applique les migrations de base de données
#   2. "npx prisma generate"       → génère le client Prisma (ORM)
#   3. "npm run dev"               → lance le serveur Next.js en mode développement
# Le format ["sh", "-c", "..."] permet d'utiliser "&&" dans la syntaxe exec.
CMD ["sh", "-c", "npx prisma migrate deploy && npx prisma generate && npm run dev"]


# ---------- Étape 4 : Build de production ----------
# Cette étape compile l'application pour la production.
# Elle n'est PAS incluse dans l'image finale : elle sert uniquement à
# produire les fichiers compilés qui seront copiés dans l'étape suivante.
FROM deps AS build

# On copie le code source pour pouvoir le compiler.
COPY . .

# On génère le client Prisma puis on compile l'application Next.js.
# "npm run build" crée un dossier .next/ contenant l'application optimisée.
RUN npx prisma generate && npm run build


# ---------- Étape 5 : Image finale, légère ----------
# C'est l'image qui sera déployée en production.
# Elle repart de "base" (pas de node_modules de dev, pas de code source)
# pour être la plus légère possible.
FROM base AS prod

# On définit la variable d'environnement NODE_ENV=production.
# Cela indique à Node.js et aux bibliothèques (Express, Next.js, etc.)
# d'activer les optimisations de production (pas de logs de debug, etc.).
ENV NODE_ENV=production

# COPY --from=build : on copie des fichiers DEPUIS l'étape "build"
# (pas depuis la machine hôte). C'est le cœur du multi-stage build !
# "standalone" contient le serveur Next.js autonome (pas besoin de node_modules complet).
COPY --from=build /app/.next/standalone ./

# On copie aussi les fichiers statiques (CSS, JS, images) générés par le build.
COPY --from=build /app/.next/static ./.next/static

# On expose le port 3000 (même remarque que plus haut : c'est informatif).
EXPOSE 3000

# En production, on lance directement le serveur Node.js compilé.
# Pas besoin de "npm run" ni de "npx" : le fichier server.js est autonome.
CMD ["node", "server.js"]
