@echo off
setlocal EnableExtensions DisableDelayedExpansion

REM ===========================================================================
REM  BuildDUFUtilities.bat - builds DUF's utility programs in a workspace that
REM  uses DUF as a package (DataFlex 26 and later).
REM
REM  The DUF package brings the sources of its utilities, but no programs.
REM  This script compiles them in the workspace it stands in: with that
REM  workspace's login key (AppSrc\LoginEncryptionKey.inc) and with the
REM  DataFlex version the workspace file names. The programs land in the
REM  workspace's Programs folder.
REM
REM      BuildDUFUtilities.bat              DUFCodeGenerator, DUFSQLRepairUtility
REM      BuildDUFUtilities.bat /all         also DUFSQLConnections and
REM                                         ReadDFDriverDefXML
REM      BuildDUFUtilities.bat MyApp.sws    when the folder has several
REM                                         workspace files that use DUF
REM      BuildDUFUtilities.bat /nopause     do not wait for a key at the end
REM
REM  It needs Windows and DataFlex, nothing else: cmd, reg and df-cli.exe,
REM  which is part of DataFlex. df-cli is looked for on the PATH and then in
REM  the DataFlex folder the registry names. To point at it yourself, set the
REM  variable DFCLI to its full path before starting this script.
REM
REM  It writes to two places only: the folder DUFUtilitiesBuild in the
REM  workspace (copies of the sources it compiles, and the compiler's
REM  listings) and the Programs folder. The package folder in DfPkg is only
REM  read. DUFUtilitiesBuild can be deleted at any time.
REM ===========================================================================

REM The folder this script stands in, taken before the arguments are shifted.
set "HERE=%~dp0"
set "RC=0"
set "NOPAUSE="
set "ALL="
set "SWSARG="
set "BUILT="
set "FAILED="

:Args
if "%~1"=="" goto ArgsDone
if /i "%~1"=="/?" goto Usage
if /i "%~1"=="/all" goto ArgAll
if /i "%~1"=="/nopause" goto ArgNoPause
if defined SWSARG goto Usage
set "SWSARG=%~f1"
shift /1
goto Args
:ArgAll
set "ALL=1"
shift /1
goto Args
:ArgNoPause
set "NOPAUSE=1"
shift /1
goto Args
:ArgsDone

echo.
echo === DUF utilities: build in this workspace ===

REM --- the workspace folder and its workspace file --------------------------
set "WS=%HERE%"
if defined SWSARG for %%F in ("%SWSARG%") do set "WS=%%~dpF"
if "%WS:~-1%"=="\" set "WS=%WS:~0,-1%"

if not defined SWSARG goto FindSws
if not exist "%SWSARG%" goto NoSuchSws
set "SWS=%SWSARG%"
goto HaveSws

:FindSws
set "SWS="
set "COUNT=0"
for /f "delims=" %%F in ('findstr /m /i /c:"Library-DUF" "%WS%\*.sws" 2^>nul') do call :CountSws "%%F"
if "%COUNT%"=="1" goto HaveSws
if "%COUNT%"=="0" goto NoDufSws
goto ManySws

:HaveSws
echo Workspace file: "%SWS%"

REM --- the DataFlex version the workspace file names -------------------------
set "DFVER="
for /f "tokens=2 delims=:," %%V in ('findstr /r /c:"\"df\" *:" "%SWS%"') do if not defined DFVER set "DFVER=%%V"
if defined DFVER set "DFVER=%DFVER: =%"
if not defined DFVER goto NoDfVer

REM --- df-cli: the variable DFCLI, the PATH, the registry ---------------------
if not defined DFCLI goto CliOnPath
if exist "%DFCLI%" goto HaveCli
echo The variable DFCLI names a file that is not there: "%DFCLI%"
set "DFCLI="
:CliOnPath
for /f "delims=" %%P in ('where df-cli.exe 2^>nul') do if not defined DFCLI set "DFCLI=%%P"
if defined DFCLI goto HaveCli
call :CliFromKey "HKLM\SOFTWARE\Data Access Worldwide\DataFlex\%DFVER%"
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

REM --- where things go ---------------------------------------------------------
set "BUILD=%WS%\DUFUtilitiesBuild"
if not exist "%BUILD%\" mkdir "%BUILD%"
if not exist "%BUILD%\" goto NoBuildDir
set "OUT=%WS%\Programs"
if not exist "%OUT%\" set "OUT=%WS%"

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

