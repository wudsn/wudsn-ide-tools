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

export platform="`uname -s`"
export arch="`uname -a`"
if [[ $platform == Linux* ]]
 then {
        export target=linux
      }
 else if [[ $platform = "Darwin" ]]
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

export jacdir=~/jac
export wudsndir=$jacdir/wudsn
export idefile=wudsn-ide-$target

export tmpdir=/tmp
export tmpjacdir=$tmpdir/jac

rm -rf $tmpjacdir
mkdir -p $tmpjacdir

function package(){
  pushd ~
  export zipfile=$tmpjacdir/$idefile.tar.gz
  tar -cv --exclude='.DS_Store' --exclude='.git' -f $zipfile jac
  popd
  ls -l $zipfile

}

#download
package
#upload
