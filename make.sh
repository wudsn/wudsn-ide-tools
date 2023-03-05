#!/bin/bash
# Run from BASH terminal.
# Check using https://www.shellcheck.net/.

set -e

#------------------------------------------------------------------------
# Get list of supported languages.
#------------------------------------------------------------------------
function getLanguageList(){
    echo "$LANGUAGE_ASM $LANGUAGE_PAS"
}

#------------------------------------------------------------------------
# Get human readabe name of a language.
#------------------------------------------------------------------------
function getLanguageName(){
    local LANGUAGE=$1
    case $LANGUAGE in

        "$LANGUAGE_ASM")
        echo "Assembler";
        ;;
        "$LANGUAGE_PAS")
        echo "Pascal";
        ;;
        *)
        echo "ERROR: Unknown language '$LANGUAGE'."
        exit 1
    esac
}

#------------------------------------------------------------------------
# Get list of tools for a language.
#------------------------------------------------------------------------
function getLanguageTools(){
    local LANGUAGE=$1
    pushd "$LANGUAGE" >/dev/null 
    local TOOLS
    TOOLS=$(ls -d -- */)
    TOOLS="${TOOLS//\// }"
    echo "$TOOLS"
    popd >/dev/null
}

#------------------------------------------------------------------------
# Get human readabe name of an OS.
#------------------------------------------------------------------------
function getOSName(){
  local OS=$1
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
      echo "ERROR: Unknown OS '$OS'."
      exit 1
  esac
}

#------------------------------------------------------------------------
# Get list of supported OSes.
#------------------------------------------------------------------------
function getOSList(){
  echo "$OS_LINUX $OS_MACOS $OS_WINDOWS"
}

#------------------------------------------------------------------------
# Get list of supported architectures.
#------------------------------------------------------------------------
function getArchitectureList(){
  echo "$ARCHITECTURE_I32 $ARCHITECTURE_I64 $ARCHITECTURE_A64 $ARCHITECTURE_PPC $ARCHITECTURE_JAVA"
}

#------------------------------------------------------------------------
# Get executable file extension for an OS and architecture.
# Returns empty string if not supported 
#------------------------------------------------------------------------
function getFileExtension(){
    local OS=$1
    local ARCHITECTURE=$2
    case ${OS} in
        "${OS_LINUX}")
        case ${ARCHITECTURE} in
            "${ARCHITECTURE_I32}" | "${ARCHITECTURE_I64}")
                echo ".${OS}-${ARCHITECTURE}";
            ;;
            "$ARCHITECTURE_JAVA")
                echo ".jar"
            ;;
        esac
        ;;
         "${OS_MACOS}")
        case ${ARCHITECTURE} in
            "${ARCHITECTURE_A64}" | "${ARCHITECTURE_I32}" | "${ARCHITECTURE_I64}" | "${ARCHITECTURE_PPC}" )
                echo ".${OS}-${ARCHITECTURE}";
            ;;
            "${ARCHITECTURE_JAVA}")
                echo ".jar"
            ;;
        esac
        ;;
        "${OS_WINDOWS}")
        
        case ${ARCHITECTURE} in
            "${ARCHITECTURE_I32}")
                echo ".exe"
            ;;
             "${ARCHITECTURE_I64}")
                echo "-${ARCHITECTURE_I64}.exe"
            ;;
            "${ARCHITECTURE_JAVA}")
                echo ".jar"
            ;;
        esac
        ;;
        *)
        echo "ERROR: Unknown OS '${OS}' in getFileExtension()."
        exit 1
        ;;
    esac
}

#------------------------------------------------------------------------
# Install XCode Commnd Line Tools if required.
#------------------------------------------------------------------------
installXCodeCommandlineTools(){
  export XCODE_COMMANDLINE_TOOLS="/Library/Developer/CommandLineTools"
  if [ ! -d $XCODE_COMMANDLINE_TOOLS ]; then
    xcode-select --install
  fi
  export XCODE_COMMANDLINE_TOOLS_LIBS="${XCODE_COMMANDLINE_TOOLS}/SDKs/MacOSX11.1.sdk"
}

