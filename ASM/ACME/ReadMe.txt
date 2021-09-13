

                                 ACME

         ...the ACME Crossassembler for Multiple Environments

                        --- Win32  version ---


This file only describes stuff that is specific to the Win32 version
of ACME. So if you are looking for more general things, you should
take a look at "docs\Help.txt".




***   Installing the executable:

There is no automated installation. If you don't like this, write an
installer program and mail it to me. :)

To install ACME, copy the file "acme.exe" to a directory that is
included in your system's PATH variable or store it inside a dedicated
"acme" directory and insert that directory's path into your PATH
variable. I recommend the second option, because that way you can keep
all of ACME's files together by just moving the whole archive into the
said directory.




***   Installing the library:

The directory "ACME_Lib" contains a bunch of files that may be useful.
Okay, there's hardly anything in it at the moment, but it will
hopefully grow over time.
You will have to set up an environment variable called "ACME" to allow
the main program to find this directory tree. For example, if you
store the library to C:\ACME\ACME_Lib, you will have to set the
environment variable "ACME" to "C:\ACME\ACME_Lib"
You don't *have* to install the library just to use ACME, but it
doesn't hurt to install it  - even the supplied example program uses
the library.




***   Miscellaneous:

All file names inside ACME sources must be given in UNIX style, so you
will have to exchange "\" and "/" characters.

The "acmeloop.bat" batch file may be useful if you don't want to enter
the same command line over and over again. When calling "acmeloop"
instead of "acme", you can keep assembling the same source code file
until it succeeds (of course you'll need to fix your sources between
iterations :))

Thanks to Wanja "Brix" Gayk for painting the "acme.ico" icon.

Thanks to Iris Lindner for doing this compile.

The Win32 version of ACME was compiled using Bloodshed Dev C++.




***   Changes:

Release 0.90:
 -Compiled without forcing to DOS version. The resulting binary claims
  to be the "Platform independent version / general UNIX version", but
  it really works under Windows (at least on the XP machine where it
  was compiled and tested). I couldn't be bothered to change the
  version string...

Release 0.86:
 -First Win32 version
