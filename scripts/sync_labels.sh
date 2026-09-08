#!/usr/bin/env bash
# Push .github/labels.json to the GitHub repo named by .ai/project.yml. Idempotent:
# creates missing labels, updates colour/description of existing ones, never deletes.
# Deleting a label that left the file is deliberately manual: an issue keeps its label
# history. Requires `gh` authenticated with push access.
set -euo pipefail
cd "$(dirname "$0")/.."

repo="${1:-$(sed -n 's/^repo:[[:space:]]*\([^[:space:]#]*\).*/\1/p' .ai/project.yml)}"
[ -n "$repo" ] || { echo "sync_labels: could not read repo from .ai/project.yml" >&2; exit 1; }

jq -c '.labels[]' .github/labels.json | while read -r label; do
  name=$(jq -r .name <<<"$label")
  color=$(jq -r .color <<<"$label")
  desc=$(jq -r .description <<<"$label")
  if gh label create "$name" --repo "$repo" --color "$color" --description "$desc" --force >/dev/null 2>&1; then
    echo "synced: $name"
  else
    echo "FAILED: $name" >&2
    exit 1
  fi
done
