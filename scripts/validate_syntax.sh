#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

declare -a failures=()

while IFS= read -r file; do
  if ! bash -n "${file}"; then
    failures+=("${file}")
  fi
done < <(find "${ROOT_DIR}" -type f -name "*.sh" ! -path "*/.git/*")

if (( ${#failures[@]} > 0 )); then
  printf 'Syntax errors detected in the following scripts:\n'
  printf ' - %s\n' "${failures[@]}"
  exit 1
fi

printf 'All shell scripts passed syntax validation.\n'

