#!/usr/bin/env bash
# Utility helper functions for CodeLLM related install / maintenance scripts.
# To use these helpers, simply source this file in your script, e.g.:
#   source "$(dirname -- "${BASH_SOURCE[0]}")/utils.sh"
# ---------------------------------------------------------------------------

# ---------------------------- Configuration --------------------------------
# You can optionally set MSG_PREFIX **before** sourcing this file to override
# the prefix shown in msg/err output, e.g.:
#   MSG_PREFIX="Neovim"; source ./utils.sh
# ---------------------------------------------------------------------------

# Figure out the prefix: use user-supplied $MSG_PREFIX if set, otherwise derive
# it from the calling script name (strip path & extension, then capitalise first
# letter for nicer output).
if [[ -n "${MSG_PREFIX:-}" ]]; then
  __PREFIX="$MSG_PREFIX"
else
  # Basename of the top-level script that sourced this file (contained in $0)
  __PREFIX="$(basename -- "$0")"
  __PREFIX="${__PREFIX%.*}"   # remove extension
  __PREFIX="${__PREFIX^}"     # capitalise first letter
fi

# Ensure prefix is not empty (fallback just in case)
__PREFIX="${__PREFIX:-Script}"

# ---------------------------- Helper Functions -----------------------------
# Print an informational message prefixed with [<prefix>] in blue.
msg() {
  printf "\e[1;34m[%s] %s\e[0m\n" "${__PREFIX}" "$1"
}

# Print an error message prefixed with [<prefix>] Error: in red to stderr.
err() {
  printf "\e[1;31m[%s] Error: %s\e[0m\n" "${__PREFIX}" "$1" >&2
}

# "Available in functions" – check if a command exists in PATH.
aif() {
  command -v "$1" >/dev/null 2>&1
}
