@echo off
REM ============================================================================
REM Zilium Super Compactor - Windows Build & Package Script
REM ============================================================================
REM Simple, clean build script for Windows with Qt6 GUI support
REM ============================================================================

setlocal enabledelayedexpansion

REM ============================================================================
REM Configuration
REM ============================================================================

set PROJECT_NAME=Zilium Super Compactor
set VERSION=1.0.0
set BUILD_DIR=build
set DIST_DIR=dist
set PACKAGE_NAME=zilium-windows-v%VERSION%

REM Qt6 Configuration
set QT_PATH=C:\Qt\6.9.3\msvc2022_64

REM Build Options
set BUILD_TYPE=Release
set BUILD_GUI=ON
set DO_PACKAGE=OFF
set DO_CLEAN=OFF

REM ============================================================================
REM Parse Arguments
REM ============================================================================

:parse_args
if "%~1"=="" goto :done_args
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="--gui" set BUILD_GUI=ON& shift& goto :parse_args
if /i "%~1"=="--cli-only" set BUILD_GUI=OFF& shift& goto :parse_args
if /i "%~1"=="--debug" set BUILD_TYPE=Debug& shift& goto :parse_args
if /i "%~1"=="--release" set BUILD_TYPE=Release& shift& goto :parse_args
if /i "%~1"=="--package" set DO_PACKAGE=ON& shift& goto :parse_args
if /i "%~1"=="--clean" set DO_CLEAN=ON& shift& goto :parse_args
if /i "%~1"=="--qt-path" (
    set QT_PATH=%~2
    shift
    shift
    goto :parse_args
)
echo Unknown option: %~1
goto :show_help

:done_args

REM ============================================================================
REM Display Banner
REM ============================================================================

echo.
echo ============================================================================
echo   %PROJECT_NAME% v%VERSION%
echo   Windows Build Script
echo ============================================================================
echo.
echo Configuration:
echo   Build Type: %BUILD_TYPE%
echo   Build GUI:  %BUILD_GUI%
echo   Qt Path:    %QT_PATH%
echo   Package:    %DO_PACKAGE%
echo   Clean:      %DO_CLEAN%
echo.

REM ============================================================================
REM Step 1: Clean (if requested)
REM ============================================================================

if "%DO_CLEAN%"=="ON" (
    echo [1/6] Cleaning...
    if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%" 2>nul
    if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%" 2>nul
    echo       OK Cleaned
    echo.
) else (
    echo [1/6] Skipping clean
    echo.
)

REM ============================================================================
REM Step 2: Check Prerequisites
REM ============================================================================

echo [2/6] Checking prerequisites...

REM Check CMake
where.exe cmake >nul 2>&1
if errorlevel 1 (
    echo       ERROR: CMake not found
    echo       Install from: https://cmake.org/download/
    exit /b 1
)
echo       OK CMake

REM Check Visual Studio
call :find_visual_studio
if "%VS_PATH%"=="" (
    echo       ERROR: Visual Studio 2022 not found
    echo       Install from: https://visualstudio.microsoft.com/downloads/
    exit /b 1
)
echo       OK Visual Studio 2022

REM Check Qt6 if building GUI
if "%BUILD_GUI%"=="ON" (
    if not exist "%QT_PATH%\bin\qmake.exe" (
        echo       ERROR: Qt6 not found at %QT_PATH%
        echo       Install Qt6 or use --qt-path
        exit /b 1
    )
    echo       OK Qt6
)

REM Check LP Tools
if not exist "lptools-prebuilt\win\lpmake.exe" (
    echo       WARNING: LP tools not found
) else (
    echo       OK LP tools
)

echo.

REM ============================================================================
REM Step 3: Initialize Visual Studio
REM ============================================================================

echo [3/6] Initializing Visual Studio...
call "%VS_PATH%" x64 >nul 2>&1
if errorlevel 1 (
    echo       ERROR: Failed to initialize Visual Studio
    exit /b 1
)
echo       OK Initialized
echo.

REM ============================================================================
REM Step 4: Configure CMake
REM ============================================================================

