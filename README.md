# 🚁 PocketTX

> **Turn your Android Phone into a High-Precision RC Flight Simulator Controller for Windows**

PocketTX transforms your smartphone into a virtual RC transmitter with ultra-low latency, 250Hz packet rate, and customisable stick layouts. It pairs with a Windows Companion app that emulates a native **Xbox 360 Controller** via **ViGEmBus**, enabling plug-and-play support for popular RC flight simulators like **PicaSim**, **Liftoff**, **RealFlight**, **FPV Freerider**, **VelociDrone**, and **Uncrashed**.

---

## ✨ Features

- **⚡ Ultra-Low Latency Streaming**: Transmits stick positions and auxiliary switches at **250Hz (4ms interval)**.
- **🔌 Dual Connection Modes**:
  - **Wired USB Mode**: Zero-lag connection via length-prefixed TCP framed over ADB reverse tunnel (`127.0.0.1:18458`).
  - **Wireless Wi-Fi Mode**: Low-latency UDP broadcast & direct unicast streaming (`18456 / 18457`).
- **🎮 Native Windows Controller Emulation**: Integrates with **ViGEmBus** to present an **Xbox 360 Controller** directly to Windows OS (`joy.cpl`).
- **🎛️ Flight Transmitter Customization**:
  - Stick Modes: Mode 1, Mode 2 (Default), Mode 3, Mode 4.
  - Fine Tuning: Exponential (Expo), Neutral Deadband, End-point Trims, and Channel Reversing.
  - Interactive Calibration Wizard.
- **🛡️ Failsafe & Monitoring Engine**:
  - Heartbeat monitor with auto-disarm and failsafe fallback.
  - Live latency (ping), packet drop rate, and throughput metrics display.

---

## 🏗️ System Architecture

