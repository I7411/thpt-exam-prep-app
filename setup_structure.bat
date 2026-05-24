@echo off
REM Create Flutter Project Directory Structure
REM This batch file creates the standardized directory structure for the THPT Exam Prep App

setlocal enabledelayedexpansion

cd lib

echo Creating core directories...
mkdir core\config 2>nul
mkdir core\constants 2>nul
mkdir core\routes 2>nul
mkdir core\theme 2>nul
mkdir core\utils 2>nul

echo Creating data directories...
mkdir data\models 2>nul
mkdir data\mock 2>nul
mkdir data\local 2>nul
mkdir data\remote 2>nul
mkdir data\repositories 2>nul

echo Creating providers directory...
mkdir providers 2>nul

echo Creating screens directories...
mkdir screens\splash 2>nul
mkdir screens\auth 2>nul
mkdir screens\student 2>nul
mkdir screens\document 2>nul
mkdir screens\exam 2>nul
mkdir screens\progress 2>nul
mkdir screens\notification 2>nul
mkdir screens\profile 2>nul
mkdir screens\teacher 2>nul
mkdir screens\admin 2>nul

echo Creating widgets directory...
mkdir widgets 2>nul

echo.
echo ✓ All directories created successfully!
echo.
echo Next steps:
echo   1. Run: flutter clean
echo   2. Run: flutter pub get
echo   3. Run: flutter analyze
echo.
pause
