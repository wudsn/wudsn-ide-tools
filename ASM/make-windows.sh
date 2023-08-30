#!/bin/bash

export OS="Windows"
export EXT="exe"

echo Creating $OS binaries.

#-------------------------------------------------------------------------
# Create ATASM.
#-------------------------------------------------------------------------

cd ATASM/src

echo Creating ATASM - $OS 64-bit version
export ARCH=-m64
make
chmod a+x atasm
mv atasm ../atasm.$EXT
make clean

cd ../..

#-------------------------------------------------------------------------
# Create ASM6.
#-------------------------------------------------------------------------

cd ASM6

echo Creating ASM6 - $OS 64-bit version
make

cd ..



#------------------------------------------------------------------------
# Create DASM.
#------------------------------------------------------------------------

cd DASM

mkdir bin
cd src
echo Creating DASM - $OS 32-bit version
export CC="gcc -m32"
make
mv dasm.exe   ../bin/dasm.$EXT
mv ftohex.exe ../bin/ftohex.$EXT

# Rename bin to exclude it from clean.
mv bin bin.bak
make clean
mv bin.bak bin
cd ..

cd test
make clean
cd ..

cd ..

#------------------------------------------------------------------------
# Create MADS.
#------------------------------------------------------------------------

cd MADS

echo Creating MADS - $OS 32-bit version
fpc -Mdelphi -v -O3 -omads.$EXT mads.pas
rm mads.o

cd ..

#-------------------------------------------------------------------------
# Create TASS.
#-------------------------------------------------------------------------

cd TASS/src

echo Creating TASS - $OS 64-bit version
make -f Makefile.win
mv 64tass.exe ../
make clean
cd ../..

#------------------------------------------------------------------------
# List result. 
#------------------------------------------------------------------------
echo Done.
ls -al ATASM/*.$EXT
ls -al ASM6/*.$EXT
ls -al DASM/bin/*.$EXT
ls -al MADS/*.$EXT
ls -al TASS/*.$EXT

