#!/bin/bash

export OS="Mac OS X"
export EXT="macosx"
export EXT32="$EXT-i386"
export EXTPPC="$EXT-powerpc"

echo Creating $OS binaries.

#-------------------------------------------------------------------------
# Create ATASM.
#-------------------------------------------------------------------------

cd ATASM/src

echo Creating ATASM - $OS 32-bit version
export ARCH="-arch i386"
make
chmod a+x atasm
mv atasm ../atasm.$EXT32
make clean

echo Creating ATASM - $OS PPC version
export ARCH="-arch ppc"
make
chmod a+x atasm
mv atasm ../atasm.$EXTPPC
make clean

cd ../..

#------------------------------------------------------------------------
# Create DASM.
#------------------------------------------------------------------------

cd DASM

mkdir bin
cd src
echo Creating DASM - $OS 32-bit version
export CC="gcc -arch i386"
make
mv dasm   ../bin/dasm.$EXT32
mv ftohex ../bin/ftohex.$EXT32
make clean

echo Creating DASM - $OS PPC version
export CC="gcc -arch ppc"
make
mv dasm   ../bin/dasm.$EXTPPC
mv ftohex ../bin/ftohex.$EXTPPC
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

echo Creating MADS - $OS PPC version
ppcppc -Mdelphi -O3 -v -omads.$EXTPPC mads.pas
rm mads.o

cd ..

#------------------------------------------------------------------------
# List result. 
#------------------------------------------------------------------------
echo Done.
ls -al ATASM/*.$EXT32 ATASM/*.$EXTPPC
ls -al DASM/*.$EXT32  DASM/*.$EXTPPC
ls -al MADS/*.$EXT32  MADS/*.$EXTPPC


