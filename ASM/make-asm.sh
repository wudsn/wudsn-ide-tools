#!/bin/bash
# Build platform specific versions.
# The resulting archive for the target platform is uploaded again to "/tmp/compilers".
# Compatible with Linux, Mac OS X and Windows (Cygwin64).
# Last changed on 2017-11-05.

set -e
pushd /tmp

export platform="`uname`"
if [[ $platform == Linux* ]]
 then export target=linux
 else if [[ $platform = Darwin* ]]
      then export target=macosx
      else if [[ $platform == CYGWIN_NT* ]]
           then export target=windows
           else echo Unknown OS platform $platform.
                exit
           fi
      fi
fi

echo Compiling ASM for target "'$target'".

cd ASM
chmod a+x ASM/*.sh

echo
echo Calling make-$target.sh.
rm -f compilers-$target.zip
./make-$target.sh >>../compilers.log 2>&1
if [ $target = "linux" -o $target = "macosx" ]
then ls ATASM/*.$target* DASM/bin/*.$target* MADS/*.$target* | zip -@ ../compilers-$target.zip
else ls ATASM/*.exe      DASM/bin/*.exe      MADS/*.exe      | zip -@ ../compilers-$target.zip
fi
echo
echo Compiler errors and warnings:
cat ../compilers.log | grep -i 'error\|warning'

cd ..
rm -rf ASM
echo
echo Uploading "/tmp/compilers/compilers-$target.zip".
echo put compilers-$target.zip >sftp.txt
echo quit >>sftp.txt
sftp -b sftp.txt -i ~/.ssh/id_rsa  u52906944-compilers@home280969378.1and1-data.host

popd