```
┌───────────────────────────────────────┐
│          Android Phone                │
│       (PocketTX Mobile App)           │
└──────────────────┬────────────────────┘
                   │
         [ USB Cable / ADB Tunnel ]
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

## 📋 Prerequisites & Requirements

### Windows PC
* **OS**: Windows 10 / 11 (64-bit)
* **Runtime**: [.NET 8.0 Desktop Runtime](https://dotnet.microsoft.com/download/dotnet/8.0) or SDK
* **Driver**: **ViGEmBus Driver** (`v1.21.442` or newer)
* **ADB**: Android Platform Tools (`adb.exe`) added to System PATH

### Android Phone
* **OS**: Android 8.0 (Oreo) or higher
* **Setting**: **USB Debugging** enabled (*Developer Options*)
* **Cable**: Quality USB Data Cable (USB-C to USB-A / USB-C)

---

## 🚀 Step-by-Step Setup Guide

### 1️⃣ Install ViGEmBus Driver on Windows
ViGEmBus allows PocketTX Companion to create a virtual Xbox 360 Controller in Windows.

1. Download the official installer: [ViGEmBus_1.21.442_x64_x86_arm64.exe](https://github.com/nefarius/ViGEmBus/releases/download/v1.21.442.0/ViGEmBus_1.21.442_x64_x86_arm64.exe)
2. Run the installer, accept the Administrator prompt, and click **Install**.
3. Verify driver status in PowerShell:
   ```powershell
   Get-Service ViGEmBus
   ```
   *(Status should read `Running`)*

---

### 2️⃣ Configure ADB Reverse Tunnel for Wired USB Mode

1. Connect your Android phone to your PC via USB cable.
2. Enable **USB Debugging** on your phone (*Settings ➔ Developer Options ➔ USB Debugging*).
3. Open PowerShell / Command Prompt and set up port forwarding:
   ```powershell
   adb reverse tcp:18456 tcp:18456
   adb reverse tcp:18457 tcp:18457
   adb reverse tcp:18458 tcp:18458
   ```
4. Verify the active tunnels:
   ```powershell
   adb reverse --list
   ```
   *Expected Output:*
   ```text
   UsbFfs tcp:18456 tcp:18456
   UsbFfs tcp:18457 tcp:18457
   UsbFfs tcp:18458 tcp:18458
   ```

---

### 3️⃣ Build & Launch Windows Companion App

1. Clone or open the repository:
   ```cmd
   git clone https://github.com/Preetdudhat03/PocketTX.git
   cd PocketTX\companion
   ```
2. Build the solution using .NET CLI:
   ```cmd
   dotnet build PocketTX.Companion.sln -c Debug
   ```
3. Run the Windows Companion UI:
   ```cmd
   dotnet run --project src\PocketTX.Companion.UI\PocketTX.Companion.UI.csproj
   ```
   *The Companion window will display `Active Backend: ViGEm (Xbox 360 Controller)`.*

---

### 4️⃣ Install & Launch PocketTX Android App

1. Navigate to the `android_app` directory:
   ```cmd
   cd ..\android_app
   ```
2. Build and run on your connected Android device:
   ```cmd
   flutter run --debug
   ```
3. In the PocketTX phone app:
   - Tap **CONNECT**.
   - Select **127.0.0.1** (or enter your PC's IP address for Wi-Fi).
   - Tap **CONNECT**.
4. The PocketTX Companion UI will show: **`Connected: [Your Phone Model] (USB-C)`**!

---

## 🎮 Simulator Setup (PicaSim, Liftoff, RealFlight)

### PicaSim Setup
1. Launch **PicaSim** on your PC.
2. Go to **Options ➔ Controller**.
3. Set **Mode** to **Joystick**.
4. Click **Joystick Setup** and select **Xbox 360 Controller for Windows** from the dropdown menu.
5. Move your phone touch sticks to verify channel response:
   - **Left Stick Y**: Throttle
   - **Left Stick X**: Rudder (Yaw)
   - **Right Stick Y**: Elevator (Pitch)
   - **Right Stick X**: Aileron (Roll)

### Liftoff / FPV Freerider / VelociDrone / Uncrashed Setup
1. Launch the simulator.
2. Go to **Controls / Calibration**.
3. Select **Xbox 360 Controller / Gamepad**.
4. Follow the simulator's calibration wizard by centering and moving the sticks when prompted.

---

## 📡 Network & Protocol Reference

| Transport | Connection Type | Port | Description |
|-----------|-----------------|------|-------------|
| **TCP**   | Wired USB (ADB) | `18458` | Length-prefixed 2-byte framed binary stream |
| **UDP**   | Wi-Fi Unicast   | `18456` | Direct low-latency channel telemetry data |
| **UDP**   | LAN Discovery   | `18457` | Beacon discovery & broadcast ping |

### Binary Packet Structure (24-Byte Header)
```text
Offset | Field        | Type   | Value / Description
-------|--------------|--------|----------------─────────────────
0..1   | Magic Bytes  | 2 Bytes| 0x50, 0x54 ('P', 'T')
2      | Version      | 1 Byte | 0x01 (Protocol Version)
3      | Type         | 1 Byte | 0x01 (Hello), 0x03 (ChannelData), 0x05 (ACK)
4..7   | Session ID   | UInt32 | Big-Endian Session Identifier
8..11  | Sequence     | UInt32 | Incremental Sequence Counter
12..19 | Timestamp    | UInt64 | Epoch Milliseconds
20..21 | Payload Len  | UInt16 | Length of attached payload
22..23 | Reserved     | 2 Bytes| Reserved alignment (0x0000)
24..N  | Payload      | Bytes  | UTF-8 Device Name or Channel Data
```

---

## 🛠️ Troubleshooting

### ❓ "SESSION_HANDSHAKE_FAILED" or "Host Unreachable"
- Verify ADB reverse tunnels are active: `adb reverse --list`.
- If using Wi-Fi, ensure PC Windows Firewall permits inbound traffic on UDP ports `18456` and `18457`.

### ❓ PicaSim doesn't list Xbox 360 Controller
- Check Windows Device Manager / PowerShell:
  ```powershell
  Get-PnpDevice | Where-Object { $_.FriendlyName -like "*Xbox*" }
  ```
- If status is not `OK`, restart the PocketTX Companion app so ViGEmBus initializes properly.

### ❓ Windows Firewall prompt blocked the connection
- Run PowerShell as Administrator to add firewall rules:
  ```powershell
  New-NetFirewallRule -DisplayName "PocketTX UDP" -Direction Inbound -Protocol UDP -LocalPort 18456,18457 -Action Allow
  New-NetFirewallRule -DisplayName "PocketTX TCP" -Direction Inbound -Protocol TCP -LocalPort 18458 -Action Allow
  ```

---

## 📄 License & Credits

- **PocketTX Core & App**: Built with Flutter & .NET 8.
- **Virtual Gamepad Engine**: Powered by [Nefarius.ViGEm.Client](https://github.com/nefarius/ViGEm.NET).
- **License**: MIT License..