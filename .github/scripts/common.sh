#!/usr/bin/env bash
#
# Shared helpers for the update scripts. Source config.sh first: the paths, the
# channel list and the system list all come from there.

# A hash that cannot match anything, used to make nix report the real one when
# a channel is pinned for the first time.
export FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# Channels, one per line, in config order.
channel_names() {
  local -a names
  read -ra names <<< "$CHANNELS"
  printf '%s\n' "${names[@]}"
}

# Systems, one per line, in config order.
system_names() {
  local -a names
  read -ra names <<< "$SYSTEMS"
  printf '%s\n' "${names[@]}"
}

# Version pinned for a channel, empty when the channel is not pinned at all.
pinned_version() {
  jq -r --arg c "$1" '.[$c].version // empty' "$SOURCES_FILE"
}

# Version the resolve job found for a channel, empty when upstream has none.
# VERSIONS is a JSON object handed over by the workflow.
channel_version() {
  local versions="${VERSIONS:-}"
  [ -n "$versions" ] || versions='{}'
  jq -r --arg c "$1" '.[$c] // empty' <<< "$versions"
}

# Hash pinned for a channel on a system, empty when missing.
pinned_hash() {
  jq -r --arg c "$1" --arg s "$2" '.[$c].hash[$s] // empty' "$SOURCES_FILE"
}

# Upstream release page of a version.
release_url() {
  printf '%s/tag/v%s' "$RELEASE_URL" "$1"
}

# Upstream release asset for a version and one system.
asset_url() {
  local version="$1" asset="$2"
  printf '%s/download/v%s/app-%s-%s.asar.gz' "$RELEASE_URL" "$version" "$version" "$asset"
}

# Write sources.json through jq, atomically.
sources_update() {
  jq "$@" "$SOURCES_FILE" > sources.json.new
  mv sources.json.new "$SOURCES_FILE"
}
