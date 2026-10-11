@echo off
setlocal EnableExtensions DisableDelayedExpansion

REM ===========================================================================
REM  BuildDUFUtilities.bat - builds DUF's utility programs for the workspace of
REM  an application that uses DUF.
REM
REM  The programs are compiled with that workspace's login key
REM  (AppSrc\LoginEncryptionKey.inc) and with the DataFlex version its workspace
REM  file names, and they land in its Programs folder. A program built that way
REM  reads the application's SQLConnections.ini, also at a customer's.
REM
REM  DataFlex 26 and later, DUF as a package: the package puts this file into
REM  the workspace folder. Start it there.
REM      BuildDUFUtilities.bat
REM
REM  DataFlex 19.1 to 25, DUF as a library folder: start it from the folder of
REM  the application's workspace, or hand it the workspace file.
REM      ..\Libraries\DUF\BuildDUFUtilities.bat
REM      BuildDUFUtilities.bat C:\Projects\MyApp\MyApp.sws
REM
REM      /all       also DUFSQLConnections and ReadDFDriverDefXML
REM                 (without it: DUFCodeGenerator and DUFSQLRepairUtility)
REM      /32        32-bit programs, DataFlex 20 to 25 (19.1 is always 32-bit)
REM      /nopause   do not wait for a key at the end
REM
REM  It needs Windows and DataFlex, nothing else. The compiler is looked for in
REM  the DataFlex folder the registry names (df-cli also on the PATH). To point
REM  at it yourself, set the variable DFCLI (DataFlex 26 and later) or
REM  DFCOMPILER (19.1 to 25) to its full path before starting this script.
REM
REM  It writes to two places only: the folder DUFUtilitiesBuild in the
REM  workspace (copies of the sources it compiles, and the compiler's
REM  listings) and the Programs folder. The DUF folder is only read.
REM  DUFUtilitiesBuild can be deleted at any time.
REM ===========================================================================

REM The folder this script stands in, taken before the arguments are shifted.
set "HERE=%~dp0"
set "START=%CD%"
set "RC=0"
set "NOPAUSE="
set "ALL="
set "WANT32="
set "SWSARG="
set "BUILT="
set "FAILED="
set "KEYCOPY="

:Args
if "%~1"=="" goto ArgsDone
if /i "%~1"=="/?" goto Usage
if /i "%~1"=="/all" goto ArgAll
if /i "%~1"=="/32" goto Arg32
if /i "%~1"=="/nopause" goto ArgNoPause
if defined SWSARG goto Usage
set "SWSARG=%~f1"
shift /1
goto Args
:ArgAll
set "ALL=1"
shift /1
goto Args
:Arg32
set "WANT32=1"
shift /1
goto Args
:ArgNoPause
set "NOPAUSE=1"
shift /1
goto Args
:ArgsDone

echo.
echo === DUF utilities: build for an application's workspace ===

REM --- the workspace file ---------------------------------------------------
REM Handed in, or the one in this script's folder that uses DUF, or the one in
REM the folder this script was started from.
set "WS=%HERE%"
if "%WS:~-1%"=="\" set "WS=%WS:~0,-1%"
if not defined SWSARG goto FindSws
if not exist "%SWSARG%" goto NoSuchSws
set "SWS=%SWSARG%"
goto HaveSws

:FindSws
set "SWS="
set "COUNT=0"
call :ScanFolder "%WS%"
if not "%COUNT%"=="0" goto FoundSws
if /i "%START%"=="%WS%" goto NoDufSws
set "WS=%START%"
call :ScanFolder "%WS%"
if "%COUNT%"=="0" goto NoDufSws
:FoundSws
if not "%COUNT%"=="1" goto ManySws

:HaveSws
for %%F in ("%SWS%") do set "WS=%%~dpF"
if "%WS:~-1%"=="\" set "WS=%WS:~0,-1%"
echo Workspace file: "%SWS%"

