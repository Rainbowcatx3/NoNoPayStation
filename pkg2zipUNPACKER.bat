@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1
echo ========================================
echo Converting ALL .pkg files with pkg2zip
echo ========================================
echo.
:: === Configuration ===
set "SEVENZIP=C:\Program Files\7-Zip\7z.exe"
:: Check required files
if not exist "%SEVENZIP%" (
    echo ERROR: 7-Zip not found at "%SEVENZIP%"
    echo Please edit the script and set the correct path.
    pause
    exit /b 1
)
if not exist "%~dp0pkg2zip.exe" (
    echo ERROR: pkg2zip.exe not found in the script folder!
    pause
    exit /b 1
)
echo Processing all .pkg files...
echo.
for /r %%f in (*.pkg) do (
    echo Processing: %%~nxf
    pushd "%%~dpf"
    set "PKGFILE=%%~nxf"
    echo Running pkg2zip...
    "%~dp0pkg2zip.exe" "!PKGFILE!"
    :: Find the newest .zip
    set "NEWZIP="
    for /f "delims=" %%z in ('dir *.zip /b /o:d /t:c 2^>nul') do set "NEWZIP=%%z"
    if defined NEWZIP (
        echo Extracting: !NEWZIP! ...
        "%SEVENZIP%" x "!NEWZIP!" -o"." -y -mcp=932 >nul 2>&1
        if errorlevel 1 (
            echo WARNING: Extraction may have had issues.
        ) else (
            echo Extraction successful - deleting .zip
            del "!NEWZIP!" >nul 2>&1
            echo Processing license structure...
            set "FOUND=0"
            :: === 1. Main app ===
            if exist "app\*" (
                for /d %%a in (app\*) do (
                    if exist "work.bin" (
                        set "TITLE_ID=%%~na"
                        echo Found work.bin
                        if not exist "app\!TITLE_ID!\sce_sys\package\" mkdir "app\!TITLE_ID!\sce_sys\package\"
                        move "work.bin" "app\!TITLE_ID!\sce_sys\package\work.bin" >nul
                        echo Moved → app\!TITLE_ID!\sce_sys\package\work.bin
                        set "FOUND=1"
                    )
                )
            )
            :: === 2. DLC / addcont (ALWAYS create structure) ===
            if exist "addcont\*" (
                for /d %%t in (addcont\*) do (
                    set "TITLE_ID=%%~nt"
                    for /d %%d in ("%%t\*") do (
                        set "DLC_ID=%%~nd"
                        echo Found DLC folder: addcont\!TITLE_ID!\!DLC_ID!
                        if exist "work.bin" (
                            move "work.bin" "addcont\!TITLE_ID!\!DLC_ID!\sce_sys\package\work.bin" >nul
                            echo Moved work.bin → addcont\!TITLE_ID!\!DLC_ID!\sce_sys\package\work.bin
                            set "FOUND=1"
                        )
                    )
                )
            )
                if "!FOUND!"=="0" (
                echo NOTE: No work.bin found, but folder structure created if applicable.
            )
            :: === Delete original .pkg ===
            echo Deleting original .pkg file...
            del "!PKGFILE!" >nul 2>&1
            if not exist "!PKGFILE!" (
                echo ✓ .pkg deleted successfully
            ) else (
                echo WARNING: Could not delete !PKGFILE!
            )
        )
    ) else (
        echo WARNING: No .zip file created by pkg2zip
    )
    popd
    echo.
)
echo ========================================
echo Finished!
echo All .pkg files processed and deleted.
echo DLC folders handled correctly.
echo ========================================
pause
