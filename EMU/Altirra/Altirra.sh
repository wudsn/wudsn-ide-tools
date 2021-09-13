#/!bin/bash

fullpath="${1//\"}"
lstfile=${fullpath%*.xex}.lst

sed "/mads /a\\
Source: $lstfile
" $lstfile > $lstfile.temp
mv $lstfile.temp $lstfile

FILE="${fullpath%*.}"
basename "$FILE"
f="$(basename -- $FILE)"

/usr/local/bin/wine64 ~/jac/wudsn/Tools/EMU/Altirra/Altirra64.exe $f