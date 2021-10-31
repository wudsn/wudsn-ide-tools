#!/bin/bash
# Run from BASH terminal.
# Check using https://www.shellcheck.net/.

set -e

function getLanguageList(){
    echo "$LANGUAGE_ASM $LANGUAGE_PAS"
}

function getLanguageName(){
    LANGUAGE=$1
    case $LANGUAGE in

        "$LANGUAGE_ASM")
        echo "Assembler";
        ;;
        "$LANGUAGE_PAS")
        echo "Pascal";
        ;;
        *)
        echo "ERROR: Unknown language $LANGUAGE."
        exit 1
    esac
}

function getLanguageTools(){
    LANGUAGE=$1
    cd "$LANGUAGE"
    TOOLS=$(ls -d "*/")
    TOOLS="${TOOLS//\// }"
    echo "$TOOLS"
    cd ..
}

#------------------------------------------------------------------------
# Display File Details.
#------------------------------------------------------------------------
function displayFiles() {
  FILTER="$PATH_PREFIX*$FILE_EXTENSION"
  FILE_FOUND="false"
  echo "Filter $FILTER"
  for FILE in $FILTER
  do
    if test -f "$FILE"; then
     FILE_FOUND="true"
     FILE_NAME="$FILE"
     FILE_DATE=$(date -r "$FILE" "+%Y-%m-%d %H:%M:%S")
     FILE_INFO=$(file -b "$FILE")
     echo "- $FILE_INFO $FILE_DATE"
     TOOL_VERSION=""
     if test -f "$FILE".version; then
         TOOL_VERSION=$(cat "$FILE".version)
     fi
     echo "<tr><td>$LANGUAGE_NAME</td><td>$TOOL</td><td>$TOOL_VERSION</td><td>$OS_NAME</td><td>$ARCHITECTURE</td><td>$FILE_NAME</td><td>$FILE_INFO</td><td>$FILE_DATE</th><tr>">>"$OUTPUT_HTML"
    fi
  done
  if [[ "$FILE_FOUND" == "false" ]]
  then
     echo "- No file found."
  fi
}

#------------------------------------------------------------------------
# Get human readabe name of OS.
#------------------------------------------------------------------------
function getOSName(){
    OS=$1
    case $OS in
        "$OS_LINUX")
        echo "Linux";
        ;;
        "$OS_MACOS")
        echo "macOS";
        ;;
        "$OS_WINDOWS")
        echo "Windows";
        ;;
        *)
        echo "ERROR: Unknown OS $OS."
        exit 1
    esac
}

function getOSList(){
    echo "$OS_LINUX $OS_MACOS $OS_WINDOWS"
}

function getArchitectureList(){
    echo "$ARCHITECTURE_I32 $ARCHITECTURE_I64 $ARCHITECTURE_A64 $ARCHITECTURE_PPC $ARCHITECTURE_JAVA"
}


function getFileExtension(){
     ARCHITECTURE=$1
    case $OS in
        "$OS_LINUX")
        case $ARCHITECTURE in
            "$ARCHITECTURE_I32" | "$ARCHITECTURE_I64")
                echo ".$OS-$ARCHITECTURE";
            ;;
            "$ARCHITECTURE_JAVA")
                echo ".jar"
            ;;
        esac
        ;;
         "$OS_MACOS")
        case $ARCHITECTURE in
            "$ARCHITECTURE_A64" | "$ARCHITECTURE_I32" | "$ARCHITECTURE_I64" | "$ARCHITECTURE_PPC" )
                echo ".$OS-$ARCHITECTURE";
            ;;
            "$ARCHITECTURE_JAVA")
                echo ".jar"
            ;;
        esac
        ;;
        "$OS_WINDOWS")
        
        case $ARCHITECTURE in
            "$ARCHITECTURE_I32")
                echo ".exe"
            ;;
             "$ARCHITECTURE_I64")
                echo "-$ARCHITECTURE_I64.exe"
            ;;
            "$ARCHITECTURE_JAVA")
                echo ".jar"
            ;;
        esac
        ;;
        *)
        echo "ERROR: Unknown OS $OS in getFileExtension()."
        exit 1
        ;;
    esac
}

function getExecutableName(){
    TARGET=$1
    OS=$2
    ARCHITECTURE=$3
    echo "$TARGET$(getFileExtension "$ARCHITECTURE")"
}

function forAllArchitectures(){
  FUNCTION=$1
  OS_LIST=$(getOSList)
  for OS in $OS_LIST
  do
    OS_NAME=$(getOSName "$OS")
    ARCHITECTURE_LIST=$(getArchitectureList)
      for ARCHITECTURE in $ARCHITECTURE_LIST
      do
          FILE_EXTENSION=$(getFileExtension "$ARCHITECTURE")
          #echo "INFO: Architecture $ARCHITECTURE on $OS_NAME has file extension $FILE_EXTENSION".
          
          if [ -n "$FILE_EXTENSION" ]
          then
                #echo "$OS $OS_NAME $ARCHITECTURE *$FILE_EXTENSION"
             $FUNCTION
#         else
#            echo "INFO: Architecture $ARCHITECTURE is not supported on $OS_NAME".
         fi
      done
  done
}

