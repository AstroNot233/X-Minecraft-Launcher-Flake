#!/usr/bin/env bash
#
# Rewrite the readme table between the markers from sources.json; everything
# outside the markers is hand written.
set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

block="$(
  {
    echo
    header="| Channel | Ref |"
    align="| --- | --- |"
    while read -r system; do
      header="${header} \`${system}\` |"
      align="${align} :---: |"
    done < <(system_names)
    echo "${header} Updated |"
    echo "${align} --- |"

    while read -r channel; do
      version="$(pinned_version "$channel")"
      if [ -z "$version" ]; then
        row="| \`${channel}\` | — |"
        while read -r system; do row="${row} — |"; done < <(system_names)
        echo "${row} — |"
        continue
      fi

      row="| \`${channel}\` | [\`v${version}\`]($(release_url "$version")) |"
      while read -r system; do
        hash="$(pinned_hash "$channel" "$system")"
        if [ -n "$hash" ]; then
          row="${row} ✅ [\`${hash:7:8}…\`]($(asset_url "$version" "$(system_asset "$system")")) |"
        else
          row="${row} — |"
        fi
      done < <(system_names)
      echo "${row} $(jq -r --arg c "$channel" '.[$c].updated // "—"' "$SOURCES_FILE") |"
    done < <(channel_names)
  }
)"

export BLOCK="$block"
awk '
  index($0, ENVIRON["MARKER_BEGIN"]) == 1 { print; print ENVIRON["BLOCK"]; print ""; inside = 1; next }
  index($0, ENVIRON["MARKER_END"]) == 1 { inside = 0 }
  !inside { print }
' "$README_FILE" > readme.new
mv readme.new "$README_FILE"

git diff -- "$README_FILE"
