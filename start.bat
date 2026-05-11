@echo off
title Al-awqat - serveur dev
cd /d "%~dp0"
echo ================================================
echo   Al-awqat - serveur Flutter web sur le port 8080
echo ================================================
echo.
echo   Une fois lance :
echo     r   = hot reload  (petits changements)
echo     R   = hot restart (changements de tailles, structure)
echo     q   = quitter
echo.
echo   Ouvre ensuite :  http://localhost:8080
echo ================================================
echo.
where flutter
if errorlevel 1 (
    echo.
    echo [ERREUR] La commande "flutter" est introuvable.
    echo   Verifie que Flutter est installe et dans ton PATH.
    echo.
    pause
    exit /b 1
)
echo.
cmd /k flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
