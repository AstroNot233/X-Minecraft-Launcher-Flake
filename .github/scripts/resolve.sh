#!/usr/bin/env bash
#
# Work out which version every channel should be pinned to: the newest release
# for `release`, the newest prerelease for `preview`. Writes the versions as a
# JSON object to $GITHUB_OUTPUT; a channel upstream has nothing for keeps the
# version it is already pinned to.
#
# Requires GITHUB_TOKEN when it is available: the anonymous rate limit is per
# IP, and a runner shares its IP.
set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

# Wide enough that the newest release does not fall out of the window during a
# stretch of prereleases.
releases=""
if [ -n "${GITHUB_TOKEN:-}" ]; then
  releases="$(curl -fsSL -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    "${API_URL}/releases?per_page=100" 2>/dev/null)" || releases=""
else
  releases="$(curl -fsSL "${API_URL}/releases?per_page=100" 2>/dev/null)" || releases=""
fi

if [ -z "$releases" ] || [ "$releases" = "null" ] || [ "$releases" = "[]" ]; then
  echo "::warning::the releases API call returned nothing, keeping the pinned channels"
  releases=""
fi

versions='{}'
while read -r channel; do
  prerelease="$(jq -r --arg c "$channel" '.channels[] | select(.name == $c) | .prerelease' "$CONFIG_FILE")"
  pinned="$(pinned_version "$channel")"

  if [ -z "$releases" ]; then
    # A failed call must not drop a pin; the next run picks the release up.
    version="$pinned"
  else
    tag="$(jq -r --argjson p "$prerelease" \
      '[.[] | select((.draft | not) and (.prerelease == $p))][0].tag_name // empty' <<< "$releases")"

    if [ -z "$tag" ]; then
      # Nothing to move to; never read that as "the channel is gone".
      echo "::warning::${channel}: no matching release upstream, keeping the pinned '${pinned:-none}'"
      version="$pinned"
    else
      version="${tag#v}"
      if ! grep -qE -x -- "$VERSION_FMT" <<< "$version"; then
        echo "::error::upstream tag '${tag}' is not a plain version"
        exit 1
      fi
      # Never go backwards: upstream occasionally tags a patch on an older line,
      # which would silently downgrade the pin and the tag.
      if [ -n "$pinned" ] && [ "$version" != "$pinned" ] &&
        [ "$(printf '%s\n%s\n' "$version" "$pinned" | sort -V | head -n1)" = "$version" ]; then
        echo "::warning::${channel}: upstream is at ${version}, older than the pinned ${pinned}; keeping the pin"
        version="$pinned"
      fi
    fi
  fi

  echo "${channel}: pinned '${pinned:-none}', upstream '${version:-none}'"
  versions="$(jq -c --arg c "$channel" --arg v "$version" '. + {($c): $v}' <<< "$versions")"
done < <(channel_names)

printf 'versions=%s\n' "$versions" >> "$GITHUB_OUTPUT"