REM --- its DataFlex version, and the kind of workspace file -----------------
REM "df": 26.0 in a workspace file of DataFlex 26 and later (DUF as a package);
REM Version=25.0 in one of DataFlex 19.1 to 25 (DUF as a library folder).
set "KIND="
set "DFVER="
for /f "tokens=2 delims=:," %%V in ('findstr /r /c:"\"df\" *:" "%SWS%"') do if not defined DFVER set "DFVER=%%V"
if defined DFVER set "KIND=PACKAGE"
if not defined DFVER for /f "tokens=2 delims==" %%V in ('findstr /b /i /c:"Version=" "%SWS%"') do if not defined DFVER set "DFVER=%%V"
if defined DFVER set "DFVER=%DFVER: =%"
if not defined DFVER goto NoDfVer
if not defined KIND set "KIND=LIBRARY"

set "BUILD=%WS%\DUFUtilitiesBuild"
if not exist "%BUILD%\" mkdir "%BUILD%"
if not exist "%BUILD%\" goto NoBuildDir
set "OUT=%WS%\Programs"
if not exist "%OUT%\" set "OUT=%WS%"
set "PROGRAMS=DUFCodeGenerator DUFSQLRepairUtility"
if defined ALL set "PROGRAMS=%PROGRAMS% DUFSQLConnections ReadDFDriverDefXML"

if "%KIND%"=="LIBRARY" goto Library

REM ===========================================================================
REM  DataFlex 26 and later: DUF is a package in DfPkg, df-cli compiles.
REM ===========================================================================
set "SUFFIX=64"
set "ARCH=amd64"
if defined WANT32 echo /32 is for DataFlex 20 to 25. This workspace gets 64-bit programs.

REM --- df-cli: the variable DFCLI, the PATH, the registry ---------------------
if not defined DFCLI goto CliOnPath
if exist "%DFCLI%" goto HaveCli
echo The variable DFCLI names a file that is not there: "%DFCLI%"
set "DFCLI="
:CliOnPath
for /f "delims=" %%P in ('where df-cli.exe 2^>nul') do if not defined DFCLI set "DFCLI=%%P"
if defined DFCLI goto HaveCli
call :RootFromKey "HKLM\SOFTWARE\Data Access Worldwide\DataFlex\%DFVER%"
if defined ROOT if exist "%ROOT%\Bin64\df-cli.exe" set "DFCLI=%ROOT%\Bin64\df-cli.exe"
if defined DFCLI goto HaveCli
REM any installed DataFlex that has df-cli; the last one listed is the highest
for /f "tokens=*" %%K in ('reg query "HKLM\SOFTWARE\Data Access Worldwide\DataFlex" /reg:64 2^>nul ^| findstr /r /c:"DataFlex\\[0-9]"') do call :CliFromKey "%%K"
if not defined DFCLI goto NoCli
:HaveCli
echo df-cli:         "%DFCLI%"

REM --- the DUF package folder --------------------------------------------------
set "DUFDIR="
set "COUNT=0"
for /d %%D in ("%WS%\DfPkg\*RDC_DUF_Library-*") do call :CountDuf "%%D"
if "%COUNT%"=="0" goto NoDuf
if "%COUNT%"=="1" goto HaveDuf
REM several versions are in DfPkg: the lock file says which one is in use
call :DufFromLock
if not defined DUFDIR goto ManyDuf
:HaveDuf
if not exist "%DUFDIR%\AppSrc\DUFCodeGenerator.src" goto NoDufSources
echo DUF package:    "%DUFDIR%"

REM --- the 64-bit compiler of that DataFlex version ----------------------------
REM df-cli builds 32-bit unless it is told which one to use.
set "TOOLCHAIN="
"%DFCLI%" toolchain list > "%BUILD%\toolchains.txt" 2>nul
for /f "tokens=1 delims=:" %%T in ('findstr /b /c:"%DFVER%." "%BUILD%\toolchains.txt" ^| findstr /c:"+windows-64"') do if not defined TOOLCHAIN set "TOOLCHAIN=%%T"
if not defined TOOLCHAIN goto NoToolchain
echo Compiler:       %TOOLCHAIN%