REM --- build -----------------------------------------------------------------------
set "PROGRAMS=DUFCodeGenerator DUFSQLRepairUtility"
if defined ALL set "PROGRAMS=%PROGRAMS% DUFSQLConnections ReadDFDriverDefXML"
pushd "%WS%"
for %%P in (%PROGRAMS%) do call :BuildOne %%P
popd

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
REM  folder, a manifest is written beside them, and df-cli compiles from there.
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
"%DFCLI%" build-file "%BUILD%\%P%.src" --workspace "%SWS%" --output-dir "%OUT%" --cfg "%BUILD%\%P%.cfg" --toolchain %TOOLCHAIN% --rebuild --write-errors > "%BUILD%\%P%.log" 2>&1
if errorlevel 1 goto BuildFailed
if not exist "%OUT%\%P%64.exe" goto BuildFailed
echo   built: "%OUT%\%P%64.exe"
set "BUILT=%BUILT% %P%"
goto :eof

:BuildNoSource
echo   NOT built: the package has no "%P%.src".
goto BuildMarkFailed
:BuildNoCopy
echo   NOT built: could not copy the source to "%BUILD%".
goto BuildMarkFailed
:BuildFailed
echo   NOT built. What the compiler said:
findstr /i /c:"error" "%BUILD%\%P%.log"
echo   All of it is in "%BUILD%\%P%.log".
:BuildMarkFailed
set "RC=1"
set "FAILED=%FAILED% %P%"
goto :eof

REM ===========================================================================
REM  The manifest the Studio writes for a 64-bit program: the current Windows
REM  controls, no request for administrator rights, aware of the screen scaling.
REM  The project settings ask for it, and df-cli does not write one.
REM ===========================================================================
:WriteManifest
set "MF=%BUILD%\%P%64.exe.manifest"
> "%MF%" echo ^<?xml version="1.0"?^>
>>"%MF%" echo ^<assembly manifestVersion="1.0" xmlns="urn:schemas-microsoft-com:asm.v1"^>
>>"%MF%" echo   ^<assemblyIdentity version="1.0.0.0" processorArchitecture="amd64" name="DAW.DataFlex.%P%.src" type="win32"^>^</assemblyIdentity^>
>>"%MF%" echo   ^<description^>%P%.src^</description^>
>>"%MF%" echo   ^<dependency^>
>>"%MF%" echo     ^<dependentAssembly^>
>>"%MF%" echo       ^<assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls" version="6.0.0.0" processorArchitecture="amd64" publicKeyToken="6595b64144ccf1df" language="*"^>^</assemblyIdentity^>
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
:CountSws
set /a COUNT+=1
set "SWS=%~1"
goto :eof

:CountDuf
set /a COUNT+=1
set "DUFDIR=%~1"
goto :eof

REM df-cli.exe of the DataFlex whose registry key is handed in
:CliFromKey
set "ROOT="
for /f "tokens=2,*" %%A in ('reg query "%~1\Defaults" /v VDFRootDir /reg:64 2^>nul ^| findstr /i /c:"VDFRootDir"') do set "ROOT=%%B"
if not defined ROOT goto :eof
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
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
echo BuildDUFUtilities.bat [workspace file] [/all] [/nopause]
echo.
echo   Builds DUFCodeGenerator and DUFSQLRepairUtility from the sources of the
echo   DUF package into the Programs folder of this workspace.
echo   /all      also DUFSQLConnections and ReadDFDriverDefXML
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
echo No workspace file in "%WS%" uses the DUF package.
echo Add DUF to the workspace as a package first, then start this script from
echo the workspace folder.
set "RC=1"
goto End

:ManySws
echo.
echo Several workspace files in "%WS%" use the DUF package:
findstr /m /i /c:"Library-DUF" "%WS%\*.sws"
echo Name the one to build for: BuildDUFUtilities.bat MyApp.sws
set "RC=1"
goto End

:NoDfVer
echo.
echo The workspace file does not name a DataFlex version. This script is for
echo workspaces of DataFlex 26 and later.
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
echo The DUF package folder has no utility sources: "%DUFDIR%\AppSrc"
set "RC=1"
goto End

:NoBuildDir
echo.
echo Could not make the folder "%BUILD%".
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
