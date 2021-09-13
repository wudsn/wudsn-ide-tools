#!/bin/bash

export OS="Windows"
export EXT="linux"
export EXT32="exe"

echo Creating $OS binaries.

#-------------------------------------------------------------------------
# Create ATASM.
#-------------------------------------------------------------------------

cd ATASM/src

echo Creating ATASM - $OS 32-bit version
export ARCH=-m32
make
chmod a+x atasm
mv atasm ../atasm.$EXT32
make clean

cd ../..

#------------------------------------------------------------------------
# Create DASM.
#------------------------------------------------------------------------

cd DASM

mkdir bin
cd src
echo Creating DASM - $OS 32-bit version
export CC="gcc -m32"
make
mv dasm.exe   ../bin/dasm.$EXT32
mv ftohex.exe ../bin/ftohex.$EXT32
make clean
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
fpc -Mdelphi -v -O3 -omads.$EXT32 mads.pas
rm mads.o

cd ..

#------------------------------------------------------------------------
# List result. 
#------------------------------------------------------------------------
echo Done.
ls -al ATASM/*.$EXT32
ls -al DASM/bin/*.$EXT32
ls -al MADS/*.$EXT32
