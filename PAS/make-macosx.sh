#!/bin/bash

export OS="Mac OS X"
export EXT="macosx"
export EXTI32="$EXT-i386"
export EXTI64="$EXT-x86-64"
export EXTA64="$EXT-aarch-64"
export EXTPPC="$EXT-powerpc"

echo Creating $OS binaries.

#------------------------------------------------------------------------
# Create MP.
#------------------------------------------------------------------------
function makeMPs() { 

function makeMP(){
  command=$1
  executable=$2
  if command -v $command &> /dev/null
  then
    echo Creating MP - $OS Intel 64-bit version
    $command -Mdelphi -v -O3 -XXs -o$executable mp.pas
    rm -f mp.o
  else
    echo Command $command not available. Creation of $executable skipped.
  fi
}

cd MP

#makeMP ppc386 mp.$EXTI64 "Intel 32-bit"
makeMP ppcx64 mp.$EXTI64 "Intel 64-bit"

#echo Creating MADS - $OS M1 64-bit version
#fpc -Paarch64 -Mdelphi -v -O3 -XXs -omads.$EXTA64 mads.pas
#rm -f mads.o

 
cd ..

}

#------------------------------------------------------------------------
# Display Result Details.
#------------------------------------------------------------------------
function displayExecutables() {
  echo Executables for $1: 
  for f in $1$2*.$EXTI32 $1$2*.$EXTI64 $1$2*.$EXTPPC
  do
    if test -f $f; then
     file $f
     ls -o $f
    fi
  done
}

makeMPs

#------------------------------------------------------------------------
# List result. 
#------------------------------------------------------------------------
echo Done.
displayExecutables MP /

