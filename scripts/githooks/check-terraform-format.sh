#!/bin/bash

set -e

# Pre-commit git hook to check format Terraform code.
#
# Usage:
#   $ ./check-terraform-format.sh
#
# Options:
#   CHECK_ONLY=true # Do not format, run check only, default is `false`
#   VERBOSE=true    # Show all the executed commands, default is `false`

# ==============================================================================

versions=$(git rev-parse --show-toplevel)/.tool-versions
terraform_version=$(grep terraform $versions | cut -f2 -d' ')
image_version=${terraform_version:-latest}

# ==============================================================================

function main() {

  opts=
  if is-arg-true "$CHECK_ONLY"; then
    opts="-check"
  fi

  docker run --rm --platform linux/amd64 \
    --volume=$PWD:/workdir \
    hashicorp/terraform:$image_version \
      fmt -recursive $opts
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
