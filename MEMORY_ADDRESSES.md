# Memory Address Reference - Pokémon Pearl (US)

This document contains memory addresses and offsets used in the automation script.

## Important Notes

- These addresses are for **Pokémon Pearl (US version)**
- Memory addresses can vary between ROM versions (US/EU/JP)
- Some addresses may shift with different game states
- Always verify addresses with your specific ROM

---

## Main Memory Addresses

### Game State Addresses

| Address | Size | Description | Notes |
|---------|------|-------------|-------|
| `0x021C4D84` | 1 byte | Fishing State | 0 = not fishing, 1 = rod cast, 2 = bite detected |
| `0x021C6094` | 1 byte | Battle Flag | 0 = no battle, 1 = in battle |
| `0x0226AAEC` | Structure | Encounter Data | Base address for wild encounter Pokémon data |
| `0x022349B4` | Structure | Party Pokémon 1 | Base address for first Pokémon in party |

---

## Encounter Data Structure

Base address: `0x0226AAEC` (or whatever `ENCOUNTER_SLOT` points to)

### Offsets from Base

| Offset | Size | Description |
|--------|------|-------------|
| `+0x00` | 2 bytes | Species ID (e.g., 129 = Magikarp) |
| `+0x04` | 4 bytes | Personality ID (PID) |
| `+0x08` | 2 bytes | HP (individual value) |
| `+0x0A` | 2 bytes | Attack IV |
| `+0x0C` | 2 bytes | Defense IV |
| `+0x0E` | 2 bytes | Special Attack IV |
| `+0x10` | 2 bytes | Special Defense IV |
| `+0x12` | 2 bytes | Speed IV |

---

## Pokémon Species IDs

Common species you might encounter while fishing:

| Species | ID (Decimal) | ID (Hex) |
|---------|--------------|----------|
| Magikarp | 129 | 0x0081 |
| Gyarados | 130 | 0x0082 |
| Goldeen | 118 | 0x0076 |
| Seaking | 119 | 0x0077 |
| Barboach | 339 | 0x0153 |
| Whiscash | 340 | 0x0154 |

---

## Trainer Data Structure

Base address: `0x022349B4` (party Pokémon 1 area, but trainer data nearby)

### Trainer ID Offsets

| Offset | Size | Description |
|--------|------|-------------|
| `+0x0C` | 2 bytes | Trainer ID (TID) |
| `+0x0E` | 2 bytes | Secret ID (SID) |

**Note:** These offsets are approximate. The exact location of TID/SID may vary.

---

## Shiny Calculation

### Gen 4 Shiny Formula

A Pokémon is shiny if:
```
(TID ⊕ SID ⊕ PID_high ⊕ PID_low) < 8
```

Where:
- `TID` = Trainer ID (16-bit)
- `SID` = Secret ID (16-bit)
- `PID_high` = Upper 16 bits of PID
- `PID_low` = Lower 16 bits of PID
- `⊕` = XOR operation

### Example Calculation

```lua
local pid = 0x12345678
local tid = 12345
local sid = 54321

local pidLow = pid % 0x10000           -- 0x5678
local pidHigh = math.floor(pid / 0x10000)  -- 0x1234

local xorResult = bit.bxor(bit.bxor(bit.bxor(tid, sid), pidHigh), pidLow)

if xorResult < 8 then
    -- Pokémon is shiny!
end
```

---

## Button Input Values

Used with `joypad.set()`:

| Button | Key Name |
|--------|----------|
| A | "A" |
| B | "B" |
| X | "X" |
| Y | "Y" |
| Start | "start" |
| Select | "select" |
| Up | "up" |
| Down | "down" |
| Left | "left" |
| Right | "right" |
| L | "L" |
| R | "R" |

---

## Finding Memory Addresses

If the default addresses don't work for your ROM:

### Method 1: Using DeSmuME's Memory Viewer

1. Open DeSmuME's memory viewer: `Tools → View Memory`
2. Look for known values (like your Pokémon's species, level, etc.)
3. Use the search function to narrow down addresses
4. Cross-reference with known Pokémon data structures

### Method 2: Using Cheat Engine

1. Attach Cheat Engine to DeSmuME process
2. Search for known values (species ID, stats, etc.)
3. Change the value in-game and do a "next scan"
4. Repeat until you find the address
5. Convert address to DeSmuME format

### Method 3: Using PokeFinder

1. PokeFinder tool can help identify memory structures
2. Useful for verifying PID, IVs, and shiny calculations
3. Can generate test PIDs to verify your shiny detection

---

## ROM Version Differences

| Version | Region | Notes |
|---------|--------|-------|
| US | Americas | Most common, addresses in this document |
| EU | Europe | Slightly different address offsets |
| JP | Japan | Significant differences, requires remapping |

---

## Debugging Tips

### Verify Fishing State

```lua
-- Add this to your Lua script to debug
while true do
    local fishState = memory.readbyte(0x021C4D84)
    print("Fishing State: " .. fishState)
    emu.frameadvance()
end
```

### Verify Species Reading

```lua
-- Cast rod, trigger encounter, then check:
local species = memory.readword(0x0226AAEC)
print("Encountered species ID: " .. species)
```

### Verify PID Reading

```lua
local pid = memory.readdword(0x0226AAEC + 0x04)
print(string.format("PID: %08X", pid))
```

---

## Advanced: Memory Mapping

Pokémon data in Gen 4 is organized in structures:

```
Pokémon Structure (0x88 bytes total)
├── PID (0x00, 4 bytes)
├── Unused (0x04, 2 bytes)
├── Checksum (0x06, 2 bytes)
├── Species (0x08, 2 bytes)
├── Item Held (0x0A, 2 bytes)
├── OT ID (0x0C, 4 bytes)
├── Exp (0x10, 4 bytes)
├── Friendship (0x14, 1 byte)
├── Ability (0x15, 1 byte)
└── ... (more data)
```

The structure is **encrypted** in the party but may be different in encounter memory.

---

## References

- [Project Pokemon: Gen 4 Save Structure](https://projectpokemon.org/docs/gen-4/)
- [Bulbapedia: Personality Value](https://bulbapedia.bulbagarden.net/wiki/Personality_value)
- [Smogon: RNG Abuse Guide](https://www.smogon.com/ingame/rng/)

---

## Contributing

If you find correct addresses for other ROM versions, please document them here!
