#!/bin/bash

export OS="Linux"
export EXT="linux"
export EXT32="$EXT-i386"
export EXT64="$EXT-x86-64"

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

echo Creating ATASM - $OS 64-bit version
export ARCH=-m64
make
chmod a+x atasm
mv atasm ../atasm.$EXT64
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
mv dasm   ../bin/dasm.$EXT32
mv ftohex ../bin/ftohex.$EXT32
make clean

echo Creating DASM - $OS 64-bit version
export CC="gcc -m64"
make
mv dasm   ../bin/dasm.$EXT64
mv ftohex ../bin/ftohex.$EXT64
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
ls -al ATASM/*.$EXT32 ATASM/*.$EXT64
ls -al DASM/*.$EXT32  DASM/*.$EXT64
ls -al MADS/*.$EXT32  MADS/*.$EXT64

