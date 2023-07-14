#!/bin/bash

set -e

# Pre-commit git hook to scan for secrets hardcoded in the codebase.
#
# Usage:
#   $ ./scan-secrets.sh
#
# Options:
#   ALL_FILES=true  # Scan whole git history or 'last-commit', default is `false`
#   VERBOSE=true    # Show all the executed commands, default is `false`
#
# Exit codes:
#   0 - No leaks present
#   1 - Leaks or error encountered
#   126 - Unknown flag

# ==============================================================================

# SEE: https://github.com/gitleaks/gitleaks/pkgs/container/gitleaks, use the `linux/amd64` os/arch
image_version=v8.17.0@sha256:99e40155529614d09d264cc886c1326c9a4593ad851ccbeaaed8dcf03ff3d3d7

# ==============================================================================

function main() {

  if is_arg_true "$ALL_FILES"; then
    # Scan whole git history
    cmd="detect --source=/scan --verbose --redact"
  elif [ "$ALL_FILES" == "last-commit" ]; then
    # Scan the last commit
    cmd="detect --source=/scan --verbose --redact --log-opts=-1"
  else
    # Scan staged files only
    cmd="protect --source=/scan --verbose --staged"
  fi
  # Include base line file if it exists
  if [ -f $PWD/scripts/config/.gitleaks-baseline.json ]; then
    cmd="$cmd --baseline-path /scan/scripts/config/.gitleaks-baseline.json"
  fi

  docker run --rm --platform linux/amd64 \
    --volume=$PWD:/scan \
    --workdir=/scan \
    ghcr.io/gitleaks/gitleaks:$image_version \
      $cmd \
      --config /scan/scripts/config/.gitleaks.toml
}

function is_arg_true() {

  if [[ "$1" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$ ]]; then
    return 0
  else
    return 1
  fi
}

# ==============================================================================

is_arg_true "$VERBOSE" && set -x

main $*

exit 0