echo [4/6] Configuring CMake...

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

set CMAKE_ARGS=-G "Visual Studio 17 2022" -A x64
set CMAKE_ARGS=%CMAKE_ARGS% -DCMAKE_BUILD_TYPE=%BUILD_TYPE%
set CMAKE_ARGS=%CMAKE_ARGS% -DBUILD_GUI=%BUILD_GUI%

if "%BUILD_GUI%"=="ON" (
    set CMAKE_ARGS=%CMAKE_ARGS% -DCMAKE_PREFIX_PATH=%QT_PATH%
)

cmake -B "%BUILD_DIR%" %CMAKE_ARGS% -S .
if errorlevel 1 (
    echo       ERROR: CMake configuration failed
    exit /b 1
)
echo       OK Configured
echo.

REM ============================================================================
REM Step 5: Build
REM ============================================================================

echo [5/6] Building...
cmake --build "%BUILD_DIR%" --config %BUILD_TYPE% --parallel
if errorlevel 1 (
    echo       ERROR: Build failed
    exit /b 1
)
echo       OK Build complete
echo.

REM ============================================================================
REM Step 6: Deploy Qt (if GUI)
REM ============================================================================

if "%BUILD_GUI%"=="ON" (
    echo [6/6] Deploying Qt...
    
    set GUI_BUILD_DIR=%BUILD_DIR%\gui\%BUILD_TYPE%
    
    if not exist "!GUI_BUILD_DIR!\zilium-gui.exe" (
        echo       ERROR: zilium-gui.exe not found
        exit /b 1
    )
    
    if not exist "!GUI_BUILD_DIR!\Qt6Core.dll" (
        echo       Running windeployqt...
        if exist "%QT_PATH%\bin\windeployqt.exe" (
            "%QT_PATH%\bin\windeployqt.exe" --qmldir gui\qml --no-translations "!GUI_BUILD_DIR!\zilium-gui.exe"
            if errorlevel 1 (
                echo       WARNING: windeployqt had issues
            ) else (
                echo       OK Qt deployed
            )
        ) else (
            echo       WARNING: windeployqt not found
        )
    ) else (
        echo       OK Qt already deployed
    )
) else (
    echo [6/6] Skipping Qt deployment
)
echo.

REM ============================================================================
REM Build Summary
REM ============================================================================

echo ============================================================================
echo   Build Summary
echo ============================================================================
echo.
echo CLI: %BUILD_DIR%\%BUILD_TYPE%\zilium-super-compactor.exe
if "%BUILD_GUI%"=="ON" (
    echo GUI: %BUILD_DIR%\gui\%BUILD_TYPE%\zilium-gui.exe
)
echo.

REM Show file sizes
for %%A in ("%BUILD_DIR%\%BUILD_TYPE%\zilium-super-compactor.exe") do (
    echo CLI size: %%~zA bytes
)
if "%BUILD_GUI%"=="ON" (
    if exist "%BUILD_DIR%\gui\%BUILD_TYPE%\zilium-gui.exe" (
        for %%A in ("%BUILD_DIR%\gui\%BUILD_TYPE%\zilium-gui.exe") do (
            echo GUI size: %%~zA bytes
        )
    )
)
echo.

REM ============================================================================
REM Create Package (if requested)
REM ============================================================================

if "%DO_PACKAGE%"=="ON" (
    call :create_package
) else (
    echo To create distribution package:
    echo   %~nx0 --package
    echo.
)

echo ============================================================================
goto :eof

REM ============================================================================
REM Function: Find Visual Studio
REM ============================================================================

:find_visual_studio
set VS_PATH=

for %%e in (Enterprise Professional Community BuildTools) do (
    if exist "C:\Program Files\Microsoft Visual Studio\2022\%%e\VC\Auxiliary\Build\vcvarsall.bat" (
        set VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\%%e\VC\Auxiliary\Build\vcvarsall.bat
        goto :eof
    )
)

for %%e in (Enterprise Professional Community BuildTools) do (
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\2022\%%e\VC\Auxiliary\Build\vcvarsall.bat" (
        set VS_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2022\%%e\VC\Auxiliary\Build\vcvarsall.bat
        goto :eof
    )
)

