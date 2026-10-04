#!/usr/bin/env bash
set -euo pipefail
GODOT_VERSION=4.6
GODOT_TOOL_DIR="${GODOT_TOOL_DIR:-$PWD/.tools/godot}"
mkdir -p "$GODOT_TOOL_DIR"
base="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"
if [[ ! -f "$GODOT_TOOL_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64" ]]; then
  curl --fail --location --retry 3 "$base/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o "$GODOT_TOOL_DIR/editor.zip"
  unzip -q -o "$GODOT_TOOL_DIR/editor.zip" -d "$GODOT_TOOL_DIR"
fi
python scripts/prepare_font.py
if [[ "${1:-}" == "--templates" ]]; then
  template_dir="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${GODOT_VERSION}.stable"
  if [[ ! -f "$template_dir/android_debug.apk" ]]; then
    curl --fail --location --retry 3 "$base/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" -o "$GODOT_TOOL_DIR/templates.tpz"
    mkdir -p "$template_dir"
    unzip -q -o "$GODOT_TOOL_DIR/templates.tpz" 'templates/android_debug.apk' 'templates/android_release.apk' 'templates/version.txt' -d "$GODOT_TOOL_DIR"
    cp "$GODOT_TOOL_DIR"/templates/* "$template_dir/"
  fi
fi
printf 'Godot ready: %s\n' "$GODOT_TOOL_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64"
