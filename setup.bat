@echo off
setlocal

REM ===========================================================================
REM  Library-DUF - one-time setup
REM
REM  Run this once after cloning (and any time the Libraries\ folders look
REM  empty or out of date, or a submodule has changed). It:
REM    1. Downloads / updates the library submodules (DFAbout, RDCToolsLib,
REM       vwin32fh) to the exact versions this workspace expects.
REM    2. Configures THIS clone so a normal "git pull" keeps those libraries
REM       in sync automatically from then on.
REM
REM  Nothing here is destructive: it only fetches libraries and sets one
REM  local git option for this repository.
REM ===========================================================================

cd /d "%~dp0"

echo.
echo === Library-DUF setup ===
echo Working folder: %CD%
echo.

where git >nul 2>nul
if errorlevel 1 (
    echo [ERROR] Git was not found on your PATH.
    echo         Install Git ^(or the GitHub Desktop app^), reopen the
    echo         command prompt, and run setup.bat again.
    echo.
    pause
    exit /b 1
)

git rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
    echo [ERROR] This folder is not a git repository.
    echo         Clone Library-DUF with GitHub Desktop or "git clone", then
    echo         run setup.bat from the repository root.
    echo.
    pause
    exit /b 1
)

echo Synchronizing submodule definitions...
git submodule sync --recursive

echo.
echo Downloading / updating library submodules ^(this may take a minute^)...
git submodule update --init --recursive
if errorlevel 1 (
    echo.
    echo [ERROR] One or more submodules could not be fetched.
    echo         Check your internet connection and that you can reach:
    echo           - https://github.com/NilsSve/Library-DFAbout.git
    echo           - https://github.com/NilsSve/Library-RDCToolsLib
    echo           - https://github.com/NilsSve/Library-vwin32fh.git
    echo         Then run setup.bat again.
    echo.
    pause
    exit /b 1
)

echo.
echo Configuring this clone to keep libraries in sync on every "git pull"...
git config submodule.recurse true

echo.
echo === Setup complete ===
echo.
echo The Libraries\ folder now holds DFAbout, RDCToolsLib and vwin32fh at
echo the versions this workspace expects. From now on a normal "git pull"
echo (or Pull in GitHub Desktop) will also update these libraries
echo automatically.
echo.
echo If a brand-new library/submodule is ever added, just run setup.bat once
echo more to pick it up.
echo.
pause
exit /b 0
