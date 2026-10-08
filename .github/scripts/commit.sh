#!/usr/bin/env bash
#
# Commit the sources and the readme when they moved, then push them together
# with the tag of every version being packaged. A run that changed nothing
# commits nothing.
set -euo pipefail

source "$(dirname "$0")/config.sh"
source "$(dirname "$0")/common.sh"

git add "$SOURCES_FILE" "$README_FILE"
if git diff --cached --quiet -- "$SOURCES_FILE" "$README_FILE"; then
  echo "nothing to commit"
  exit 0
fi

subject="$(pinned_version release)"
if [ -z "$subject" ]; then
  subject="$(channel_names | head -n1 | while read -r c; do pinned_version "$c"; done)"
fi

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
# -c/--no-gpg-sign: a checkout with commit.gpgSign or tag.gpgSign set (this is
# the case when the script is replayed locally) would otherwise sign with
# somebody's key and stop for a passphrase.
git commit --no-gpg-sign -m "v${subject}"

# Upstream tags its releases as v<version>, so tag the same way and the flake
# can be pinned as ...?ref=v<version>. A version that is already tagged is moved
# along when upstream replaced the artifact behind it.
refs=()
tagged=""
while read -r channel; do
  version="$(pinned_version "$channel")"
  [ -n "$version" ] || continue
  # Both channels can end up on the same version (a prerelease promoted to a
  # release keeps its version); one tag is enough for it.
  case " $tagged " in
  *" $version "*)
    continue
    ;;
  esac
  tagged="$tagged $version"

  # The CI checkout has no tags (actions/checkout fetches with --no-tags), so
  # ask the remote: pushing an existing tag without force fails the atomic push.
  if git ls-remote --exit-code --refs origin "refs/tags/v${version}" >/dev/null 2>&1; then
    git -c tag.gpgSign=false tag -f -a "v${version}" -m "xmcl ${version}"
    refs+=("+refs/tags/v${version}")
  else
    git -c tag.gpgSign=false tag -a "v${version}" -m "xmcl ${version}"
    refs+=("refs/tags/v${version}")
  fi
done < <(channel_names)

# One atomic push: the branch and its tags land together or not at all.
git push --atomic origin HEAD "${refs[@]}"