function displayLanguagesFiles(){
    LANGUAGE_LIST=$(getLanguageList)
    for LANGUAGE in $LANGUAGE_LIST
    do
        LANGUAGE_NAME=$(getLanguageName "$LANGUAGE")
        TOOLS=$(getLanguageTools "$LANGUAGE")
        for TOOL in $TOOLS
        do
            echo "Language $LANGUAGE_NAME, Tool $TOOL"
#            TARGET=${TOOL,,}
            TARGET=$(echo "$TOOL" | tr '[:upper:]' '[:lower:]')
            PATH_PREFIX=$LANGUAGE/$TOOL/$TARGET
            forAllArchitectures displayFiles
        done
    done
}

#------------------------------------------------------------------------
# Compile Pascal source file with Free Pascal Compiler
#------------------------------------------------------------------------
function generateHTML(){
    OUTPUT_HTML="Readme.html"
    echo "<!DOCTYPE html><html><head><title>WUDSN IDE Tools</title></head><body><table border=\"1\">">$OUTPUT_HTML
    echo "<tr><th>Language</th><th>Tool</th><th>Version</th><th>OS</th><th>Architecture</th><th>File Name</th><th>File Type</th><th>File Date</th></tr>">>$OUTPUT_HTML

    displayLanguagesFiles 

    echo "</table></body></html>">>$OUTPUT_HTML
    open $OUTPUT_HTML
}

#------------------------------------------------------------------------
# Install XCode Commnd Line Tools if required.
#------------------------------------------------------------------------
installXCodeCommandlineTools() {
  export XCODE_COMMANDLINE_TOOLS="/Library/Developer/CommandLineTools"
  if [ ! -d $XCODE_COMMANDLINE_TOOLS ]; then
    xcode-select --install
  fi
  export XCODE_COMMANDLINE_TOOLS_LIBS="${XCODE_COMMANDLINE_TOOLS}/SDKs/MacOSX.sdk"
}

#------------------------------------------------------------------------
# Compile Pascal source file with Free Pascal Compiler
#------------------------------------------------------------------------
function compileWithFPC(){

    NAME=$1
    SOURCE=$2
    TARGET=$3
    OS=$4
    ARCHITECTURE=$5
    EXECUTABLE=$(getExecutableName "$TARGET" "$OS" "$ARCHITECTURE")
    echo "INFO: compileWithFPC $EXECUTABLE"
    pushd "$NAME"

    OPT="-Mdelphi -O3"
  
    case $OS in

        "$OS_LINUX")
        COMMAND="none";
        ;;
        "$OS_MACOS")
          OPT="$OPT -XR$XCODE_COMMANDLINE_TOOLS_LIBS"
        COMMAND="ppcx64"
        ;;
        "$OS_WINDOWS")
        COMMAND="FPC.exe";
        ;;
        *)
        echo "ERROR: Unknown OS $OS in compileWithFPC()."
        exit 1
        ;;
    esac

  if command -v $COMMAND &> /dev/null
  then
    echo Creating "$NAME" - "$OS" "$ARCHITECTURE" - "$EXECUTABLE"
    $COMMAND "$OPT" -o"$EXECUTABLE" "$SOURCE"
    if [ -f "$SOURCE".version ]
    then cp "$SOURCE".version "$EXECUTABLE".version
    fi
    rm -f "*.o"
  else
    echo Creation of "$NAME" - "$OS" "$ARCHITECTURE" - "$EXECUTABLE" skipped. Command $COMMAND is not available.
  fi
  
  popd
}


#VERBOSE=-v
    installXCodeCommandlineTools

    LANGUAGE_ASM="ASM"
    LANGUAGE_PAS="PAS"

    OS_LINUX="linux"
    OS_MACOS="macos"
    OS_WINDOWS="windows"

    ARCHITECTURE_A64="aarch-64"
    ARCHITECTURE_I32="i386"
    ARCHITECTURE_I64="x86-64"
    ARCHITECTURE_JAVA="java"
    ARCHITECTURE_PPC="powerpc"


    pushd ASM
    compileWithFPC MADS mads.pas mads $OS_MACOS $ARCHITECTURE_I64
    popd

    pushd PAS
    compileWithFPC MP mp.pas mp $OS_MACOS $ARCHITECTURE_I64
    popd

    generateHTML
pushd ASM
echo source "$VERBOSE" make-"$OS".sh
popd
pushd PAS
echo source "$VERBOSE" make-"$OS".sh
popd
echo

