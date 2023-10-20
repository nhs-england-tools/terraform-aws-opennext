#!/bin/bash

set -e

# Count lines of code of this repository.
#
# Usage:
#   $ ./cloc-repository.sh
#
# Options:
#   VERBOSE=true    # Show all the executed commands, default is `false`
#   FORMAT=[format] # Set output format [default,cloc-xml,sloccount,json], default is `default`

# ==============================================================================

# SEE: https://github.com/make-ops-tools/gocloc/pkgs/container/gocloc, use the `linux/amd64` os/arch
image_version=latest@sha256:6888e62e9ae693c4ebcfed9f1d86c70fd083868acb8815fe44b561b9a73b5032

# ==============================================================================

function main() {

  docker run --rm --platform linux/amd64 \
    --volume=$PWD:/workdir \
    ghcr.io/make-ops-tools/gocloc:$image_version \
      --output-type=${FORMAT:-default} .
}

function is-arg-true() {

  if [[ "$1" =~ ^(true|yes|y|on|1|TRUE|YES|Y|ON)$ ]]; then
    return 0
  else
    return 1
  fi
}

# ==============================================================================

is-arg-true "$VERBOSE" && set -x

main $*

exit 0
