#!/bin/bash
set -euo pipefail

EXT_ID='com.azizzo.QLSymlinkViewer.Preview'

list_registered() {
  pluginkit -m -A -D -v -p com.apple.quicklook.preview 2>/dev/null | grep -i "$EXT_ID" || true
}

clean_registered() {
  paths=$(pluginkit -m -A -D -v -p com.apple.quicklook.preview 2>/dev/null \
    | grep -i "$EXT_ID" \
    | awk -F'\t' '{print $4}' \
    | sed '/^[[:space:]]*$/d' || true)

  if [ -z "${paths:-}" ]; then
    echo "No registered entries found for $EXT_ID"
    return 0
  fi

  while IFS= read -r p; do
    [ -n "$p" ] || continue
    echo "Removing: $p"
    pluginkit -r "$p" 2>/dev/null || true
  done <<< "$paths"
}

case "${1:-}" in
  --clean|--uninstall)
    clean_registered
    echo
    echo "Remaining registrations:"
    list_registered
    ;;
  ""|--list)
    list_registered
    ;;
  *)
    echo "Usage: $0 [--list|--clean|--uninstall]" >&2
    exit 2
    ;;
esac