if not exist "%WS%\AppSrc\LoginEncryptionKey.inc" echo.
if not exist "%WS%\AppSrc\LoginEncryptionKey.inc" echo Note: AppSrc\LoginEncryptionKey.inc is not in this workspace. The utilities
if not exist "%WS%\AppSrc\LoginEncryptionKey.inc" echo are compiled with that file. Without it the compile stops.
goto BuildAll

REM ===========================================================================
REM  DataFlex 19.1 to 25: DUF is a library folder, that version's own compiler
REM  compiles. A utility needs DUF's own folders to compile (its table
REM  definition, its bitmaps and help), so it is compiled with a workspace file
REM  written into the build folder: DUF's folders, with two things from the
REM  application - a copy of its login key file, first on the source path, and
REM  its Programs folder.
REM ===========================================================================
:Library
if not exist "%WS%\AppSrc\LoginEncryptionKey.inc" goto NoKeyFile

REM --- the DUF folder: the library the workspace file names, or this folder ----
set "DUFLIB="
set "DUFDIR="
for /f "tokens=1,* delims==" %%A in ('findstr /b /i /r /c:"Lib[0-9]*=.*DUFLibrary" "%SWS%"') do if not defined DUFLIB set "DUFLIB=%%B"
if defined DUFLIB call :FolderOf "%DUFLIB%"
if defined DUFLIB set "DUFDIR=%FOUND%"
if not defined DUFDIR if exist "%HERE%AppSrc\DUFSQLRepairUtility.src" set "DUFDIR=%HERE:~0,-1%"
if not defined DUFDIR goto NoDufLibrary
if not exist "%DUFDIR%\AppSrc\DUFSQLRepairUtility.src" goto NoDufSources
echo DUF folder:     "%DUFDIR%"

REM --- the compiler of that DataFlex version ------------------------------------
set "BITS=64"
if defined WANT32 set "BITS=32"
if "%DFVER:~0,1%"=="1" set "BITS=32"
set "SUFFIX=64"
set "ARCH=amd64"
if "%BITS%"=="32" set "SUFFIX="
if "%BITS%"=="32" set "ARCH=X86"
set "WIN64=True"
if "%BITS%"=="32" set "WIN64=False"
set "BIN=Bin64"
if "%BITS%"=="32" set "BIN=Bin"
set "COMPILER="
set "OLDCOMP="
if not defined DFCOMPILER goto CompilerFromRegistry
if exist "%DFCOMPILER%" set "COMPILER=%DFCOMPILER%"
if not defined COMPILER echo The variable DFCOMPILER names a file that is not there: "%DFCOMPILER%"
:CompilerFromRegistry
if defined COMPILER goto HaveCompiler
call :RootFromKey "HKLM\SOFTWARE\Data Access Worldwide\DataFlex\%DFVER%"
if not defined ROOT goto NoCompiler
if exist "%ROOT%\%BIN%\DFCompConsole.exe" set "COMPILER=%ROOT%\%BIN%\DFCompConsole.exe"
if not defined COMPILER if "%BITS%"=="32" if exist "%ROOT%\Bin\DFComp.exe" set "COMPILER=%ROOT%\Bin\DFComp.exe"
if not defined COMPILER goto NoCompiler
:HaveCompiler
REM DFComp.exe is the compiler before the console one; it runs without a window on -i0.
for %%F in ("%COMPILER%") do if /i "%%~nF"=="DFComp" set "OLDCOMP=1"
echo Compiler:       "%COMPILER%", %BITS%-bit

