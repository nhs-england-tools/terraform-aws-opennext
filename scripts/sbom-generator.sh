#!/bin/bash

set -e

# Script to generate SBOM (Software Bill of Materials) for the repository
# content and any artefact created by the CI/CD pipeline.
#
# Usage:
#   $ ./generate-sbom.sh
#
# Options:
#   VERBOSE=true  # Show all the executed commands, default is `false`

# ==============================================================================

# SEE: https://github.com/anchore/syft/pkgs/container/syft, use the `linux/amd64` os/arch
image_version=v0.84.1@sha256:9a8f80eee3984d4a3f9a86e4d66e739e30dfc34564d76d3574f98798db5d5b35

# ==============================================================================

function main() {

  create-sbom
  enrich-sbom
}

function create-sbom() {

  docker run --rm --platform linux/amd64 \
    --volume $PWD:/scan \
    ghcr.io/anchore/syft:$image_version \
      packages dir:/scan \
      --config /scan/scripts/config/.syft.yaml \
      --output spdx-json=/scan/sbom-spdx.tmp.json
}

function enrich-sbom() {

  git_url=$(git config --get remote.origin.url)
  git_branch=$(git rev-parse --abbrev-ref HEAD)
  git_commit_hash=$(git rev-parse HEAD)
  git_tags=$(echo \"$(git tag | tr '\n' ',' | sed 's/,$//' | sed 's/,/","/g')\" | sed 's/""//g')
  pipeline_run_id=${GITHUB_RUN_ID:-0}
  pipeline_run_number=${GITHUB_RUN_NUMBER:-0}
  pipeline_run_attempt=${GITHUB_RUN_ATTEMPT:-0}

  docker run --rm --platform linux/amd64 \
    --volume $PWD:/repo \
    --workdir /repo \
    ghcr.io/make-ops-tools/jq:latest \
      '.creationInfo |= . + {"repository":{"url":"'${git_url}'","branch":"'${git_branch}'","tags":['${git_tags}'],"commitHash":"'${git_commit_hash}'"},"pipeline":{"id":'${pipeline_run_id}',"number":'${pipeline_run_number}',"attempt":'${pipeline_run_attempt}'}}' \
      sbom-spdx.tmp.json \
        > sbom-spdx.json
  rm -f sbom-spdx.tmp.json
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
