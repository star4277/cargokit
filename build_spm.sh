#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <cargo-manifest-dir> <output-file> <plugin-work-dir>" >&2
  exit 64
fi

for variable in PLATFORM_NAME ARCHS CONFIGURATION; do
  if [ -z "${!variable:-}" ]; then
    echo "Missing Xcode build variable: $variable" >&2
    exit 64
  fi
done

BASEDIR=$(cd "$(dirname "$0")" && pwd -P)
MANIFEST_DIR=$(cd "$1" && pwd -P)
OUTPUT_PARENT=$(mkdir -p "$(dirname "$2")" && cd "$(dirname "$2")" && pwd -P)
OUTPUT_FILE="$OUTPUT_PARENT/$(basename "$2")"
PLUGIN_WORK_DIR=$(mkdir -p "$3" && cd "$3" && pwd -P)

# Xcode's SDK paths break compilation of the host Dart build tool.
NEW_PATH=$(printf '%s' "$PATH" | tr ":" "\n" | grep -v "Contents/Developer/" | tr "\n" ":")
export PATH=${NEW_PATH%?}

export CARGOKIT_DARWIN_PLATFORM_NAME="$PLATFORM_NAME"
export CARGOKIT_DARWIN_ARCHS="$ARCHS"
export CARGOKIT_CONFIGURATION="$CONFIGURATION"
export CARGOKIT_MANIFEST_DIR="$MANIFEST_DIR"
export CARGOKIT_OUTPUT_FILE="$OUTPUT_FILE"
export CARGOKIT_TARGET_TEMP_DIR="$PLUGIN_WORK_DIR/rust"
export CARGOKIT_TOOL_TEMP_DIR="$PLUGIN_WORK_DIR/build_tool"
export CARGOKIT_ROOT_PROJECT_DIR="$MANIFEST_DIR"

if [ -n "${CARGOKIT_DART_PACKAGE_CONFIG:-}" ]; then
  if [ ! -f "$CARGOKIT_DART_PACKAGE_CONFIG" ]; then
    echo "Missing CargoKit Dart package config: $CARGOKIT_DART_PACKAGE_CONFIG" >&2
    exit 66
  fi
  if [ -z "${FLUTTER_ROOT:-}" ]; then
    echo "FLUTTER_ROOT is required with CARGOKIT_DART_PACKAGE_CONFIG" >&2
    exit 64
  fi
  exec "$FLUTTER_ROOT/bin/cache/dart-sdk/bin/dart" \
    --packages="$CARGOKIT_DART_PACKAGE_CONFIG" \
    "$BASEDIR/build_tool/bin/build_tool.dart" \
    build-spm
fi

exec "$BASEDIR/run_build_tool.sh" build-spm
