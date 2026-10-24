#!/usr/bin/env bash
# Prints "true" when the mobile app changed between two commits, otherwise
# "false". A change of only the version line in app/pubspec.yaml (made by
# cz bump) does not count. Used by the GitHub Actions workflows.
#
# Usage: bash scripts/app_changed.sh <base-commit> <head-commit>
set -euo pipefail

base="${1:-}"
head="${2:-HEAD}"

# No usable base (first push of a branch, first tag): treat as changed.
if [ -z "$base" ] || ! git cat-file -e "${base}^{commit}" 2>/dev/null; then
  echo true
  exit 0
fi

files=$(git diff --name-only "$base" "$head" -- app/)
if [ -z "$files" ]; then
  echo false
  exit 0
fi
if [ "$files" != "app/pubspec.yaml" ]; then
  echo true
  exit 0
fi

other_changes=$(git diff -U0 "$base" "$head" -- app/pubspec.yaml \
  | grep -E '^[+-]' | grep -vE '^(\+\+\+|---)' | grep -vE '^[+-]version:' || true)
if [ -n "$other_changes" ]; then
  echo true
else
  echo false
fi