#------------------------------------------------------------------------
# Compile with command $1.
#------------------------------------------------------------------------
function compileWithCommand(){
  local COMMAND=$1
  # Check if command is present
  if command -v $COMMAND &>/dev/null; then
  	local COMMAND_LINE
  	COMMAND_LINE="${COMMAND} ${OPT} -o${EXECUTABLE} ${SOURCE}"
  	# TODO For debugging
  	echo $COMMAND_LINE
    echo "Creating ${NAME} for ${OS} on ${ARCHITECTURE} as ${EXECUTABLE} from ${SOURCE}."
    if command ${COMMAND_LINE} &>${LOG}; then
      if [ -f "${SOURCE}.version" ]; then
        cp "${SOURCE}.version" "${EXECUTABLE}.version"
      fi
    else
      cat "$LOG"
    fi
    rm -f "*.o"
  else
    echo "Creation of ${NAME} for ${OS} on ${ARCHITECTURE} as ${EXECUTABLE} skipped. Command ${COMMAND} is not available."
  fi
}

#------------------------------------------------------------------------
# Compile Pascal source file with Free Pascal Compiler
#------------------------------------------------------------------------
function compileWithFPC(){

    local NAME=$1
    local SOURCE=$2
    local TARGET=$3
    local OS=$4
    local ARCHITECTURE=$5
    local EXECUTABLE
    EXECUTABLE=$(getExecutableName "$TARGET" "$OS" "$ARCHITECTURE")
    local LOG="$EXECUTABLE.log"

    OPT="-Mdelphi -O3"
  
    case $OS in

        "$OS_LINUX")
        COMMAND="none";
        ;;
        "$OS_MACOS")
        OPT="$OPT -XR$XCODE_COMMANDLINE_TOOLS_LIBS"
        if [ "$ARCHTECTURE" == "$ARCHITECTURE_I386" ]; then
        	COMMAND="ppcx64"
        else
        	COMMAND="ppcjvm"
        fi
        ;;
        "$OS_WINDOWS")
        COMMAND="FPC.exe";
        ;;
        *)
        echo "ERROR: Unknown OS '$OS' in compileWithFPC()."
        exit 1
        ;;
    esac

  compileWithCommand "${COMMAND}"
}

#------------------------------------------------------------------------
# Compile C source file with standard CC compiler
#------------------------------------------------------------------------
function compileWithCC(){
  local NAME=$1
  local SOURCE=$2
  local TARGET=$3

  local EXECUTABLE
  EXECUTABLE=$(getExecutableName "$TARGET" "$OS" "$ARCHITECTURE")
  local LOG="$EXECUTABLE.log"

  
  local OPT
  OPT=$(getCCARCH)
  if [ -z "${OPT}" ]; then
  	return
  fi

  printCompileLanguageAndToolAndOSAndArchitecture
  compileWithCommand "cc"
}

#------------------------------------------------------------------------
# Get ARCH parameter for standard CC compiler.
#------------------------------------------------------------------------
function getCCARCH(){
# Compile only if host OS matches.
  if [ "${OS}" != "${OS_TYPE}" ]; then
  	return
  fi

case ${ARCHITECTURE} in
  ${ARCHITECTURE_A64})
    echo "-arch arm64"
    ;;
  ${ARCHITECTURE_I32})
  	# No longer supported on macOS
  	if [ "${OS}" == "${OS_MACOS}" ]; then
  	  return
    fi
    echo "-arch i386"
    ;;
  ${ARCHITECTURE_I64})
    echo "-arch x86_64"
    ;;
  ${ARCHITECTURE_PPC})
  	# No longer supported on macOS
   	if [ "${OS}" == "${OS_MACOS}" ]; then
  	  return
    fi
    echo"-arch ppc"
    ;;
  esac
}