REM --- the build folder's own workspace file ------------------------------------
copy /y "%WS%\AppSrc\LoginEncryptionKey.inc" "%BUILD%\LoginEncryptionKey.inc" >nul
if errorlevel 1 goto NoBuildDir
set "KEYCOPY=%BUILD%\LoginEncryptionKey.inc"
> "%BUILD%\Build.sws" echo [Properties]
>>"%BUILD%\Build.sws" echo Version=%DFVER%
>>"%BUILD%\Build.sws" echo [WorkspacePaths]
>>"%BUILD%\Build.sws" echo ConfigFile=.\Config.ws
>>"%BUILD%\Build.sws" echo [Conditionals]
>>"%BUILD%\Build.sws" echo Is$WebApp=False
>>"%BUILD%\Build.sws" echo Is$Win64=%WIN64%
>>"%BUILD%\Build.sws" echo [Libraries]
set "LIBNO=0"
for /f "tokens=1,* delims==" %%A in ('findstr /b /i /r /c:"Lib[0-9]*=" "%SWS%"') do call :AddLibrary "%%B"
> "%BUILD%\Config.ws" echo [Workspace]
>>"%BUILD%\Config.ws" echo Home=%DUFDIR%\
>>"%BUILD%\Config.ws" echo AppSrcPath=%BUILD%;%DUFDIR%\AppSrc
>>"%BUILD%\Config.ws" echo AppHTMLPath=%DUFDIR%
>>"%BUILD%\Config.ws" echo BitmapPath=%DUFDIR%\Bitmaps
>>"%BUILD%\Config.ws" echo IdeSrcPath=%DUFDIR%\IdeSrc
>>"%BUILD%\Config.ws" echo DataPath=%DUFDIR%\Data
>>"%BUILD%\Config.ws" echo DDSrcPath=%DUFDIR%\DDSrc
>>"%BUILD%\Config.ws" echo HelpPath=%DUFDIR%\Help
>>"%BUILD%\Config.ws" echo ProgramPath=%OUT%
>>"%BUILD%\Config.ws" echo FileList=%DUFDIR%\Data\Filelist.cfg
>>"%BUILD%\Config.ws" echo Description=DUF utilities, built for %SWS%

REM DataFlex 19.1 builds two of the four: the code generator needs 20.1 or
REM later, and DUFSQLConnections an icon DataFlex has from version 20.
if not "%DFVER:~0,1%"=="1" goto BuildAll
set "PROGRAMS=DUFSQLRepairUtility"
if defined ALL set "PROGRAMS=DUFSQLRepairUtility ReadDFDriverDefXML"
echo.
echo Note: on DataFlex %DFVER% DUFCodeGenerator and DUFSQLConnections cannot be
echo built. They need DataFlex 20.1 or later.

REM ===========================================================================
REM  Build, both kinds
REM ===========================================================================
:BuildAll
pushd "%WS%"
for %%P in (%PROGRAMS%) do call :BuildOne %%P
popd
if defined KEYCOPY del "%KEYCOPY%" >nul 2>nul

echo.
echo ----------------------------------------------------------------------
if defined BUILT echo Built:    %BUILT%
if defined FAILED echo NOT built:%FAILED%
if defined BUILT echo The programs are in "%OUT%".
if not defined FAILED echo Start DUFCodeGenerator or DUFSQLRepairUtility and click "Add To Studio"
if not defined FAILED echo to put it on the Studio's Tools menu.
goto End

REM ===========================================================================
REM  One program: copies of its source and its project settings go to the build
REM  folder, a manifest is written beside them, and the compiler works on the
REM  copy.
REM ===========================================================================
:BuildOne
set "P=%~1"
echo.
echo Building %P% ...
if not exist "%DUFDIR%\AppSrc\%P%.src" goto BuildNoSource
if exist "%BUILD%\%P%.src" attrib -R "%BUILD%\%P%.src" >nul 2>nul
if exist "%BUILD%\%P%.cfg" attrib -R "%BUILD%\%P%.cfg" >nul 2>nul
copy /y "%DUFDIR%\AppSrc\%P%.src" "%BUILD%\%P%.src" >nul
if errorlevel 1 goto BuildNoCopy
copy /y "%DUFDIR%\AppSrc\%P%.cfg" "%BUILD%\%P%.cfg" >nul
if errorlevel 1 goto BuildNoCopy
attrib -R "%BUILD%\%P%.src" >nul 2>nul
attrib -R "%BUILD%\%P%.cfg" >nul 2>nul
call :WriteManifest
if "%KIND%"=="LIBRARY" goto BuildWithOwnCompiler

