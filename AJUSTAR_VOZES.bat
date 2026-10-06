@echo off
chcp 65001 >nul
title Bicharada Cantante - ajustar vozes
python "%~dp0ajustar_vozes.py"
echo.
pause
