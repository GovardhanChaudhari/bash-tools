#!/usr/bin/env bash
# Utility helper functions for CodeLLM related install / maintenance scripts.
# To use these helpers, simply source this file in your script, e.g.:
#   source "$(dirname -- "${BASH_SOURCE[0]}")/utils.sh"
# ---------------------------------------------------------------------------

# Print an informational message prefixed with [CodeLLM] in blue.
msg() {
  printf "\e[1;34m[CodeLLM] %s\e[0m\n" "$1"
}

# Print an error message prefixed with [CodeLLM] Error: in red to stderr.
err() {
  printf "\e[1;31m[CodeLLM] Error: %s\e[0m\n" "$1" >&2
}

# "Available in functions" – check if a command exists in PATH.
aif() {
  command -v "$1" >/dev/null 2>&1
}
