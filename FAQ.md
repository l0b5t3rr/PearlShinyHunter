# Frequently Asked Questions

## Can the Lua script be loaded automatically?

**Short answer:** Unfortunately, no. The Lua script must be manually loaded through DeSmuME's Lua console.

**Why?**

DeSmuME's Lua scripting system is designed as an embedded feature within the emulator. There's no external API that allows:
- Loading Lua scripts programmatically from outside DeSmuME
- Controlling DeSmuME via command-line arguments to auto-load Lua scripts
- Communicating with DeSmuME's Lua environment from external applications

**The workflow is:**
1. External C# app can **launch** DeSmuME with a ROM (using command-line arguments)
2. But the user must **manually load the Lua script** via the UI
3. Once loaded, the Lua script communicates with the C# app via the status file

**What we've done to make it easier:**
- ✅ The C# app provides a "Launch Emulator" button that opens DeSmuME with your ROM
- ✅ The C# app shows you the exact path to the Lua script to load
- ✅ The Lua script uses **relative paths** so it works regardless of where you install the project
- ✅ You only need to load the script once per session

**Alternative approaches that don't work:**
- ❌ AutoHotkey/AutoIt scripts - Too fragile and dependent on UI layout
- ❌ DeSmuME command-line flags - No such flags exist for Lua
- ❌ DeSmuME API - No external API exists
- ❌ Modified DeSmuME build - Would require maintaining a custom fork

## Why use relative paths in Lua?

Using relative paths makes the project **portable**. The Lua script automatically detects its own location and builds paths relative to that:

```lua
-- OLD (hardcoded, breaks on different systems):
local STATUS_FILE = "e:\\PearlShinyHunter\\shared\\status.txt"

-- NEW (portable, works anywhere):
local scriptPath = debug.getinfo(1, "S").source:sub(2)
local scriptDir = scriptPath:match("(.*\\)")
local STATUS_FILE = scriptDir .. "..\\shared\\status.txt"
```

This means:
- ✅ Works on any Windows drive (C:, D:, E:, etc.)
- ✅ Works in any folder location
- ✅ Can be cloned/copied without modification
- ✅ Multiple users can use the same script

## How does the C# app help with setup?

The updated UI includes a **Setup Panel** that:

1. **Saves your emulator and ROM paths** for future sessions
2. **Launches DeSmuME automatically** with your ROM loaded
3. **Shows you exactly where the Lua script is** after launching
4. **Remembers your settings** in `shared/user_settings.json`

This reduces the manual steps from:
- ❌ Find DeSmuME
- ❌ Open it manually
- ❌ Navigate to your ROM
- ❌ Remember where the Lua script is

To just:
- ✅ Click "Launch Emulator with ROM"
- ✅ Load the Lua script (path is shown in the log)

## Can I modify this for other Pokémon?

Yes! The system is designed to be extensible:

1. **In the Lua script**, change the target species:
   ```lua
   local TARGET_SPECIES_ID = 129  -- Change this
   local TARGET_SPECIES_NAME = "Magikarp"  -- And this
   ```

2. **For grass encounters**, you'd need to modify:
   - Detection logic (replace fishing state with walking/grass state)
   - Input sequence (walking instead of fishing rod)
   - Memory addresses (encounter mechanics differ)

3. **For other games** (Diamond, Platinum, etc.):
   - Memory addresses will be different
   - Use DeSmuME's memory viewer to find the correct addresses
   - The core logic (shiny calculation, input handling) remains the same

## What if my ROM version has different memory addresses?

See [MEMORY_ADDRESSES.md](MEMORY_ADDRESSES.md) for detailed guidance on finding the correct addresses for your ROM version.

Quick tips:
- Use DeSmuME's memory viewer (`Tools → View Memory`)
- Search for known values (your Pokémon's level, species, etc.)
- Cross-reference with Pokémon data structure documentation
- Test by manually fishing and watching memory changes

## Why separate Lua and C# instead of one tool?

This architecture has several advantages:

**Lua (inside emulator):**
- ✅ Direct memory access (fast and accurate)
- ✅ Frame-perfect input control
- ✅ No external memory reading tools needed
- ✅ Works at emulator speed (can use fast-forward)

**C# (external app):**
- ✅ Better UI capabilities (Windows Forms)
- ✅ System notifications and alerts
- ✅ Persistent logging and statistics
- ✅ Doesn't slow down the emulator
- ✅ Easier to develop and debug

**Communication via file:**
- ✅ Simple and reliable
- ✅ No complex IPC needed
- ✅ Can monitor/debug by just opening the file
- ✅ Language-agnostic (could swap C# for Python, etc.)

This separation of concerns makes the system more maintainable and robust.

## Can I speed up the hunting process?

Yes! Several ways to optimize:

1. **Use DeSmuME's fast-forward** (Tab key) - Runs emulation faster
2. **Disable frame limiter** - Removes speed cap entirely
3. **Reduce emulator accuracy settings** - Faster but less accurate
4. **Optimize wait times in Lua** - Reduce `waitFrames()` values if reliable
5. **Use save states efficiently** - Keep save state right before casting

With fast-forward enabled, you can check hundreds of encounters per hour!

## Is this safe for my save file?

**Yes, completely safe!** The automation:
- ✅ Only uses **savestates** (not in-game saves)
- ✅ Never writes to your actual save file
- ✅ Can be stopped at any time (just close Lua window)
- ✅ Doesn't modify ROM or emulator settings

Your actual in-game save remains untouched. Even if something goes wrong, just reload your in-game save.

**Best practice:** Keep a backup of your `.sav` file just in case!

## What's the shiny hunting success rate?

In Gen 4 (Pokémon Pearl), the base shiny rate is:
- **1 in 8,192** without Shiny Charm
- **1 in 2,731** with Masuda Method (not applicable here)

With automation running at ~10-20 encounters per minute (depending on fast-forward), you can expect:
- ~400-1200 checks per hour
- **Average time to shiny: 7-20 hours** of active hunting
- Some people find shinies in 10 minutes, others take days (it's random!)

The automation makes it bearable by removing the manual tedium!
