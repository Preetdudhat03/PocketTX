@echo off
title PocketTX - One-Click USB Port Fixer
echo ========================================================
echo         PocketTX USB Port Forwarding Auto-Fixer        
echo ========================================================
echo.
echo [1/3] Checking connected Android devices...
"C:\Users\preet\AppData\Local\Android\Sdk\platform-tools\adb.exe" devices

echo.
echo [2/3] Setting up ADB reverse port forwardings...
"C:\Users\preet\AppData\Local\Android\Sdk\platform-tools\adb.exe" reverse tcp:18458 tcp:18458
"C:\Users\preet\AppData\Local\Android\Sdk\platform-tools\adb.exe" reverse tcp:18456 tcp:18456
"C:\Users\preet\AppData\Local\Android\Sdk\platform-tools\adb.exe" reverse tcp:18457 tcp:18457

echo.
echo [3/3] Active ADB Reverse Rules:
"C:\Users\preet\AppData\Local\Android\Sdk\platform-tools\adb.exe" reverse --list

echo.
echo ========================================================
echo SUCCESS! USB ports are ready. Now launch Companion PC app ^& open PocketTX on phone.
echo ========================================================
pause
