# Pokémon Pearl Shiny Magikarp Fishing Automation - Setup Guide

## Overview

This project automates shiny hunting for Magikarp in Pokémon Pearl using:
- **DeSmuME emulator** with Lua scripting support
- **Lua script** that reads game memory and controls inputs
- **C# Windows Forms application** that monitors progress and alerts you when a shiny is found

---

## Prerequisites

### 1. DeSmuME Emulator (with Lua Support)
- Download DeSmuME from: https://desmume.org/download/
- **IMPORTANT**: You need a version with Lua scripting support (not all versions have this)
- Recommended: DeSmuME 0.9.11 or newer with Lua enabled

#### 📦 Required: lua51.dll (Already Included!)
- The `lua51.dll` file is **already included** in the `lua/` folder
- This file must be present for DeSmuME to run Lua scripts
- Keep it in the same folder as `shiny_fishing.lua`

**If you move the Lua script**, make sure to move `lua51.dll` with it!

### 2. Pokémon Pearl ROM
- You need a legitimate Pokémon Pearl ROM (US version recommended)
- Other versions may work but memory addresses might differ

### 3. .NET 8.0 Runtime
- Download from: https://dotnet.microsoft.com/download/dotnet/8.0
- Required to run the C# controller application

---

## Initial Setup

### Step 1: Prepare Your Game Save

1. **Start Pokémon Pearl** in DeSmuME
2. Navigate to a **fishing spot** (Route 203, 204, etc.)
3. Make sure you have the **fishing rod selected** in your bag
4. **Stand in front of water** where you want to fish
5. **Save your game** (in-game save, not savestate yet)

### Step 2: Create a Savestate

1. In DeSmuME, press **Shift+F1** to save to slot 1
   - Or use menu: `File → Save State → Slot 1`
2. This savestate will be used to reset quickly after each attempt
3. Make sure you're in the **exact position** you want to fish from

### Step 3: Configure Memory Addresses (if needed)

The Lua script includes default memory addresses for Pokémon Pearl (US version):

```lua
FISHING_STATE = 0x021C4D84
BATTLE_FLAG = 0x021C6094
ENCOUNTER_SLOT = 0x0226AAEC
PARTY_POKEMON_1 = 0x022349B4
```

**If these don't work:**
1. You may be using a different ROM version
2. Use a memory scanner tool like Cheat Engine to find correct addresses
3. Update the addresses in `lua/shiny_fishing.lua`

---

## Running the Automation

### 🚀 Simplified Workflow (Recommended)

The UI now includes a **Step-by-Step Guide** that walks you through the entire process!

#### **Step 1: Launch the Controller**
- In VS Code: Press **F5**
- Or via terminal: `cd controller && dotnet run`

#### **Step 2: Set Paths**
- Click **"Browse Emulator"** → Select `DeSmuME.exe`
- Click **"Browse ROM"** → Select your `Pokemon_Pearl.nds`
- Paths are saved automatically for next time ✅

#### **Step 3: Launch Emulator**
- Click **"🚀 Launch Emulator with ROM"**
- DeSmuME opens with your ROM loaded ✅

#### **Step 4: Prepare In-Game**
In DeSmuME:
1. Navigate to a **fishing spot** (Route 203, 204, etc.)
2. Position yourself facing water with **rod selected**
3. **Create savestate**: Press **Shift+F1**

#### **Step 5: Load Lua Script**
In DeSmuME:
1. Go to `Tools → Lua Scripting → New Lua Script Window`
2. Click **"Browse"**
3. Navigate to `lua/shiny_fishing.lua` (path shown in controller log)
4. The script loads and shows: *"Waiting for START command from UI"*

**⚠️ If you see "lua51.dll was not found"**:
- Make sure `lua51.dll` is in the `lua/` folder (it should already be there)
- DeSmuME looks for the DLL in the same folder as the Lua script

#### **Step 6: Start Monitoring**
Back in the Controller:
- Click **"Start Monitoring"**
- Status updates to "READY" ✅

#### **Step 7: Start Automation**
- Click **"▶️ Start Automation"**
- The bot immediately begins fishing!

**No typing in Lua console needed!** Everything is controlled from the UI.

---

### 🎮 Automation Controls

Once running, you can:
- **⏸️ Pause** - Temporarily pause hunting
- **▶️ Resume** - Continue from where you left off  
- **⏹️ Stop** - Stop automation completely

