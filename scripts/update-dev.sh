#!/usr/bin/env bash

set -ex

nix flake update --flake ./dev/private
nix hash path ./dev/private >./dev/private.narHash
