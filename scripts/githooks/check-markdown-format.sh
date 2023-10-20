#!/bin/bash

set -e

# Pre-commit git hook to check the Markdown file formatting rules compliance
# over changed files.
#
# Usage:
#   $ ./check-markdown-format.sh
#
# Options:
#   BRANCH_NAME=other-branch-than-main  # Branch to compare with, default is `origin/main`
#   ALL_FILES=true                      # Check all files, default is `false`
#   VERBOSE=true                        # Show all the executed commands, default is `false`
#
# Exit codes:
#   0 - All files are formatted correctly
#   1 - Files are not formatted correctly
#
# Notes:
#   1) Please, make sure to enable Markdown linting in your IDE. For the Visual
#   Studio Code editor it is `davidanson.vscode-markdownlint` that is already
#   specified in the `./.vscode/extensions.json` file.
#   2) To see the full list of the rules, please visit
#   https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md

# ==============================================================================

# SEE: https://github.com/igorshubovych/markdownlint-cli/pkgs/container/markdownlint-cli, use the `linux/amd64` os/arch
image_version=v0.35.0@sha256:4ec089301e2e3e1298424f4d2b5d9e18af3aa005402590770c339b6637100dc6

# ==============================================================================

function main() {

  if is-arg-true "$ALL_FILES"; then
    # Check all files
    files="$(find ./ -type f -name "*.md")"
  else
    # Check changed files only
    files="$( (git diff --diff-filter=ACMRT --name-only ${BRANCH_NAME:-origin/main} "*.md"; git diff --name-only "*.md") | sort | uniq )"
  fi

  if [ -n "$files" ]; then
    docker run --rm --platform linux/amd64 \
      --volume=$PWD:/workdir \
      ghcr.io/igorshubovych/markdownlint-cli:$image_version \
        $files \
        --disable MD013 MD033 \
        --ignore .github/PULL_REQUEST_TEMPLATE.md
  fi
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
