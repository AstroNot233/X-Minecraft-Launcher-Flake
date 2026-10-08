#!/usr/bin/env bash

# config.json, read once. Sourced, it puts the values in the caller's
# environment; run directly — the workflow's "Load config" step — it also
# publishes the job matrix as a step output.
#
# Set CONFIG_FILE to read a different file.

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
fi

CONFIG_FILE="${CONFIG_FILE:-config.json}"

config_load() {
  local -a v=()
  # One value per line: @tsv would escape the backslashes of version_fmt.
  mapfile -t v < <(jq -r '
    .upstream_repo,
    .version_fmt,
    .sources_file,
    .readme_file,
    .readme_markers[0],
    .readme_markers[1],
    (.channels | map(.name) | join(" ")),
    (.systems | map(.name) | join(" "))
  ' "$CONFIG_FILE")

  UPSTREAM_REPO="${v[0]}"
  VERSION_FMT="${v[1]}"
  SOURCES_FILE="${v[2]}"
  README_FILE="${v[3]}"
  MARKER_BEGIN="${v[4]}"
  MARKER_END="${v[5]}"
  CHANNELS="${v[6]}"
  SYSTEMS="${v[7]}"

  # Derived here rather than in every caller.
  API_URL="${UPSTREAM_REPO/github.com/api.github.com/repos}"
  RELEASE_URL="${UPSTREAM_REPO}/releases"

  export UPSTREAM_REPO VERSION_FMT SOURCES_FILE README_FILE \
    MARKER_BEGIN MARKER_END CHANNELS SYSTEMS API_URL RELEASE_URL
}

# The hash job builds one flake attribute per channel: asar, asar-preview, …
channel_attr() {
  jq -r --arg c "$1" '.channels[] | select(.name == $c) | .attr' "$CONFIG_FILE"
}

# Whether a channel may disappear from upstream (default: no).
channel_optional() {
  jq -r --arg c "$1" '.channels[] | select(.name == $c) | (.optional // false)' "$CONFIG_FILE"
}

# Asset suffix upstream uses for a system: linux, linux-arm64, …
system_asset() {
  jq -r --arg s "$1" '.systems[] | select(.name == $s) | .asset' "$CONFIG_FILE"
}

config_load

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  printf 'matrix=%s\n' "$(jq -c '{include: .systems}' "$CONFIG_FILE")" \
    >> "${GITHUB_OUTPUT:?GITHUB_OUTPUT is not set}"
fi