"%DFCLI%" build-file "%BUILD%\%P%.src" --workspace "%SWS%" --output-dir "%OUT%" --cfg "%BUILD%\%P%.cfg" --toolchain %TOOLCHAIN% --rebuild --write-errors > "%BUILD%\%P%.log" 2>&1
if errorlevel 1 goto BuildFailed
goto BuildCheck

:BuildWithOwnCompiler
REM The compiler's error file of an earlier run must not be taken for this one.
if exist "%BUILD%\%P%.err" del "%BUILD%\%P%.err" >nul 2>nul
if exist "%BUILD%\%P%.x64.err" del "%BUILD%\%P%.x64.err" >nul 2>nul
if defined OLDCOMP goto BuildWithOldCompiler
"%COMPILER%" "%BUILD%\%P%.src" -x "%BUILD%\Build.sws" -c > "%BUILD%\%P%.log" 2>&1
if errorlevel 1 goto BuildFailed
goto BuildCheck

:BuildWithOldCompiler
REM -i0: no window. Its exit code says nothing; an error file does.
"%COMPILER%" "%BUILD%\%P%.src" "-x%BUILD%\Build.sws" -i0w > "%BUILD%\%P%.log" 2>&1
if not exist "%BUILD%\%P%.err" goto BuildCheck
copy /y "%BUILD%\%P%.err" "%BUILD%\%P%.log" >nul
goto BuildFailed

:BuildCheck
if not exist "%OUT%\%P%%SUFFIX%.exe" goto BuildFailed
echo   built: "%OUT%\%P%%SUFFIX%.exe"
set "BUILT=%BUILT% %P%"
goto :eof

:BuildNoSource
echo   NOT built: DUF has no "%P%.src".
goto BuildMarkFailed
:BuildNoCopy
echo   NOT built: could not copy the source to "%BUILD%".
goto BuildMarkFailed
:BuildFailed
echo   NOT built. What the compiler said:
findstr /c:"ERROR: " /c:") Error " "%BUILD%\%P%.log"
echo   All of it is in "%BUILD%\%P%.log".
:BuildMarkFailed
set "RC=1"
set "FAILED=%FAILED% %P%"
goto :eof

REM ===========================================================================
REM  The manifest the Studio writes for a program: the current Windows
REM  controls, no request for administrator rights, aware of the screen scaling.
REM  The project settings ask for it, and the command-line compilers do not
REM  write one.
REM ===========================================================================
:WriteManifest
set "MF=%BUILD%\%P%%SUFFIX%.exe.manifest"
> "%MF%" echo ^<?xml version="1.0"?^>
>>"%MF%" echo ^<assembly manifestVersion="1.0" xmlns="urn:schemas-microsoft-com:asm.v1"^>
>>"%MF%" echo   ^<assemblyIdentity version="1.0.0.0" processorArchitecture="%ARCH%" name="DAW.DataFlex.%P%.src" type="win32"^>^</assemblyIdentity^>
>>"%MF%" echo   ^<description^>%P%.src^</description^>
>>"%MF%" echo   ^<dependency^>
>>"%MF%" echo     ^<dependentAssembly^>
>>"%MF%" echo       ^<assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls" version="6.0.0.0" processorArchitecture="%ARCH%" publicKeyToken="6595b64144ccf1df" language="*"^>^</assemblyIdentity^>
>>"%MF%" echo     ^</dependentAssembly^>
>>"%MF%" echo   ^</dependency^>
>>"%MF%" echo   ^<v3:trustInfo xmlns:v3="urn:schemas-microsoft-com:asm.v3"^>
>>"%MF%" echo     ^<v3:security^>
>>"%MF%" echo       ^<v3:requestedPrivileges^>
>>"%MF%" echo         ^<v3:requestedExecutionLevel level="asInvoker"^>^</v3:requestedExecutionLevel^>
>>"%MF%" echo       ^</v3:requestedPrivileges^>
>>"%MF%" echo     ^</v3:security^>
>>"%MF%" echo   ^</v3:trustInfo^>
>>"%MF%" echo   ^<v3:application xmlns:v3="urn:schemas-microsoft-com:asm.v3"^>
>>"%MF%" echo     ^<v3:windowsSettings xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings"^>
>>"%MF%" echo       ^<dpiAware^>True^</dpiAware^>
>>"%MF%" echo     ^</v3:windowsSettings^>
>>"%MF%" echo   ^</v3:application^>
>>"%MF%" echo ^</assembly^>
goto :eof

