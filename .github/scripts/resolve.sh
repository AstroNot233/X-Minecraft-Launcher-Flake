#!/usr/bin/env bash
#
# Work out which version every channel should be pinned to: the newest release
# for `release`, the newest prerelease for `preview`. Writes version_<channel>
# and changed to $GITHUB_OUTPUT.
#
# Requires GITHUB_TOKEN when it is available: the anonymous rate limit is per
# IP, and a runner shares its IP.
set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

releases=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
  releases="$(curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${API_URL}/releases?per_page=30" 2>/dev/null)" || releases=""
else
  releases="$(curl -fsSL "${API_URL}/releases?per_page=30" 2>/dev/null)" || releases=""
fi

if [ -z "$releases" ] || [ "$releases" = "null" ]; then
  echo "::warning::releases API call failed, keeping the pinned channels"
fi

changed=false
versions='{}'
while read -r channel; do
  prerelease="$(jq -r --arg c "$channel" '.channels[] | select(.name == $c) | .prerelease' "$CONFIG_FILE")"
  pinned="$(pinned_version "$channel")"

  if [ -z "$releases" ] || [ "$releases" = "null" ]; then
    # A failed call must not drop a pin; the next run picks the release up.
    version="$pinned"
  else
    tag="$(jq -r --argjson p "$prerelease" \
      '[.[] | select((.draft | not) and (.prerelease == $p))][0].tag_name // empty' <<< "$releases")"
    version="${tag#v}"
    if [ -n "$version" ] && ! grep -qE -x -- "$VERSION_FMT" <<< "$version"; then
      echo "::error::upstream tag '${tag}' is not a plain version"
      exit 1
    fi
  fi

  echo "${channel}: pinned '${pinned:-none}', upstream '${version:-none}'"
  [ "$version" != "$pinned" ] && changed=true
  versions="$(jq -c --arg c "$channel" --arg v "$version" '. + {($c): $v}' <<< "$versions")"
done < <(channel_names)

printf 'versions=%s\n' "$versions" >> "$GITHUB_OUTPUT"
printf 'changed=%s\n' "$changed" >> "$GITHUB_OUTPUT"
