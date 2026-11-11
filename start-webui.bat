@echo off
title Personal Local AI System
echo Launching Personal Local AI System (Ollama + Open WebUI)...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-webui.ps1"
pause
