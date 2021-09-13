#!/bin/bash
# Build script for creating the WUDSN IDE zero installation download archives.
# This script builds the Linux 32-bit version and the Mac OS X 32-bit version.
# It assumes that the latest version of the compilers are present locally.
#
# The installation directory on Windows is "C:\jac\wudsn".
# The installation directory on Linux is "~/jac/wudsn".
# The installation directory on Mac OS X is "~/jac/wudsn".
#
# The following folders are taken from the Windows 64-bit zero installation download archive
# - jac/wudsn/Workspace (i.e. all sources, except .metadata with the platform specific preferences)
# The remaining folders are taken from the local Linux or Mac OS X installation.

# Enable verbose output/echo
set -v

# Stop on first error
set -e

# Change working directory
pushd /tmp

# Compute target

export platform="`uname`"
if [[ $platform == Linux* ]]
 then {
        export target=linux
      }
 else if [[ $platform = Darwin* ]]
      then {
             export target=macosx-x86_64
           }
      else if [[ $platform == CYGWIN_NT* ]]
           then {
                  export target=windows
                }
           else {
                  echo Unknown OS platform $platform.
                  exit
                }
           fi
      fi
fi
echo Target '$target' detected on platform '$platform'.

export tmpdir=/tmp/jac
export tmpwudsndir=$tmpdir/wudsn
export jacdir=~/jac
export wudsndir=$jacdir/wudsn
export idefile=wudsn-ide-$target

rm -rf $tmpdir
mkdir -p $tmpdir

function download() {
  export download_url=https://www.wudsn.com/productions/java/ide/downloads/wudsn-ide-win64.zip
  export zipfile=wudsn-ide.zip

  echo Building WUDSN IDE for target "'$target'".
  echo Downloading "$download_url".
  curl -o $zipfile -z $zipfile $download_url

  echo Unzipping archive.
  rm -rf $zipfile.log jac
  unzip -o $zipfile -d $tmpdir >$zipfile.log
}

function merge(){
  echo Merging $tmpwudsndir with local installation $wudsndir.
  rm -f $targetfile
# Keep local workspace .metadata with settings
  rm -rf $tmpwudsndir/.metadata
# Remove local workspace examples
  rm -rf $wudsndir/Workspace/*
# Take over global workspace examples
  mv $tmpwudsndir/Workspace/* $wudsndir/Workspace
}

function package(){
  pushd $jacdir
  export tarfile=$tmpdir/$idefile.tar
  export zipfile=$tarfile.gz
  tar -cvf $tarfile wudsn
  gzip $tarfile
  popd
  ls -l $zipfile

}

#download
package
#upload
