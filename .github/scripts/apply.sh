#!/usr/bin/env bash
#
# Apply what the resolve and hash jobs found: the version of every channel, the
# hashes that changed, and an update date for the channels that moved.
#
# Requires VERSIONS, HASHES_DIR and GITHUB_OUTPUT.
set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

today="$(date -u +%F)"
moved=""

while read -r channel; do
  version="$(channel_version "$channel")"
  pinned="$(pinned_version "$channel")"

  if [ -z "$version" ]; then
    if [ -z "$pinned" ]; then
      continue
    fi
    if [ "$(channel_optional "$channel")" = "true" ]; then
      echo "${channel}: gone upstream, dropping the optional pin"
      sources_update --arg c "$channel" '.[$c] = null'
      moved="$moved $channel"
    else
      echo "::warning::${channel}: upstream has nothing to pin, keeping ${pinned}"
    fi
    continue
  fi

  if [ "$version" != "$pinned" ]; then
    echo "${channel}: ${pinned:-none} -> ${version}"
    sources_update --arg c "$channel" --arg v "$version" '.[$c] = ((.[$c] // {}) | .version = $v)'
    moved="$moved $channel"
  fi
done < <(channel_names)

shopt -s nullglob
files=("$HASHES_DIR"/*/hash.env)
[ "${#files[@]}" -eq "$(system_names | wc -l)" ] || {
  echo "::error::expected one hash.env per system, found ${#files[@]}: ${files[*]}"
  exit 1
}

# Write every hash by channel and system. A plain string replacement would be
# ambiguous here: a channel pinned for the first time carries a placeholder, and
# that placeholder is the same for both systems.
for file in "${files[@]}"; do
  while read -r channel system got; do
    [ -n "$channel" ] || continue
    [ -n "$(pinned_version "$channel")" ] || {
      echo "::error::${channel}: a hash was reported for a channel with no pinned version"
      exit 1
    }
    sources_update --arg c "$channel" --arg s "$system" --arg h "$got" \
      '.[$c].hash = ((.[$c].hash // {}) | .[$s] = $h)'
    [ "$(pinned_hash "$channel" "$system")" = "$got" ] || {
      echo "::error::cannot pin ${got} for ${channel} on ${system}"
      exit 1
    }
    echo "${channel} (${system}): hash is now ${got}"
    moved="$moved $channel"
  done < "$file"
done

printf '%s\n' "$moved" | tr ' ' '\n' | sort -u | while read -r channel; do
  [ -n "$channel" ] || continue
  # A channel that was just dropped has nothing to stamp.
  [ -n "$(pinned_version "$channel")" ] || continue
  sources_update --arg c "$channel" --arg d "$today" '.[$c].updated = $d'
  echo "${channel}: updated ${today}"
done

if git diff --quiet -- "$SOURCES_FILE"; then
  echo "sources.json is up to date"
  echo "changed=false" >> "$GITHUB_OUTPUT"
else
  git diff -- "$SOURCES_FILE"
  echo "changed=true" >> "$GITHUB_OUTPUT"
fi
