#!/bin/bash
# Run from BASH terminal.

set -e

OS="macosx"

pushd ASM
bash -v make-$OS.sh
popd
pushd PAS
bash -v make-$OS.sh
popd
echo
