#!/bin/bash
# Run from BASH terminal.

set -e

OS="macos"
#VERBOSE=-v

pushd ASM
bash $VERBOSE make-$OS.sh
popd
pushd PAS
bash $VERBOSE make-$OS.sh
popd
echo