REM ===========================================================================
REM  Helpers
REM ===========================================================================

REM The workspace files of one folder that use DUF: as a package, or as a library.
:ScanFolder
for /f "delims=" %%F in ('findstr /m /i /c:"Library-DUF" "%~1\*.sws" 2^>nul') do call :CountSws "%%F"
for /f "delims=" %%F in ('findstr /m /i /r /c:"^Lib[0-9]*=.*DUFLibrary" "%~1\*.sws" 2^>nul') do call :CountSws "%%F"
goto :eof

:CountSws
set /a COUNT+=1
set "SWS=%~1"
goto :eof

:CountDuf
set /a COUNT+=1
set "DUFDIR=%~1"
goto :eof

REM The folder of a file named in the workspace file, in FOUND: the name may be
REM a full path or stand relative to the workspace folder.
:FolderOf
set "FOUND="
set "NAME=%~1"
if "%NAME:~1,1%"==":" goto FolderOfFull
if "%NAME:~0,2%"=="\\" goto FolderOfFull
set "NAME=%WS%\%NAME%"
:FolderOfFull
for %%F in ("%NAME%") do set "FOUND=%%~dpF"
if defined FOUND if "%FOUND:~-1%"=="\" set "FOUND=%FOUND:~0,-1%"
goto :eof

REM One library of the application's workspace file goes into the build
REM folder's own, with its full path. DUF itself is left out: it is the home there.
:AddLibrary
set "NAME=%~1"
if /i "%NAME%"=="%DUFLIB%" goto :eof
if "%NAME:~1,1%"==":" goto AddLibraryFull
if "%NAME:~0,2%"=="\\" goto AddLibraryFull
set "NAME=%WS%\%NAME%"
:AddLibraryFull
for %%F in ("%NAME%") do set "NAME=%%~fF"
set /a LIBNO+=1
>>"%BUILD%\Build.sws" echo Lib%LIBNO%=%NAME%
goto :eof

REM The install folder of the DataFlex whose registry key is handed in, in ROOT.
REM DataFlex 20 and later stand in the 64-bit registry, 19.1 in the 32-bit one.
:RootFromKey
set "ROOT="
for /f "tokens=2,*" %%A in ('reg query "%~1\Defaults" /v VDFRootDir /reg:64 2^>nul ^| findstr /i /c:"VDFRootDir"') do set "ROOT=%%B"
if not defined ROOT for /f "tokens=2,*" %%A in ('reg query "%~1\Defaults" /v VDFRootDir /reg:32 2^>nul ^| findstr /i /c:"VDFRootDir"') do set "ROOT=%%B"
if not defined ROOT goto :eof
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
goto :eof

REM df-cli.exe of the DataFlex whose registry key is handed in
:CliFromKey
call :RootFromKey "%~1"
if not defined ROOT goto :eof
if exist "%ROOT%\Bin64\df-cli.exe" set "DFCLI=%ROOT%\Bin64\df-cli.exe"
goto :eof

REM The version of the DUF package the workspace's lock file names
:DufFromLock
set "DUFDIR="
if not exist "%SWS%.lock" goto :eof
set "N="
for /f "delims=:" %%N in ('findstr /n /i /c:"Library-DUF.git/RDC-DUF-Library" "%SWS%.lock"') do if not defined N set "N=%%N"
if not defined N goto :eof
set "REF="
for /f "usebackq skip=%N% tokens=2 delims=:, " %%R in ("%SWS%.lock") do if not defined REF set "REF=%%~R"
if not defined REF goto :eof
for /d %%D in ("%WS%\DfPkg\*RDC_DUF_Library-%REF%") do set "DUFDIR=%%D"
goto :eof

