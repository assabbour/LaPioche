#!/bin/sh
set -eu

cd "$(dirname "$0")"

if [ ! -f .env ]; then
    echo "Génération de la clé JWT locale..."
    umask 077
    printf 'JWT_SECRET=%s\n' "$(openssl rand -hex 32)" > .env
fi

set -a
. ./.env
set +a

echo "Démarrage de LaPioche API sur le port 8081..."
swift run App serve --hostname 127.0.0.1 --port 8081