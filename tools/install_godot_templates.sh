#!/usr/bin/env bash
set -euo pipefail

# Instala plantillas de exportación de Godot para la versión actual del binario `godot-preview`.
# Intenta URLs conocidas; si no las encuentra (versiones dev a veces no publican templates),
# sugiere instalar desde el editor.

VERSION_RAW=$(godot-preview --version | awk '{print $4}')
# Ej: v4.6.dev2.official.7864ac801 -> 4.6.dev2
VERSION=$(echo "$VERSION_RAW" | sed -E 's/^v?([0-9]+\.[0-9]+)\.([a-zA-Z0-9]+)\..*$/\1.\2/')
MAJOR_MINOR=$(echo "$VERSION" | cut -d. -f1-2)   # 4.6
QUALIFIER=$(echo "$VERSION" | cut -d. -f3)       # dev2

echo "Detectada versión Godot: $VERSION_RAW -> $VERSION (major.minor=$MAJOR_MINOR, qualifier=$QUALIFIER)"

DEST="$HOME/.local/share/godot/export_templates/$VERSION"
mkdir -p "$DEST"

TMPDIR=$(mktemp -d)
pushd "$TMPDIR" >/dev/null

FILENAME="Godot_v${MAJOR_MINOR}-${QUALIFIER}_export_templates.tpz"

URLS=(
  "https://downloads.tuxfamily.org/godotengine/${MAJOR_MINOR}/${QUALIFIER}/${FILENAME}"
  "https://downloads.tuxfamily.org/godotengine/${MAJOR_MINOR}/${FILENAME}"
  "https://downloads.godotengine.org/${MAJOR_MINOR}/${QUALIFIER}/${FILENAME}"
  "https://downloads.godotengine.org/${MAJOR_MINOR}/${FILENAME}"
)

DL_OK=0
for URL in "${URLS[@]}"; do
  echo "Intentando descargar: $URL"
  if curl -fsSL -o "$FILENAME" "$URL"; then
    DL_OK=1
    break
  fi
done

if [[ "$DL_OK" != "1" ]]; then
  echo "No se pudieron descargar plantillas automáticamente para $VERSION."
  echo "Abre el editor y ve a: Editor -> Manage Export Templates -> Download and Install."
  exit 2
fi

echo "Descomprimiendo $FILENAME"
unzip -q "$FILENAME"

if [[ -d templates ]]; then
  echo "Instalando templates en $DEST"
  cp -r templates/* "$DEST/"
else
  echo "No se encontró carpeta 'templates' dentro del paquete." >&2
  exit 3
fi

popd >/dev/null
rm -rf "$TMPDIR"

echo "Plantillas instaladas en $DEST"
exit 0
