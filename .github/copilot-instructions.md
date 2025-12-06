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
* **C# only supervises**, logs attempts, and alerts user on shiny.
* Avoid audio or screen detection entirely if using Lua.
* Keep Lua script simple and ensure it runs safely at high speed inside the emulator.

---

## **High-Level Workflow**

1. User will start DeSmuME with Pokémon Pearl loaded and manually navigate to a fishing spot.
2. Load a prepared **savestate** right before casting.
3. Start the automation:

   * Lua casts rod
   * Reads memory to check:

     * If no bite → recast
     * If bite → Lua handles timing and triggers encounter
     * Reads encounter species
     * If not Magikarp → reset
     * Reads PID / shiny flag
     * If shiny → write `SHINY_FOUND` to status file and pause
     * Else → reset
4. External program watches the status file and notifies the user when shiny is found.

---

## **File Structure Recommendations**

```
project-root/
│
├── lua/
│   └── shiny_fishing.lua   (main automation logic)
├── controller/
│   └── ShinyAutomation.cs   (C# desktop supervisor)
│
└── shared/
    ├── status.txt           (Lua → C# communication)
    └── config.json          (optional user settings)
```

---

## **Lua Script Requirements**

Copilot should assist with:

* Reading memory:

  * Fishing state
  * Species ID
  * Pokémon data structure
  * PID, TID/SID if needed
* Implementing shiny check (Gen 4 formula):

  ```
  shiny = ((TID ⊕ SID ⊕ PID_high ⊕ PID_low) < 8)
  ```
* Emulating button presses via `emu:writeKeyMemory()` or `emu.keypress()`
* Reloading savestate: `savestate.loadslot(1)`
* Writing output signals to `status.txt` using `io.open`

---

## **C# Controller Requirements**

Copilot should assist with:

* Monitoring the `status.txt` file for state changes
* Raising a system notification or sound when shiny is detected
* Logging attempts, failed casts, encounters
* Optional extra features:
  * Configurable settings (e.g., delay times)
  * Display a small UI with stats
  * Allow selecting different pokemon species to check for
  * Separate mode for shiny hunting in grass

---

## Important Implementation Notes

* The entire logic loop occurs **inside Lua for maximum speed**; the C# app should *never* attempt to control the game directly.
* Lua must handle timing precisely since Pokémon Pearl’s fishing and encounter logic is deterministic.
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
