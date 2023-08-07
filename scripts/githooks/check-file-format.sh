#!/bin/bash

set +e

# Pre-commit git hook to check the EditorConfig rules compliance over changed
# files. It ensures all non-binary files across the codebase are formatted
# according to the style defined in the `.editorconfig` file.
#
# Usage:
#   $ ./check-file-format.sh
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
#   1) Please, make sure to enable EditorConfig linting in your IDE. For the
#   Visual Studio Code editor it is `editorconfig.editorconfig` that is already
#   specified in the `./.vscode/extensions.json` file.
#   2) Due to the file name escaping issue files are checked one by one.

# ==============================================================================

# SEE: https://hub.docker.com/r/mstruebing/editorconfig-checker/tags, use the `linux/amd64` os/arch
image_version=2.7.0@sha256:0f8f8dd4f393d29755bef2aef4391d37c34e358d676e9d66ce195359a9c72ef3
exit_code=0

# ==============================================================================

function main() {

  if is-arg-true "$ALL_FILES"; then

    # Check all files
    docker run --rm --platform linux/amd64 \
      --volume=$PWD:/check \
      mstruebing/editorconfig-checker:$image_version \
        ec \
          --exclude '.git/'

  else

    # Check changed files only
    files=$( (git diff --diff-filter=ACMRT --name-only ${BRANCH_NAME:-origin/main}; git diff --name-only) | sort | uniq )
    if [ -n "$files" ]; then
      while read file; do
        docker run --rm --platform linux/amd64 \
          --volume=$PWD:/check \
          mstruebing/editorconfig-checker:$image_version \
            ec \
              --exclude '.git/' \
              "$file"
        [ $? != 0 ] && exit_code=1 ||:
      done < <(echo "$files")
    fi

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

exit $exit_code