#------------------------------------------------------------------------
# Function iterator for all OSes and architectures.
#------------------------------------------------------------------------
function getExecutableName(){
  local TARGET=$1
  local OS=$2
  local ARCHITECTURE=$3
  echo "$TARGET$(getFileExtension "$OS" "$ARCHITECTURE")"
}

#------------------------------------------------------------------------
# Function iterator for all OSes and architectures.
#------------------------------------------------------------------------
function forAllOSesAndArchitectures(){
  local FUNCTION=$1
  local OS_LIST
  OS_LIST=$(getOSList)
  for OS in $OS_LIST
  do
    OS_NAME=$(getOSName "$OS")
    local ARCHITECTURE_LIST
    ARCHITECTURE_LIST=$(getArchitectureList)
      for ARCHITECTURE in $ARCHITECTURE_LIST
      do
        FILE_EXTENSION=$(getFileExtension "$OS" "$ARCHITECTURE")
        if [ -n "$FILE_EXTENSION" ]; then
          $FUNCTION
#       else
#         echo "INFO: Architecture $ARCHITECTURE is not supported on $OS_NAME".
        fi
      done
  done
}

#------------------------------------------------------------------------
# Function iterator for all languages, tools, OSes and architectures.
#------------------------------------------------------------------------

function forAllLanguagesAndToolsAndOSesAndArchitectures(){
  LANGUAGE_LIST=$(getLanguageList)
  for LANGUAGE in $LANGUAGE_LIST
  do
    LANGUAGE_NAME=$(getLanguageName "$LANGUAGE")
    TOOLS=$(getLanguageTools "$LANGUAGE")
    for TOOL in $TOOLS
      do
        echo "Processing Language $LANGUAGE_NAME, Tool $TOOL"
        TARGET=$(echo "$TOOL" | tr '[:upper:]' '[:lower:]')
        PATH_PREFIX="$LANGUAGE/$TOOL"
        forAllOSesAndArchitectures $1
      done
  done
}

function testFunctionLanguageAndToolAndOSAndArchitecture(){
  echo "INFO: Language ${LANGUAGE}, Tool ${TOOL}, Architecture ${ARCHITECTURE} on ${OS_NAME} has file extension '${FILE_EXTENSION}'."
}

function printCompileLanguageAndToolAndOSAndArchitecture(){
   echo "Compiling: Language ${LANGUAGE}, Tool ${TOOL}, Architecture ${ARCHITECTURE} on ${OS_NAME} with file extension '${FILE_EXTENSION}'."
}

function compileLanguageAndToolAndOSAndArchitecture(){
  local FUNCTION_NAME
  FUNCTION_NAME="compile_${LANGUAGE}_${TOOL}"
  if type "${FUNCTION_NAME}" 2>/dev/null | grep -q "function"
  then
    pushd "${LANGUAGE}/${TOOL}" >/dev/null
    ${FUNCTION_NAME}
    popd >/dev/null
  fi
}


#------------------------------------------------------------------------
# Tool-specific compile functions.
#------------------------------------------------------------------------

function compile_ASM_ASM6() {
  compileWithCC ${TOOL} asm6.c asm6
}

function compile_ASM_ATASM() {
  local ARCH
  ARCH=$(getCCARCH)
  if [ -z "${ARCH}" ]; then
  	return
  fi
  export ARCH

  printCompileLanguageAndToolAndOSAndArchitecture
  cd src
  make clean
 
  make  
  chmod a+x atasm
  mv atasm ../atasm${FILE_EXTENSION}
  make clean

  cd ..
}


function compile_ASM_MADS(){
  printCompileLanguageAndToolAndOSAndArchitecture
  compileWithFPC ${TOOL} mads.pas mads $OS $ARCHITECTURE
}

function compile_PAS_MP(){
  printCompileLanguageAndToolAndOSAndArchitecture
  compileWithFPC ${TOOL} mp.pas mp $OS $ARCHITECTURE
}


