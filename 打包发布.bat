@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0打包发布.ps1" %*
if errorlevel 1 (
    echo.
    echo Build failed. See the error above.
    pause
    exit /b 1
)
echo.
echo Build finished.
pause