goto :eof

REM ============================================================================
REM Function: Create Package
REM ============================================================================

:create_package
echo.
echo ============================================================================
echo   Creating Distribution Package
echo ============================================================================
echo.

set PACKAGE_DIR=%DIST_DIR%\%PACKAGE_NAME%

REM Clean and create package directory
if exist "%PACKAGE_DIR%" rmdir /s /q "%PACKAGE_DIR%" 2>nul
mkdir "%PACKAGE_DIR%"
mkdir "%PACKAGE_DIR%\lptools"

echo Copying executables...

REM Copy CLI executable
copy "%BUILD_DIR%\%BUILD_TYPE%\zilium-super-compactor.exe" "%PACKAGE_DIR%\" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy CLI executable
    goto :package_error
)

REM Copy GUI executable and Qt dependencies
if "%BUILD_GUI%"=="ON" (
    copy "%BUILD_DIR%\gui\%BUILD_TYPE%\zilium-gui.exe" "%PACKAGE_DIR%\" >nul
    if errorlevel 1 (
        echo ERROR: Failed to copy GUI executable
        goto :package_error
    )
    
    echo Deploying Qt dependencies...
    if exist "%QT_PATH%\bin\windeployqt.exe" (
        "%QT_PATH%\bin\windeployqt.exe" --qmldir gui\qml --no-translations "%PACKAGE_DIR%\zilium-gui.exe" >nul 2>&1
    )
)

echo Copying LP tools...

REM Copy LP tools
if exist "lptools-prebuilt\win\" (
    xcopy "lptools-prebuilt\win\*.*" "%PACKAGE_DIR%\lptools\" /Y /Q >nul 2>&1
    if exist "%PACKAGE_DIR%\lptools\lpmake.exe" (
        echo       OK lpmake.exe
    )
    if exist "%PACKAGE_DIR%\lptools\lpunpack.exe" (
        echo       OK lpunpack.exe
    )
    if exist "%PACKAGE_DIR%\lptools\lpdump.exe" (
        echo       OK lpdump.exe
    )
    if exist "%PACKAGE_DIR%\lptools\cygwin1.dll" (
        echo       OK cygwin1.dll
    )
)

echo Copying documentation...

REM Copy documentation
if exist "README.md" copy "README.md" "%PACKAGE_DIR%\" >nul
if exist "LICENSE" copy "LICENSE" "%PACKAGE_DIR%\" >nul
if exist "CHANGELOG.md" copy "CHANGELOG.md" "%PACKAGE_DIR%\" >nul

if exist "docs" (
    mkdir "%PACKAGE_DIR%\docs" 2>nul
    xcopy "docs\*.md" "%PACKAGE_DIR%\docs\" /Y /Q >nul 2>&1
)

echo Creating launcher scripts...

REM Create run.bat launcher
(
    echo @echo off
    echo REM Zilium Launcher
    echo set "ZILIUM_DIR=%%~dp0"
    echo set "PATH=%%ZILIUM_DIR%%lptools;%%PATH%%"
    echo.
    if "%BUILD_GUI%"=="ON" (
        echo if exist "%%ZILIUM_DIR%%zilium-gui.exe" ^(
        echo     start "" "%%ZILIUM_DIR%%zilium-gui.exe" %%*
        echo ^) else ^(
        echo     "%%ZILIUM_DIR%%zilium-super-compactor.exe" %%*
        echo ^)
    ) else (
        echo "%%ZILIUM_DIR%%zilium-super-compactor.exe" %%*
    )
) > "%PACKAGE_DIR%\run.bat"

