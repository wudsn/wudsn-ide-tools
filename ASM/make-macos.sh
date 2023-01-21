#!/bin/bash

#-------------------------------------------------------------------------
# Create ATASM.
#-------------------------------------------------------------------------
function makeATASM() {

cd ATASM/src

#echo Creating ATASM - $OS 32-bit version
#export ARCH="-arch i386"
#make
#chmod a+x atasm
#mv atasm ../atasm.$EXT32
#make clean

echo Creating ATASM - $OS 64-bit version
export ARCH="-arch x86_64"
make
chmod a+x atasm
mv atasm ../atasm.$EXT64
make clean

#echo Creating ATASM - $OS PPC version
#export ARCH="-arch ppc"
#make
#chmod a+x atasm
#mv atasm ../atasm.$EXTPPC
#make clean

cd ../..
}

#------------------------------------------------------------------------
# Create DASM.
#------------------------------------------------------------------------
function makeDASM() {

cd DASM

mkdir -p bin
cd src

#echo Creating DASM - $OS 32-bit version
#export CC="gcc -arch i386"
#make
#mv dasm   ../bin/dasm.$EXT32
#mv ftohex ../bin/ftohex.$EXT32
#make clean

export CC="clang -target x86_64-apple-darwin-macho"
make
mv dasm   ../bin/dasm.$EXT64
mv ftohex ../bin/ftohex.$EXT64
make clean

#echo Creating DASM - $OS PPC version
#export CC="gcc -arch ppc"
#make
#mv dasm   ../bin/dasm.$EXTPPC
#mv ftohex ../bin/ftohex.$EXTPPC
#make clean

cd ..

cd test
make clean
cd ..

cd ..

}

#------------------------------------------------------------------------
# Create MADS.
#------------------------------------------------------------------------
function fetchGitRepo($URL){

	rm -rf .git
	echo Getting latest MADS sources from github.
	git init -b master  --quiet
	git remote add origin $URL
	git fetch origin master --force  --quiet
	rm -rf .git

}

function makeMADS() { 


cd MADS

fetchMADS

}


#makeATASM
makeDASM
makeMADS

#------------------------------------------------------------------------
# List result. 
#------------------------------------------------------------------------
echo Done.
displayAssembler ATASM /
displayAssembler DASM  /bin/
displayAssembler MADS  /

