@echo off
setlocal
cd /d "%~dp0"

set "PYTHON_EXE=python"
if exist "%~dp0.venv\Scripts\python.exe" (
    set "PYTHON_EXE=%~dp0.venv\Scripts\python.exe"
)

"%PYTHON_EXE%" --version >nul 2>nul
if %errorlevel% neq 0 (
    echo [LOI] Khong tim thay Python tren may. Vui long cai dat Python 3.10+ va them vao PATH.
    pause
    exit /b 1
)

"%PYTHON_EXE%" start.py

pause