REM Create comprehensive README.txt
echo Creating README.txt...
(
    echo ============================================================================
    echo   %PROJECT_NAME% v%VERSION% - Windows Edition
    echo ============================================================================
    echo.
    echo QUICK START
    echo -----------
    if "%BUILD_GUI%"=="ON" (
        echo   GUI: Double-click run.bat or zilium-gui.exe
        echo   CLI: run.bat C:\path\to\rom
        echo.
    ) else (
        echo   CLI: run.bat C:\path\to\rom
        echo.
    )
    echo PACKAGE CONTENTS
    echo ----------------
    echo   zilium-super-compactor.exe    CLI tool
    if "%BUILD_GUI%"=="ON" (
        echo   zilium-gui.exe                Qt6 GUI application
        echo   Qt6*.dll                      Qt runtime libraries
        echo   platforms\, qml\, etc.        Qt plugins
    )
    echo   lptools\lpmake.exe            Android LP partition tool
    echo   lptools\lpunpack.exe          Android LP unpacker
    echo   lptools\lpdump.exe            Android LP dumper
    echo   lptools\cygwin1.dll           Required runtime library
    echo   run.bat                       Quick launcher
    echo   README.txt                    This file
    echo.
    echo SYSTEM REQUIREMENTS
    echo -------------------
    echo   • Windows 10/11 ^(64-bit^)
    echo   • Visual C++ Redistributable 2015-2022
    echo     Download: https://aka.ms/vs/17/release/vc_redist.x64.exe
    echo.
    echo USAGE
    echo -----
    if "%BUILD_GUI%"=="ON" (
        echo   GUI Mode:
        echo     1. Double-click run.bat
        echo     2. Select ROM folder
        echo     3. Choose output location
        echo     4. Click "Start Compiling"
        echo.
    )
    echo   CLI Mode:
    echo     run.bat C:\path\to\rom\folder
    echo     run.bat C:\path\to\rom\folder config.json
    echo     run.bat C:\path\to\rom\folder config.json C:\output
    echo.
    echo EXAMPLES
    echo --------
    echo   run.bat D:\ColorOS\RMX3500_11_F.29
    echo   run.bat D:\ColorOS\RMX3500_11_F.29 super_config.json
    echo   run.bat D:\ColorOS\RMX3500_11_F.29 super_config.json D:\Output
    echo.
    echo DIRECTORY STRUCTURE
    echo -------------------
    echo   Expected ROM structure:
    echo     RomFolder\
    echo     ├── META\
    echo     │   └── super_config.json
    echo     └── IMAGES\
    echo         ├── system.img
    echo         ├── vendor.img
    echo         ├── product.img
    echo         └── ...
    echo.
    echo   Output:
    echo     RomFolder\super.img  ^(or custom output location^)
    echo.
    echo TROUBLESHOOTING
    echo ---------------
    echo   Q: "VCRUNTIME140.dll was not found"
    echo   A: Install Visual C++ Redistributable
    echo      https://aka.ms/vs/17/release/vc_redist.x64.exe
    echo.
    echo   Q: "lpmake failed"
    echo   A: Ensure lptools\lpmake.exe and cygwin1.dll are present
    echo      Check ROM folder structure is correct
    echo.
    if "%BUILD_GUI%"=="ON" (
        echo   Q: GUI won't start
        echo   A: Ensure all Qt DLLs are in the same folder
        echo      Try running from command line to see errors
        echo.
    )
    echo SUPPORT
    echo -------
    echo   GitHub:   https://github.com/Badmaneers/zilium
    echo   Issues:   https://github.com/Badmaneers/zilium/issues
    echo   Telegram: @DumbDragon
    echo.
    echo LICENSE
    echo -------
    echo   MIT License - See LICENSE file
    echo   Copyright ^(c^) 2025 Badmaneers
    echo.
    echo BUILD INFO
    echo ----------
    echo   Version:    %VERSION%
    echo   Build:      %BUILD_TYPE%
    echo   Date:       %DATE% %TIME%
    if "%BUILD_GUI%"=="ON" (
        echo   GUI:        Yes ^(Qt6^)
    ) else (
        echo   GUI:        No
    )
    echo.
    echo ============================================================================
) > "%PACKAGE_DIR%\README.txt"