REM ===========================================================================
REM  Why it could not start
REM ===========================================================================
:Usage
echo.
echo BuildDUFUtilities.bat [workspace file] [/all] [/32] [/nopause]
echo.
echo   Builds DUFCodeGenerator and DUFSQLRepairUtility for the workspace of an
echo   application that uses DUF, into that workspace's Programs folder.
echo   /all      also DUFSQLConnections and ReadDFDriverDefXML
echo   /32       32-bit programs, DataFlex 20 to 25
echo   /nopause  do not wait for a key at the end
set "RC=1"
goto End

:NoSuchSws
echo.
echo There is no such workspace file: "%SWSARG%"
set "RC=1"
goto End

:NoDufSws
echo.
echo No workspace file that uses DUF was found, neither in "%HERE%"
echo nor in "%START%".
echo Start this script from the folder of the application's workspace, or hand
echo it the workspace file: BuildDUFUtilities.bat C:\Projects\MyApp\MyApp.sws
set "RC=1"
goto End

:ManySws
echo.
echo Several workspace files in "%WS%" use DUF:
findstr /m /i /c:"Library-DUF" "%WS%\*.sws" 2>nul
findstr /m /i /r /c:"^Lib[0-9]*=.*DUFLibrary" "%WS%\*.sws" 2>nul
echo Name the one to build for: BuildDUFUtilities.bat MyApp.sws
set "RC=1"
goto End

:NoDfVer
echo.
echo The workspace file does not name a DataFlex version.
set "RC=1"
goto End

:NoKeyFile
echo.
echo "%WS%\AppSrc\LoginEncryptionKey.inc" is not there.
echo The utilities are compiled with the login key of the application's
echo workspace. The Studio makes that file for a workspace. Without it this
echo script stops: a DUF folder may hold a key file of its own, and a
echo program built with that one cannot read the application's passwords.
set "RC=1"
goto End

:NoDufLibrary
echo.
echo The workspace file does not name DUF as a library (a line like
echo Lib1=..\Libraries\DUF\DUFLibrary%DFVER%.sws), and this script does not
echo stand in a DUF folder.
set "RC=1"
goto End

:NoCompiler
echo.
echo The compiler of DataFlex %DFVER% was not found: the registry names no
echo folder for that version, or the folder has no %BIN%\DFCompConsole.exe.
echo Set the variable DFCOMPILER to its full path and start this script again:
echo     set "DFCOMPILER=C:\Program Files\DataFlex %DFVER%\%BIN%\DFCompConsole.exe"
set "RC=1"
goto End

:NoCli
echo.
echo df-cli.exe was not found: not on the PATH, and not in a DataFlex folder
echo named in the registry. It is in the Bin64 folder of DataFlex. Set the
echo variable DFCLI to its full path and start this script again:
echo     set "DFCLI=C:\Program Files\DataFlex 26.0\Bin64\df-cli.exe"
set "RC=1"
goto End

:NoDuf
echo.
echo The DUF package is not in "%WS%\DfPkg".
echo Open the workspace in the Studio once, or run df-cli config on its
echo workspace file, so the packages are fetched.
set "RC=1"
goto End

:ManyDuf
echo.
echo Several versions of the DUF package are in "%WS%\DfPkg",
echo and the lock file beside the workspace file does not say which is in use:
for /d %%D in ("%WS%\DfPkg\*RDC_DUF_Library-*") do echo     %%~nxD
set "RC=1"
goto End

:NoDufSources
echo.
echo The DUF folder has no utility sources: "%DUFDIR%\AppSrc"
set "RC=1"
goto End

:NoBuildDir
echo.
echo Could not write to the folder "%BUILD%".
set "RC=1"
goto End

:NoToolchain
echo.
echo df-cli knows no 64-bit compiler for DataFlex %DFVER%. It knows these:
type "%BUILD%\toolchains.txt"
set "RC=1"
goto End

:End
echo.
if not defined NOPAUSE pause
exit /b %RC%
