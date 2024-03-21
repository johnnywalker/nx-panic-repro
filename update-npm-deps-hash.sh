#!/usr/bin/env bash
# shellcheck shell=bash

# This script uses `prefetch-npm-deps` to recalculate the NPM dependencies hash and then update
# `package.nix` with the new value.

set -eo pipefail

npm install

npmDepsHash=$(prefetch-npm-deps ./package-lock.json)

echo
echo "Calculated hash: $npmDepsHash"

sed -E 's#\bnpmDepsHash = ".*?"#npmDepsHash = "'"$npmDepsHash"'"#' -i "package.nix"
