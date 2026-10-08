#!/usr/bin/env bash
#
# Build the source of every channel that is pinned — which fails when a hash is
# wrong — and check that the wrappers still evaluate, without paying for the
# FHS environment build.
set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

while read -r channel; do
  version="$(pinned_version "$channel")"
  [ -n "$version" ] || continue
  echo "Building ${channel} ${version}"
  nix build --no-link ".#$(channel_attr "$channel")"
done < <(channel_names)

while read -r channel; do
  [ -n "$(pinned_version "$channel")" ] || continue
  nix build --dry-run ".#${channel}"
done < <(channel_names)
