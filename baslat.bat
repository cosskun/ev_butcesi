@echo off
setlocal EnableDelayedExpansion
chcp 65001 > nul
title Ev Bütçesi - Kuruşu Kuruşuna Başlatılıyor...
cd /d "%~dp0"

echo ========================================================
echo   💰 EV BÜTÇESİ (Kuruşu Kuruşuna) BAŞLATILIYOR...
echo ========================================================
echo.

REM Flutter komutunu otomatik tespit et
set "FLUTTER_CMD="
if exist "%USERPROFILE%\.puro\envs\stable\flutter\bin\flutter.bat" (
    set "FLUTTER_CMD=%USERPROFILE%\.puro\envs\stable\flutter\bin\flutter.bat"
) else (
    where flutter >nul 2>nul
    if %errorlevel% equ 0 (
        set "FLUTTER_CMD=flutter"
    ) else (
        where puro >nul 2>nul
        if %errorlevel% equ 0 (
            set "FLUTTER_CMD=puro flutter"
        ) else if exist "%USERPROFILE%\flutter\bin\flutter.bat" (
            set "FLUTTER_CMD=%USERPROFILE%\flutter\bin\flutter.bat"
        ) else if exist "C:\Users\Superuser\flutter\bin\flutter.bat" (
            set "FLUTTER_CMD=C:\Users\Superuser\flutter\bin\flutter.bat"
        ) else if exist "C:\flutter\bin\flutter.bat" (
            set "FLUTTER_CMD=C:\flutter\bin\flutter.bat"
        ) else (
            set "FLUTTER_CMD=flutter"
        )
    )
)

echo [1/2] Tarayici otomatik acilacak (http://localhost:8081)...
start "" "http://localhost:8081"

echo [2/2] Flutter Web Sunucusu baslatiliyor...
echo.
echo IPUCU: Kodlari guncellemek icin bu pencerede 'R' tusuna basabilirsiniz.
echo.

"%FLUTTER_CMD%" run -d web-server --web-port=8081

pause
