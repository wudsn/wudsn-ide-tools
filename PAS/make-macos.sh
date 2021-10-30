#!/bin/bash

export OS="macOS"
export EXT="macos"
export EXTI32="$EXT-i386"
export EXTI64="$EXT-x86-64"
export EXTA64="$EXT-aarch-64"
export EXTPPC="$EXT-powerpc"

echo Creating $OS binaries.

#------------------------------------------------------------------------
# Install XCode Commnd Line Tools if required.
#------------------------------------------------------------------------
function installXCodeCommandlineTools() {
  export XCODE_COMMANDLINE_TOOLS="/Library/Developer/CommandLineTools"
  if [ ! -f $XCODE_COMMANDLINE_TOOLS ]; then
    xcode-select --install
  fi
  export XCODE_COMMANDLINE_TOOLS_LIBS="${XCODE_COMMANDLINE_TOOLS}/SDKs/MacOSX.sdk"
}

function compileWithFPC($NAME, $SOURCE, $TARGET, $ARCHITECTURE){
  COMMAND=$1
  EXECUTABLE=$2
  ARCHITECTURE=$3
  SOURCE=mp.pas
  OPT="-Mdelphi -O3 -XR$XCODE_COMMANDLINE_TOOLS_LIBS"

  if command -v $COMMAND &> /dev/null
  then
    echo Creating MP - $OS $ARCHITECTURE - $EXECUTABLE
    $COMMAND $OPT -o$EXECUTABLE $SOURCE.pas
    rm -f *.o
  else
    echo Creation of MP - $OS $ARCHITECTURE - $EXECUTABLE skipped. Command $COMMAND is not available.
  fi
}

#------------------------------------------------------------------------
# Create MP.
#------------------------------------------------------------------------
function makeMPs() {

function makeMP($EXTENSION){
  compileWithFPC("MP", "mp", $EXTENSION)
}

cd MP

#makeMP $EXTI32
makeMP $EXTI64
makeMP $EXTA64
 
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

installXCodeCommandlineTools
makeMPs

#------------------------------------------------------------------------
# List result.
#------------------------------------------------------------------------
echo Done.
displayExecutables MP /

