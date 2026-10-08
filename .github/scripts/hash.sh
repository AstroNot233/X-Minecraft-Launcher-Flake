#!/usr/bin/env bash
#
# One system: pin the version each channel is at upstream, build it, and read
# the hash nix asks for out of the mismatch report. A build without a mismatch
# means the pinned hash is still the right one.
#
# Requires SYSTEM, VERSIONS, GITHUB_OUTPUT; writes hash.env with one
# "<channel> <system> <hash>" line per hash that has to change.
set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

: > hash.env

while read -r channel; do
  version="$(channel_version "$channel")"
  attr="$(channel_attr "$channel")"

  if [ -z "$version" ]; then
    echo "${channel}: not released upstream, nothing to pin"
    continue
  fi

  # The entry has to exist with a hash for this system, otherwise nix throws
  # instead of reporting the hash it wants.
  sources_update --arg c "$channel" --arg v "$version" --arg s "$SYSTEM" --arg fake "$FAKE_HASH" '
    .[$c] = (
      (.[$c] // {})
      | .version = $v
      | .hash = ((.hash // {}) | .[$s] = (.[$s] // $fake))
    )
  '

  if log=$(nix build ".#${attr}" 2>&1); then
    echo "${channel}: hash unchanged (${version}, ${SYSTEM})"
    continue
  fi

  got=$(printf '%s\n' "$log" | sed -n 's/.*got: *//p' | tail -n1)
  if [ -z "$got" ]; then
    printf '%s\n' "$log"
    echo "::error::no hash mismatch reported for ${channel} on ${SYSTEM}"
    exit 1
  fi

  echo "${channel}: hash is now ${got}"
  printf '%s %s %s\n' "$channel" "$SYSTEM" "$got" >> hash.env
done < <(channel_names)
