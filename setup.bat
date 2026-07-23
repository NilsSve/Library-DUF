@echo off
setlocal enabledelayedexpansion

REM ===========================================================================
REM  Library-DUF - one-time setup for STANDALONE development
REM
REM  DUF no longer carries DFAbout, RDCToolsLib and vwin32fh as nested
REM  submodules. They are separate libraries, and every consumer declares them
REM  as a flat sibling list in its own workspace (see README.md for why). This
REM  script is only for working on DUF *on its own* - it clones those three as
REM  siblings of this folder, which is where DUFDev25.0.sws / DUFDev26.0.sws
REM  expect them (..\DFAbout, ..\RDCToolsLib, ..\vwin32fh).
REM
REM  When DUF is consumed as a library inside another workspace, that
REM  workspace's own setup provides the three siblings and this script is not
REM  needed - if run there, it finds them already present and does nothing.
REM
REM  Open DUFDev25.0.sws (or DUFDev26.0.sws) to build DUF standalone. The
REM  DUFLibrary25.0.sws / DUFLibrary26.0.sws files are the consumer-facing
REM  entry points and declare no libraries on purpose - the consumer supplies
REM  them. There is deliberately no plain DUF25.0.sws to open by mistake.
REM ===========================================================================

cd /d "%~dp0"

echo.
echo === Library-DUF standalone setup ===
echo DUF folder: %CD%
echo Siblings will be cloned into: %CD%\..
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

for %%N in (DFAbout RDCToolsLib vwin32fh) do (
    if exist "..\%%N\.git" (
        echo [%%N] already present - pulling latest...
        git -C "..\%%N" pull --ff-only
    ) else (
        echo [%%N] cloning as a sibling...
        git clone https://github.com/NilsSve/Library-%%N.git "..\%%N"
        if errorlevel 1 (
            echo.
            echo [ERROR] Could not clone Library-%%N.
            echo         Check your connection and that you can reach:
            echo           https://github.com/NilsSve/Library-%%N.git
            echo.
            pause
            exit /b 1
        )
    )
)

echo.
echo === Setup complete ===
echo.
echo DFAbout, RDCToolsLib and vwin32fh are now siblings of this folder.
echo Open DUFDev25.0.sws (or DUFDev26.0.sws) in the Studio to build DUF
echo standalone.
echo.
pause
exit /b 0