#------------------------------------------------------------------------
# Display File Details.
#------------------------------------------------------------------------
function encodeHTML(){
  local str=$1
  for (( i=0; i<${#str}; i++ )); do
    local c
    c=${str:$i:1}
    printf "&#%d;" "'$c" #
  done
  echo ""
}

#------------------------------------------------------------------------
# Display files in ${PATH_PREFIX} that have file extension 
# ${FILE_EXTENSION} abd their details as HTML table rows.
#------------------------------------------------------------------------
function displayFiles() {
  local FILTER
  local FILE_FOUND
  local FILES
  FILTER=*${FILE_EXTENSION}
  FILE_FOUND="false"
  FILES=$(find ${PATH_PREFIX} -name ${FILTER})
  for FILE in $FILES
  do
    if [ -f "$FILE" ]; then
     FILE_FOUND="true"
     FILE_NAME="$FILE"
     FILE_DATE=$(date -r "$FILE" "+%Y-%m-%d %H:%M:%S")
     FILE_INFO=$(file -b "$FILE")
     TOOL_VERSION=""
     if [ -f "${FILE}.version" ]; then
       TOOL_VERSION=$(cat "${FILE}.version")
     fi
     echo "<tr><td>$LANGUAGE_NAME</td><td>$TOOL</td><td>$TOOL_VERSION</td><td>$OS_NAME</td><td>$ARCHITECTURE</td><td title=\"$(encodeHTML "$FILE_INFO")\">$FILE_NAME</td><td>$FILE_DATE</th><tr>">>"$README_MD"
    fi
  done
  if [[ "$FILE_FOUND" == "false" ]] && [[ "$VERBOSE" == "-v" ]]; then
     echo "- No file found for filter ${FILTER}."
  fi
}

#------------------------------------------------------------------------
# Generate readme file as Readme.md with all included tools.
#------------------------------------------------------------------------
function generateREADME(){
    README_MD="README.md"
    echo "Generating ${README_MD}"
    echo "This project contains the contents for the \"Tools\" folder of the WUDSN IDE installation. This includes all supported assemblers, compilers and emulators.">$README_MD
    echo "<table>">>$README_MD
    echo "<tr><th>Language</th><th>Tool</th><th>Version</th><th>OS</th><th>Architecture</th><th>File Name</th><th>File Date</th></tr>">>$README_MD
    forAllLanguagesAndToolsAndOSesAndArchitectures displayFiles
    echo "</table>">>$README_MD
    echo "The paths defined in this repository are the defaults inside WUDSN IDE. They have to be maintained in class \"com.wudsn.ide.lng.compiler.CompilerPaths\".">>$README_MD

#   Create local "Readme.html" for quick check of the content.
    local README_HTML="README.html"
    echo "<!DOCTYPE html><html><head><title>WUDSN IDE Tools</title><style>table { border-collapse: collapse; } th, td { border: 1px solid black; }</style></head><body>">$README_HTML
    cat $README_MD >>$README_HTML
    echo "</body></html>">>$README_HTML
    open $README_HTML
}

#-------------------------------------------------------------------------
# Main function to compile all tools.
#-------------------------------------------------------------------------
function main(){
# VERBOSE=-v
	
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

  # Map OS type and host type to own codes.
  OS_TYPE="unknown"
  
  case "${OSTYPE}" in
    linux-gnu)
      OS_TYPE=${OS_LINUX}
      ;;
    darwin*) 
      OS_TYPE=${OS_MACOS}
      installXCodeCommandlineTools
      ;;
    *)
      echo "ERROR: Unknown OS type ${OSTYPE}."
      return 
  esac
 
  # The following line is only for testing the script functions.
  #forAllLanguagesAndToolsAndOSesAndArchitectures testFunctionLanguageAndToolAndOSAndArchitecture

  forAllLanguagesAndToolsAndOSesAndArchitectures compileLanguageAndToolAndOSAndArchitecture

  pushd ASM >/dev/null
  echo source "$VERBOSE" make-"$OS".sh
  popd >/dev/null

  generateREADME
}

main
