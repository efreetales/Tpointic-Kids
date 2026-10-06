@echo off
chcp 65001 >nul
title Bicharada Cantante - gerador de audios
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0gerar_audios.ps1"
echo.
pause
