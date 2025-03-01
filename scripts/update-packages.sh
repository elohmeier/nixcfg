#!/usr/bin/env bash

set -e
set -x

nix-update --flake --commit --version=branch tabula-java-jar
nix-update --flake --commit kanboard
