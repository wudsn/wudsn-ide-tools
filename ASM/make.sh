#!/bin/bash
# Download current "/tmp/compilers/compilers.zip" from "http://www.wudsn.com". and unzip for local compiling.
# Everything is downloaded to /tmp and processed in the /tmp/ASM folder.
# Compatible with Linux, Mac OS X and Windows (Cygwin64).
# Last changed on 2017-11-05.

set -e
pushd /tmp

export download_url=http://www.wudsn.com/tmp/compilers/compilers.zip
export zipfile=compilers.zip

echo Building WUDSN IDE for target "'$target'".
echo Downloading "$download_url".
curl -o $zipfile -z $zipfile $download_url

rm -rf ASM $zipfile.log
unzip -o $zipfile >$zipfile.log

popd
