# Pokémon Pearl Shiny Magikarp Hunter 🌟

An automated shiny hunting tool for Pokémon Pearl using DeSmuME emulator with Lua scripting and a C# Windows Forms controller application.

## Overview

This project automates the tedious process of shiny hunting Magikarp in Pokémon Pearl by:
- Automatically casting the fishing rod
- Detecting encounters through memory reading
- Identifying shiny Pokémon using Gen 4 shiny calculation
- Automatically resetting when non-shiny encounters occur
- Alerting you when a shiny is found!

## Features

✨ **Fully Automated** - Handles casting, detecting bites, and checking for shinies  
🎯 **Memory-Based Detection** - No screen reading or audio analysis needed  
⚡ **Fast & Efficient** - Uses savestates for instant resets  
📊 **Live Statistics** - Track attempts, encounters, and more  
🔔 **Desktop Notifications** - Get alerted when a shiny appears  
📝 **Detailed Logging** - Records all attempts and shiny encounters  

## Project Structure

```
DPPShinyHunter/
├── lua/
│   └── shiny_fishing.lua       # Main Lua automation script
├── controller/
│   ├── DPPShinyHunter.csproj  # C# project file
│   ├── Program.cs               # Application entry point
│   ├── MainForm.cs              # Main UI window
│   ├── StatusMonitor.cs         # Monitors Lua script output
│   └── Logger.cs                # Handles logging
├── shared/
│   ├── status.txt               # Communication file (Lua → C#)
│   ├── config.json              # Configuration settings
│   └── log_*.txt                # Daily activity logs
├── SETUP_GUIDE.md               # Detailed setup instructions
├── MEMORY_ADDRESSES.md          # Memory address reference
└── README.md                    # This file
```

## Quick Start

### Prerequisites

1. **DeSmuME Emulator** (with Lua scripting support)
2. **Pokémon Pearl ROM** (US version recommended)
3. **.NET 8.0 Runtime** for the C# application

### Setup Steps

1. **Launch the Controller App** (Press F5 in VS Code or run `dotnet run` in `controller/`)

2. **Follow the Step-by-Step Guide in the UI:**
   - ✅ **Step 1:** Set emulator and ROM paths (Browse buttons provided)
   - ✅ **Step 2:** Click "🚀 Launch Emulator with ROM"
   - ✅ **Step 3:** In DeSmuME: Navigate to fishing spot, create savestate (Shift+F1)
   - ✅ **Step 4:** In DeSmuME: `Tools → Lua Scripting` → Load `lua/shiny_fishing.lua`
   - ✅ **Step 5:** Click "Start Monitoring" then "▶️ Start Automation"

**That's it!** The bot automatically casts, checks encounters, and alerts you when a shiny is found. No manual typing in the Lua console needed!

For detailed setup instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md).  
For common questions, see [FAQ.md](FAQ.md).

## How It Works

### Lua Script (Inside DeSmuME)
- Reads game memory to detect fishing state, encounters, and Pokémon data
- Emulates button presses to cast rod and trigger encounters
- Calculates if a Pokémon is shiny using: `(TID ⊕ SID ⊕ PID_high ⊕ PID_low) < 8`
- Writes status updates to `shared/status.txt`
- Reloads savestates for instant resets

### C# Controller (External Application)
- Monitors the `status.txt` file for updates
- Displays live statistics and activity log
- Plays sound alerts when shiny is found
- Records all attempts and shiny encounters

### Communication Flow
```
┌─────────────┐         ┌──────────────┐         ┌─────────────┐
│  DeSmuME    │ writes  │ status.txt   │ reads   │  C# App     │
│  (Lua)      │────────▶│ (shared)     │────────▶│ (Monitor)   │
└─────────────┘         └──────────────┘         └─────────────┘
      │                                                  │
      │ Controls game                                   │ Alerts user
      ▼                                                  ▼
  Pokémon Pearl                                   Desktop Notification
```

## Configuration

Edit `shared/config.json` to customize:

```json
{
  "automation": {
    "max_wait_frames_for_bite": 600,
    "enable_sound_alerts": true,
    "enable_auto_focus": false
  },
  "target_pokemon": {
    "species_id": 129,
    "species_name": "Magikarp"
  }
}
```

## Memory Addresses

Default addresses for Pokémon Pearl (US):
- Fishing State: `0x021C4D84`
- Battle Flag: `0x021C6094`
- Encounter Data: `0x0226AAEC`
- Party Pokémon 1: `0x022349B4`

If these don't work for your ROM, see [MEMORY_ADDRESSES.md](MEMORY_ADDRESSES.md) for help finding the correct addresses.

## Statistics & Logging

The application tracks:
- Total casting attempts
- Total encounters
- Non-Magikarp encounters
- Time per attempt

Logs are saved to:
- `shared/log_YYYYMMDD.txt` - Daily activity logs
- `shared/shiny_encounters.txt` - Record of all shiny finds

## Do You Need External Tools?

**No!** Everything runs within DeSmuME's built-in Lua environment:

✅ Memory reading via `memory.readbyte/word/dword()`  
✅ Button input via `joypad.set()`  
✅ Savestate control via `savestate.load()`  
✅ File I/O via standard Lua `io.open()`  

The C# application only monitors the status file and provides notifications—it never touches the emulator directly.

**Note:** The Lua script must be manually loaded in DeSmuME (there's no way to automate this), but the C# app makes it easy by launching the emulator for you and showing you exactly where the script is located. See [FAQ.md](FAQ.md) for more details.

## Tips for Best Results

- Use **fast-forward** (Tab) in DeSmuME for faster automation
- Disable **frame limiter** for maximum speed
- Keep DeSmuME window **focused** for input to work
- Verify **memory addresses** match your ROM version
- Always keep **backups** of your save files

## Troubleshooting

### Script loads but nothing happens
- Check that you created a savestate in slot 1
- Verify you're standing at a fishing spot with rod selected
- Make sure DeSmuME has Lua scripting support enabled

### Memory reads return wrong values
- Memory addresses may differ for your ROM version
- Use DeSmuME's memory viewer to find correct addresses
- See [MEMORY_ADDRESSES.md](MEMORY_ADDRESSES.md) for guidance

### C# app can't find status file
- Ensure the `shared/` directory exists
- Check that file paths match in both Lua and C# code
- Try using absolute paths

## Safety Notes

⚠️ **Important:**
- This tool uses **savestates**, not in-game saves
- Your actual game save is **never modified** during automation
- You can stop at any time safely
- Always keep backups of save files

## Future Enhancements

Potential features to add:
- [ ] Support for other Pokémon species
- [ ] Grass encounter mode
- [ ] Multiple ROM version support
- [ ] Advanced statistics and graphs
- [ ] Discord webhook notifications
- [ ] Auto-detection of memory addresses

## Contributing

Contributions are welcome! Areas that need help:
- Memory addresses for EU/JP ROM versions
- Testing with different DeSmuME versions
- UI improvements for the C# controller
- Additional automation modes (grass, etc.)

## License

This project is for educational purposes. Respect game copyrights and only use with legally obtained ROMs.

## Acknowledgments

- DeSmuME team for the excellent emulator
- Pokémon community for memory structure documentation
- Gen 4 RNG research community

---

**Happy shiny hunting!** 🎣✨

*May the odds be ever in your favor (1/8192)!*
