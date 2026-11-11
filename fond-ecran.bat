@echo off
rem Fond d'ecran Al-awqat : un double-clic l'allume, un autre l'eteint.
tasklist /FI "IMAGENAME eq al_awqat.exe" | find /I "al_awqat.exe" >nul
if not errorlevel 1 (
    taskkill /IM al_awqat.exe /F >nul
) else (
    start "" "%~dp0build\windows\x64\runner\Release\al_awqat.exe" --fond
)
