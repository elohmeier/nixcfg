#!/usr/bin/env bash

set -e
set -x

nix-update --flake --commit --version=branch tabula-java
nix-update --flake --commit kanboard
