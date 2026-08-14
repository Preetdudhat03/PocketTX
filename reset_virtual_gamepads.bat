@echo off
title PocketTX - Virtual Gamepad Service Cleaner
echo ========================================================
echo        PocketTX ViGEmBus Ghost Controller Cleaner        
echo ========================================================
echo.
echo [1/2] Stopping ViGEmBus Service (Flushing phantom gamepads)...
net stop ViGEmBus

echo.
echo [2/2] Restarting ViGEmBus Service...
net start ViGEmBus

echo.
echo ========================================================
echo SUCCESS! All phantom gamepads cleared from Windows.
echo Now launch PocketTX Companion PC App & open FPV.Skydive.
echo ========================================================
pause