All commands are sent from the UI to the Lua script automatically!

---

## How It Works

1. **Lua script casts the fishing rod** by pressing A
2. **Waits for a bite** (checks memory for bite flag)
3. If no bite after timeout → **reloads savestate and tries again**
4. If bite occurs → **presses A to trigger encounter**
5. **Reads encounter data**:
   - Species ID (checks if Magikarp)
   - PID (Personality ID)
   - TID/SID (Trainer ID / Secret ID)
6. **Calculates if shiny** using Gen 4 formula:
   ```
   shiny = (TID ⊕ SID ⊕ PID_high ⊕ PID_low) < 8
   ```
7. If shiny → **Writes "SHINY_FOUND" to status.txt and pauses**
8. If not shiny → **Reloads savestate and continues**

The C# application monitors `status.txt` and alerts you when a shiny is found!

---

## What You Need to Do Externally

### No External Tools Required!

The beauty of this approach is that **everything runs within DeSmuME's Lua environment**:

✅ **Memory reading** → Lua's `memory.readbyte/readword/readdword` functions  
✅ **Button pressing** → Lua's `joypad.set()` function  
✅ **Savestate control** → Lua's `savestate.load/saveslot()` functions  
✅ **File writing** → Lua's standard `io.open()` function  

### What DeSmuME Lua API Provides:

- `memory.readbyte(address)` - Read 1 byte from RAM
- `memory.readword(address)` - Read 2 bytes (16-bit)
- `memory.readdword(address)` - Read 4 bytes (32-bit)
- `joypad.set(player, buttons)` - Simulate button presses
- `emu.frameadvance()` - Advance one frame
- `savestate.load()` / `savestate.saveslot()` - Savestate management
- `io.open()` / `file:write()` - File I/O for communication

**You don't need any external memory reading tools or input simulators!**

---

## Troubleshooting

### Lua Script Not Working

**Problem:** Script loads but nothing happens
- **Check:** Are you on the correct DeSmuME version with Lua support?
- **Check:** Did you create a savestate in slot 1?
- **Check:** Are you standing at a fishing spot with rod selected?

**Problem:** Memory reads return unexpected values
- **Solution:** Memory addresses may be wrong for your ROM version
- Use DeSmuME's memory viewer to find correct addresses
- Update addresses in the Lua script

### No Bites Occurring

**Problem:** Script casts rod but never detects bites
- **Check:** `FISHING_STATE` memory address
- Try manually fishing and watching memory changes in DeSmuME's memory viewer
- The address should change when you get a bite

### Shiny Detection Not Working

**Problem:** Script finds Magikarp but doesn't recognize shinies
- **Check:** TID/SID reading from `PARTY_POKEMON_1` address
- Verify PID reading from encounter data
- Test with a known shiny PID if possible

### C# Application Can't Find Status File

**Problem:** Controller app shows "file not found" errors
- **Check:** The `shared/` directory exists
- **Check:** File paths in both Lua and C# match
- Try using absolute paths

---

## Configuration Options

Edit `shared/config.json` to customize:

```json
{
  "automation": {
    "max_wait_frames_for_bite": 600,  // How long to wait for bite (in frames)
    "enable_sound_alerts": true,       // Play sound when shiny found
    "enable_auto_focus": false         // Auto focus window on shiny
  }
}
```

---

## Statistics & Logging

The application logs:
- **Daily logs**: `shared/log_YYYYMMDD.txt`
- **Shiny encounters**: `shared/shiny_encounters.txt`

All attempts, encounters, and shiny finds are recorded for your records!

---

## Tips for Best Results

1. **Use fast-forward in DeSmuME** (Tab key) to speed up automation
2. **Disable frame limiter** for maximum speed
3. **Keep DeSmuME window focused** for input to register
4. **Don't minimize DeSmuME** while script is running
5. **Test memory addresses** before long hunting sessions

---

## Safety Notes

- The script uses **savestates**, not in-game saves
- Your actual game save is **never modified** during automation
- You can stop at any time by closing the Lua script window
- Always keep backups of your save files!

---

## Need Help?

If memory addresses aren't working:
1. Check your ROM version matches (US version recommended)
2. Use DeSmuME's memory viewer to manually locate values
3. Common tools: PokeFinder, RNG Reporter can help identify memory structures

Happy shiny hunting! 🌟