REM Create ZIP if 7z available
where.exe 7z >nul 2>&1
if not errorlevel 1 (
    echo Creating ZIP archive with 7-Zip...
    cd "%DIST_DIR%"
    7z a -tzip "%PACKAGE_NAME%.zip" "%PACKAGE_NAME%" >nul 2>&1
    if not errorlevel 1 (
        echo       OK %PACKAGE_NAME%.zip created
        
        REM Generate checksums
        certutil -hashfile "%PACKAGE_NAME%.zip" SHA256 > "%PACKAGE_NAME%.sha256" 2>nul
        certutil -hashfile "%PACKAGE_NAME%.zip" MD5 > "%PACKAGE_NAME%.md5" 2>nul
        
        for %%A in ("%PACKAGE_NAME%.zip") do (
            set /a SIZE_MB=%%~zA/1024/1024
            echo       Size: !SIZE_MB! MB
        )
    )
    cd ..
) else (
    echo Creating ZIP archive with PowerShell...
    powershell -NoProfile -Command "$ProgressPreference = 'SilentlyContinue'; Compress-Archive -Path '%DIST_DIR%\%PACKAGE_NAME%' -DestinationPath '%DIST_DIR%\%PACKAGE_NAME%.zip' -Force" >nul 2>&1
    if exist "%DIST_DIR%\%PACKAGE_NAME%.zip" (
        echo       OK %PACKAGE_NAME%.zip created
        
        REM Generate checksums (using full paths)
        cd "%DIST_DIR%"
        certutil -hashfile "%PACKAGE_NAME%.zip" SHA256 > "%PACKAGE_NAME%.sha256" 2>nul
        certutil -hashfile "%PACKAGE_NAME%.zip" MD5 > "%PACKAGE_NAME%.md5" 2>nul
        cd ..
        
        for %%A in ("%DIST_DIR%\%PACKAGE_NAME%.zip") do (
            set /a SIZE_MB=%%~zA/1024/1024
            echo       Size: !SIZE_MB! MB
        )
    ) else (
        echo       WARNING: ZIP creation failed
    )
)

echo.
echo ============================================================================
echo   Package Complete!
echo ============================================================================
echo.
echo Location: %PACKAGE_DIR%\
if exist "%DIST_DIR%\%PACKAGE_NAME%.zip" (
    echo Archive:  %DIST_DIR%\%PACKAGE_NAME%.zip
)
echo.
echo Contents:
if exist "%PACKAGE_DIR%\zilium-super-compactor.exe" (
    echo   [OK] zilium-super-compactor.exe
)
if "%BUILD_GUI%"=="ON" (
    if exist "%PACKAGE_DIR%\zilium-gui.exe" (
        echo   [OK] zilium-gui.exe
    )
    if exist "%PACKAGE_DIR%\Qt6Core.dll" (
        echo   [OK] Qt6 runtime DLLs
    )
)
if exist "%PACKAGE_DIR%\lptools\lpmake.exe" (
    echo   [OK] lptools\lpmake.exe
)
if exist "%PACKAGE_DIR%\lptools\cygwin1.dll" (
    echo   [OK] lptools\cygwin1.dll
)
echo.
echo Ready for distribution!
echo.

goto :eof

:package_error
echo.
echo ERROR: Package creation failed
echo.
goto :eof

REM ============================================================================
REM Function: Show Help
REM ============================================================================

:show_help
echo.
echo Usage: %~nx0 [options]
echo.
echo Build %PROJECT_NAME% for Windows
echo.
echo Options:
echo   --gui              Build GUI application ^(default^)
echo   --cli-only         Build only CLI tool
echo   --debug            Build in Debug mode
echo   --release          Build in Release mode ^(default^)
echo   --package          Create distribution package
echo   --clean            Clean before building
echo   --qt-path PATH     Specify Qt6 installation path
echo   --help, -h         Show this help
echo.
echo Examples:
echo   %~nx0                           Build everything
echo   %~nx0 --clean --package         Clean build and package
echo   %~nx0 --cli-only                Build CLI only
echo   %~nx0 --qt-path C:\Qt\6.8.0\msvc2022_64
echo.
echo Requirements:
echo   • CMake 3.16+
echo   • Visual Studio 2022
echo   • Qt6 ^(for GUI^)
echo   • LP tools in lptools-prebuilt\win\
echo.
exit /b 0
