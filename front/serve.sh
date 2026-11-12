#!/bin/sh
# Sert le front avec Apache sur http://localhost:8080.
#
# macOS interdit à Apache de lire les dossiers Documents ou iCloud : le script
# copie donc le front dans un dossier temporaire, puis lance Apache depuis cette
# copie. Après une modification du front, relancez le script (Ctrl+C, puis à nouveau).
#
# Utilisation, depuis le dossier front/ :  sh serve.sh

SITE="${TMPDIR:-/tmp}/lapioche-front"

rm -rf "$SITE"
mkdir -p "$SITE"
cp "$(dirname "$0")"/*.html "$(dirname "$0")"/*.js "$(dirname "$0")"/*.css "$(dirname "$0")"/httpd.conf "$SITE"/
cp -R "$(dirname "$0")/tests" "$SITE"/

cd "$SITE" || exit 1
echo "Front disponible sur http://localhost:8080 (Ctrl+C pour arrêter)"
echo "Tests du front : http://localhost:8080/tests/"
# Utiliser Apache de macOS s'il existe, sinon celui du PATH.
if [ -x /usr/sbin/httpd ]; then
    APACHE="/usr/sbin/httpd"
else
    APACHE="$(command -v httpd)"
fi

exec "$APACHE" -f "$SITE/httpd.conf" -DFOREGROUND
