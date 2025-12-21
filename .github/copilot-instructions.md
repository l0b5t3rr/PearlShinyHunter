# Project Instructions for GitHub Copilot

This document summarizes the intent, workflow, tooling, scripting strategy, and development expectations for building a **DESMuME Pokémon Pearl Shiny Magikarp Fishing Automation Tool** using **Lua Scripting + External Controller Application (C# preferred)**. Copilot should follow these guidelines while generating code.

---

## **Project Goal**

Create a desktop automation tool that:

* Automates fishing in **Pokémon Pearl (Nintendo DS)** using the **DeSmuME emulator**.
* Determines whether an encountered Pokémon is a **shiny Magikarp**.
* Alerts the user when a shiny is found.
* Restarts or recasts automatically when nothing bites or when the encounter is non-shiny.
* Uses **Lua scripting inside DeSmuME** to access memory values for speed and accuracy.
* Uses an **external program** (C#) to orchestrate the main loop and act upon signals from Lua.

---

## **Primary Tools & Technologies**

### Inside DeSmuME (Lua Script)

* Read **memory addresses** for:

  * Bite status (fishing)
  * Encounter species
  * Pokémon PID and shiny calculation results
* Trigger virtual button presses (DeSmuME’s `emu.keypress` API)
* Reload savestates instantly for fast attempts
* Write a small status file or flag to signal the external program

### External Controller (C#, preferred)

* Monitor a communication file written by Lua (`status.txt` or similar)
* Handle desktop-level notifications
* Track attempts, statistics, reset counts
* Optionally drive additional automation (e.g., window focusing)

---

## **Design Philosophy**

* **Lua handles all game logic** (memory, fishing outcome, shiny detection).
* **C# sends commands to Lua** via `command.txt` (START, PAUSE, RESUME, STOP).
* **C# supervises**, logs attempts, and alerts user on shiny.
* **Bidirectional communication**: Lua writes to `status.txt`, reads from `command.txt`.
* Avoid audio or screen detection entirely - use memory reading.
* Keep Lua script simple and ensure it runs safely at high speed inside the emulator.

---

## **High-Level Workflow**

1. User launches DeSmuME with Pokémon Pearl and navigates to a fishing spot.
2. User loads the Lua script (`lua/shiny_fishing.lua`) in DeSmuME via Tools → Lua Scripting.
3. User clicks **"Start Hunting"** in the C# controller application.
4. C# writes `START` to `command.txt`.
5. Lua detects START command and:
   * **Automatically creates savestate** in slot 1
   * Begins automation loop:
     * Casts fishing rod
     * Reads memory to check for bite
     * If no bite → reload savestate and retry
     * If bite → trigger encounter
     * Read encounter species
     * If not Magikarp → reload savestate
     * Read PID and calculate if shiny (Gen 4 formula)
     * If shiny → write `SHINY_FOUND` to status file and pause
     * Else → reload savestate and continue
6. C# monitors `status.txt` and alerts user when shiny is found.
7. User can PAUSE/RESUME/STOP via UI buttons (writes to `command.txt`).

---

## **File Structure Recommendations**

```
project-root/
│
├── lua/
│   └── shiny_fishing.lua   (main automation logic)
└── shared/
    ├── status.txt           (Lua → C# communication)
    ├── command.txt          (C# → Lua communication)
    ├── user_settings.json   (persisted emulator/ROM paths)
    └── config.json          (optional settings template)
└── shared/
    ├── status.txt           (Lua → C# communication)
    └── config.json          (optional user settings)
```

## **Lua Script Requirements**

Copilot should assist with:

* Reading memory using DeSmuME Lua API:
  * `memory.readbyte(address)` - Read 1 byte
  * `memory.readword(address)` - Read 2 bytes (16-bit)
  * `memory.readdword(address)` - Read 4 bytes (32-bit)
  * Fishing state (0x021C4D84)
  * Battle flag (0x021C6094)
  * Species ID (encounter slot at 0x0226AAEC)
  * Pokémon data structure (party at 0x022349B4)
  * PID, TID/SID
* Implementing shiny check (Gen 4 formula):
  ```
  shiny = ((TID ⊕ SID ⊕ PID_high ⊕ PID_low) < 8)
  ```
* Emulating button presses via `joypad.set()`
* Savestate management:
  * `savestate.save(slot)` - Save to slot number (NOT savestate.saveslot())
  * `savestate.load(slot)` - Load from slot number (NOT savestate.saveslot())
* File I/O:
  * Writing status to `status.txt` using `io.open()`
## **C# Controller Requirements**

Copilot should assist with:

* **Windows Forms UI** (.NET 8.0) with panels:
  * Setup panel: Browse/launch emulator and ROM (optional convenience)
  * Quick Start Guide: Step-by-step instructions for user
  * Statistics panel: Displays attempts, encounters, non-Magikarp count
  * Hunting Controls: Single "Start Hunting" button, Stop button
  * Activity Log: TextBox with scrolling output
* **Bidirectional communication**:
  * Write commands to `command.txt` (START, PAUSE, RESUME, STOP)
  * Monitor `status.txt` for Lua updates (250ms polling)
* **Status monitoring** via `StatusMonitor` class:
  * Parse key=value format from status.txt
## Important Implementation Notes

* The entire logic loop occurs **inside Lua for maximum speed**; the C# app should *never* attempt to control the game directly.
* Lua must handle timing precisely since Pokémon Pearl's fishing and encounter logic is deterministic.
* **Bidirectional file-based communication**:
  * `status.txt` - Lua writes status updates (STATUS=..., ATTEMPTS=..., ENCOUNTERS=...)
  * `command.txt` - C# writes commands (START, PAUSE, RESUME, STOP)
* **Savestate auto-creation**: When START command received, Lua automatically creates savestate before beginning
* **DeSmuME Lua API quirks**:
  * Use `savestate.save(1)` NOT `savestate.save(savestate.saveslot(1))`
  * Use `savestate.load(1)` NOT `savestate.load(savestate.saveslot(1))`
  * `saveslot()` function does not exist in DeSmuME's implementation
* **lua51.dll requirement**: Users must have `lua51.dll` in the same folder as the Lua script (included in lua/ folder)
* Keep all code modular so Copilot can generate and improve specific functions easily.
* Use relative paths in Lua for portability across different drive configurations.
  * MessageBox dialog
  * Optional window focus/flash
* **Settings persistence**:
  * Save/load emulator and ROM paths to `user_settings.json`
* **No step tracking** - steps happen in emulator and can't be monitored
* Monitoring the `status.txt` file for state changes
* Raising a system notification or sound when shiny is detected
* Logging attempts, failed casts, encounters
* Optional extra features:
  * Configurable settings (e.g., delay times)
  * Display a small UI with stats
  * Allow selecting different pokemon species to check for
## Final Notes for Copilot

You will assist in generating both Lua scripts and C# controller code. Always assume:

* DeSmuME's Lua API is available (but verify correct function signatures)
* Memory addresses for Pokémon Pearl (US) are documented but may need adjustment for other versions
* **Actual Implementation Status**:
  * ✅ Complete Lua automation with command monitoring
  * ✅ Windows Forms C# controller with UI panels
  * ✅ Bidirectional communication via text files
  * ✅ Auto-savestate creation on START
  * ✅ Relative paths for portability
  * ✅ Settings persistence
  * ✅ Single "Start Hunting" workflow (merged start buttons)

Use clear, well-explained code and prioritize stability and correctness over cleverness.

## Key Learnings from Implementation

* DeSmuME's savestate API uses direct slot numbers, not a `saveslot()` wrapper function
* File-based IPC with simple text format works reliably for command/status exchange
* Single-button workflow (auto-creating savestate) provides better UX than multi-step process
* Step tracking in UI is impractical since critical steps happen inside emulator
* lua51.dll must be distributed with the Lua script for DeSmuME compatibilitydeterministic.
* Communication between C# and Lua should be **simple and robust**: a single shared text file is ideal.
* Keep all code modular so Copilot can generate and improve specific functions easily.

---

## What Copilot Should Prioritize

* Clean, modular Lua code for memory reading and button emulation
* Accurate shiny detection via memory values
* A stable, lightweight C# supervisor that monitors status and notifies the user
* Reusable helper functions and clear naming
* Comments that explain memory offsets and DS logic

---

## Final Notes for Copilot

You will assist in generating both Lua scripts and C# controller code. Always assume:

* DeSmuME’s Lua API is available
* Memory addresses for Pokémon Pearl may need to be filled in or updated

Use clear, well-explained code and prioritize stability and correctness over cleverness.
