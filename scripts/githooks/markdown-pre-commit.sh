#!/bin/bash

set -e

# Pre-commit git hook to check the Markdown file formatting rules compliance
# over changed files.
#
# Usage:
#   $ ./markdown-pre-commit.sh
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

image_version=v0.34.0@sha256:230b1e0e0fa1c7dd6261e025cacf6761ac5ba3557a6a919eec910d731817ff28

# ==============================================================================

function main() {

  if is-arg-true "$ALL_FILES"; then
    # Check all files
    files="*.md"
  else
    # Check changed files only
    files="$(git diff --diff-filter=ACMRT --name-only ${BRANCH_NAME:-origin/main} "*.md")"
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
