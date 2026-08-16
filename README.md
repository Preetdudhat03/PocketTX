# 🚁 PocketTX

> **Turn your Android Phone into a High-Precision RC Flight Simulator Controller for Windows**

PocketTX transforms your smartphone into a virtual RC transmitter with ultra-low latency, 250Hz packet rate, and customisable stick layouts. It pairs with a Windows Companion app that emulates a native **Xbox 360 Controller** via **ViGEmBus**, enabling plug-and-play support for popular RC flight simulators like **PicaSim**, **Liftoff**, **RealFlight**, **FPV Freerider**, **VelociDrone**, and **Uncrashed**.

---

## 📌 Table of Contents
1. [✨ What is PocketTX?](#-what-is-pockettx)
2. [📦 Prerequisites & Direct Downloads](#-prerequisites--direct-downloads)
3. [🚀 Step-by-Step Setup Guide <!--(Layman Friendly)-->](#-step-by-step-setup-guide-layman-friendly)
   - [Step 1: Install ViGEmBus Driver (Xbox Controller Emulation)](#step-1-install-vigembus-driver-xbox-controller-emulation)
   - [Step 2: Enable USB Debugging on Your Android Phone](#step-2-enable-usb-debugging-on-your-android-phone)
   - [Step 3: Setup ADB & USB Reverse Port Forwarding](#step-3-setup-adb--usb-reverse-port-forwarding)
   - [Step 4: Launch the Windows Companion App](#step-4-launch-the-windows-companion-app)
   - [Step 5: Connect from PocketTX Android App](#step-5-connect-from-pockettx-android-app)
4. [🎮 Simulator Setup Guides](#-simulator-setup-guides)
5. [🕹️ Testing Stick Response & Latency on PC](#%EF%B8%8F-testing-stick-response--latency-on-pc)
6. [🛠️ Troubleshooting Guide](#%EF%B8%8F-troubleshooting-guide)
7. [📡 Technical Network Reference](#-technical-network-reference)

---

## ✨ What is PocketTX?

PocketTX consists of two parts working together:
1. **PocketTX Android App**: Runs on your phone, giving you touch gimbals and switches that stream inputs at **250Hz (every 4 milliseconds)**.
2. **PocketTX Companion App**: Runs on your Windows PC. It receives input over USB or Wi-Fi and creates a **Virtual Xbox 360 Controller** in Windows (`joy.cpl`), allowing any PC simulator to detect your phone as a real joystick.

```
┌───────────────────────────────────────┐
│          Android Phone                │
│       (PocketTX Mobile App)           │
└──────────────────┬────────────────────┘
                   │
         [ USB Cable / ADB Tunnel ]  <── (Recommended Zero-Lag Mode)
         (TCP 127.0.0.1:18458)
                   OR
         [ Wi-Fi / Local Network ]
         (UDP Broadcast 18456/18457)
                   │
                   ▼
┌───────────────────────────────────────┐
│          Windows PC                   │
│     (PocketTX Companion WPF App)      │
└──────────────────┬────────────────────┘
                   │
         [ ViGEmBus Driver API ]
                   │
                   ▼
┌───────────────────────────────────────┐
│     Native Xbox 360 Controller        │
│          (Windows joy.cpl)            │
└──────────────────┬────────────────────┘
                   │
                   ▼
┌───────────────────────────────────────┐
│    RC Simulators (PicaSim, Liftoff)   │
└───────────────────────────────────────┘
```

---

## 📦 Prerequisites & Direct Downloads

### On Windows PC
| Requirement | Why it's needed | Direct Download Link |
| :--- | :--- | :--- |
| **Windows 10 / 11 (64-bit)** | Operating System | — |
| **.NET 8.0 Desktop Runtime** | Required to run the Windows Companion App | [Download .NET 8.0 Runtime](https://dotnet.microsoft.com/download/dotnet/8.0) |
| **ViGEmBus Driver (v1.21.442)** | Emulates Xbox 360 Controller in Windows | [Download ViGEmBus Installer (.exe)](https://github.com/nefarius/ViGEmBus/releases/download/v1.21.442.0/ViGEmBus_1.21.442_x64_x86_arm64.exe) |
| **Android Platform Tools (ADB)** | Allows USB communication between Phone and PC | Included with Android Studio, SDK, or [SDK Platform-Tools](https://developer.android.com/tools/releases/platform-tools) |

### On Android Phone
* **Android OS**: Android 8.0 (Oreo) or higher.
* **USB Debugging**: Enabled in Developer Options.
* **USB Data Cable**: High quality USB-C / Micro-USB cable (must support data transfer, not charge-only).

---

## 🚀 Step-by-Step Setup Guide <!--(Layman Friendly) -->

Follow these exact steps in order for first-time setup:

### Step 1: Install ViGEmBus Driver (Xbox Controller Emulation)
*ViGEmBus allows your PC to treat PocketTX as a real physical Xbox 360 gamepad.*

1. Download the official installer: [ViGEmBus_1.21.442_x64_x86_arm64.exe](https://github.com/nefarius/ViGEmBus/releases/download/v1.21.442.0/ViGEmBus_1.21.442_x64_x86_arm64.exe).
2. Run the installer, accept the Administrator prompt, and click **Install**.
3. Verify driver status in PowerShell:
   ```powershell
   Get-Service ViGEmBus
   ```
   *(Status should display `Running`)*.

---

### Step 2: Enable USB Debugging on Your Android Phone

1. On your Android phone, open **Settings**.
2. Scroll down to **About Phone** (or *System ➔ About Phone*).
3. Find **Build Number** and tap it **7 times** continuously until a message pops up: *"You are now a developer!"*.
4. Go back to **Settings ➔ System ➔ Developer Options**.
5. Find **USB Debugging** and turn the switch **ON**.
6. Connect your phone to your PC using a USB data cable.
7. Set the USB connection mode on your phone to **File Transfer / MTP** (not *Charge Only*).
8. Look at your phone screen: a popup will appear asking **"Allow USB Debugging?"**. Check **Always allow from this computer** and tap **Allow**.

---

### Step 3: Setup ADB & USB Reverse Port Forwarding

> 💡 **What is ADB Reverse Forwarding?**
> When your phone connects over USB, typing `127.0.0.1` inside the phone app points to the phone itself. ADB reverse forwarding tells your computer to forward port `18458` through the USB cable directly into the Windows Companion App.

#### Option A: Automatically Add ADB to Windows PATH (One-Time Command)
Open PowerShell on your PC and run:
```powershell
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User"); if ($userPath -notlike "*platform-tools*") { [Environment]::SetEnvironmentVariable("PATH", "$userPath;C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\platform-tools", "User") }
```

#### Option B: Set Up USB Ports
In PowerShell, set up port forwarding by running:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:18456 tcp:18456
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:18457 tcp:18457
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:18458 tcp:18458
```
*(Or simply type `adb reverse tcp:18458 tcp:18458` if ADB is already in your PATH)*.

#### Verify Connected Phone:
Check if your phone is detected:
```powershell
adb devices
```
*Expected Output:*
```text
List of devices attached
RZCW61V9PAN    device
```

Check active USB tunnels:
```powershell
adb reverse --list
```
*Expected Output:*
```text
UsbFfs tcp:18458 tcp:18458
```

---

### Step 4: Launch the Windows Companion App

1. Open PowerShell / Command Prompt and navigate to the project directory:
   ```powershell
   cd PocketTX\companion
   ```
2. Build and launch the Companion UI:
   ```powershell
   dotnet run --project src\PocketTX.Companion.UI\PocketTX.Companion.UI.csproj
   ```
3. The Companion window will open and display: **`Active Backend: ViGEm (Xbox 360 Controller)`**. Keep this app open in the background while flying.

---

### Step 5: Connect from PocketTX Android App

1. Launch **PocketTX** on your Android phone.
2. Tap **CONNECT**.
3. Select **`127.0.0.1`** (for Wired USB) or enter your PC's local IP address (for Wireless Wi-Fi).
4. Tap **CONNECT**.
5. The PocketTX Companion UI on Windows will immediately update: **`Connected: [Your Phone Model] (USB-C)`**!

---

## 🎮 Simulator Setup Guides

### 🚁 PicaSim Setup
1. Launch **PicaSim** on your Windows PC.
2. Go to **Options ➔ Controller**.
3. Set **Mode** to **Joystick**.
4. Click **Joystick Setup** and select **Xbox 360 Controller for Windows** from the dropdown menu.
5. Move your phone touch joysticks to verify channel response:
   - **Left Stick Y**: Throttle
   - **Left Stick X**: Rudder (Yaw)
   - **Right Stick Y**: Elevator (Pitch)
   - **Right Stick X**: Aileron (Roll)

### 🛸 Liftoff / FPV Freerider / VelociDrone / Uncrashed Setup
1. Launch the simulator.
2. Go to **Controls / Calibration**.
3. Select **Xbox 360 Controller / Gamepad**.
4. Follow the in-game calibration wizard by centering and moving the sticks when prompted.

---

## 🕹️ Testing Stick Response & Latency on PC

PocketTX Companion includes an **Interactive Gimbal Visualizer** to test responsiveness and latency:

1. Open **PocketTX Companion** on your PC.
2. Click **TEST CONTROLLER MODE** in the navigation sidebar.
3. You will see live **LEFT STICK (THROTTLE / YAW)** and **RIGHT STICK (PITCH / ROLL)** visualizers with a real-time Telemetry Bar (`⚡ LATENCY: 1.2 ms`, `📡 PACKET RATE: 250 Hz`).
4. **Mouse Drag Simulation**: Click and drag the stick dots directly on your PC screen to simulate stick input without holding the phone.
5. **Live Phone Motion**: Move your phone's touch joysticks to watch the blue dots track your physical touch movements on screen in real-time with zero UI lag.

---

## 🛠️ Troubleshooting Guide

### ❓ Error: `adb : The term 'adb' is not recognized`
**Cause**: Android Platform Tools is installed but its folder path is not added to your Windows PATH environment variable.

**Fix**: Use the full path to `adb.exe` in PowerShell:
```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:18458 tcp:18458
```
Or run this command to permanently add ADB to your Windows PATH:
```powershell
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User"); if ($userPath -notlike "*platform-tools*") { [Environment]::SetEnvironmentVariable("PATH", "$userPath;C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\platform-tools", "User") }
```

---

### ❓ Error: `"Connection failed. Verify Windows Companion is running."`
**Cause**: The Windows Companion app isn't running, or ADB reverse port forwarding has not been executed.

**Fix**:
1. Make sure PocketTX Companion is open on your PC.
2. Run `adb reverse tcp:18458 tcp:18458` in PowerShell.
3. In the phone app, connect to **`127.0.0.1`**.

---

### ❓ `adb devices` shows `unauthorized`
**Cause**: The USB debugging prompt was not accepted on your Android phone.

**Fix**: Unlock your phone screen, disconnect and reconnect the USB cable, and tap **"Always Allow from this Computer"** when prompted.

---

### ❓ Windows Firewall prompt blocked the connection
**Cause**: Windows Firewall blocked incoming UDP/TCP traffic on Wi-Fi.

**Fix**: Run PowerShell as Administrator to add explicit Firewall permissions:
```powershell
New-NetFirewallRule -DisplayName "PocketTX UDP" -Direction Inbound -Protocol UDP -LocalPort 18456,18457 -Action Allow
New-NetFirewallRule -DisplayName "PocketTX TCP" -Direction Inbound -Protocol TCP -LocalPort 18458 -Action Allow
```

---

## 📡 Technical Network Reference

| Transport | Connection Type | Port | Description |
|-----------|-----------------|------|-------------|
| **TCP**   | Wired USB (ADB) | `18458` | Length-prefixed 2-byte framed binary stream over ADB tunnel |
| **UDP**   | Wi-Fi Unicast   | `18456` | Direct low-latency channel telemetry stream |
| **UDP**   | LAN Discovery   | `18457` | Beacon discovery & broadcast ping |

---

## 📄 License & Credits

- **PocketTX Core & App**: Built with Flutter & .NET 8.
- **Virtual Gamepad Engine**: Powered by [Nefarius.ViGEm.Client](https://github.com/nefarius/ViGEm.NET).
- **License**: MIT License..
