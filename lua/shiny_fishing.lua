
local MEMORY = {
    FISHING_STATE = 0x021C4D84,  -- Fishing state indicator (0 = not fishing, 1 = rod cast, 2 = bite)
    BATTLE_FLAG = 0x021C6094,     -- Battle indicator (0 = no battle, 1 = in battle)
    ENCOUNTER_SLOT = 0x0226AAEC,  -- Current encounter data structure
    PARTY_POKEMON_1 = 0x022349B4, -- First Pokémon in party (for TID/SID)
    
    -- Encountered Pokémon data offsets (relative to encounter slot)
    SPECIES_OFFSET = 0x00,        -- Species ID (Magikarp = 129)
    PID_OFFSET = 0x04,            -- Personality ID (4 bytes)
}

local MAGIKARP_ID = 129
local SAVESTATE_SLOT = 1

-- Get script directory and build relative path to shared folder
local scriptPath = debug.getinfo(1, "S").source:sub(2)
local scriptDir = scriptPath:match("(.*/)")
if not scriptDir then
    scriptDir = scriptPath:match("(.*\\)")
end
if not scriptDir then
    scriptDir = ""
end
local STATUS_FILE = scriptDir .. "..\\shared\\status.txt"

-- Statistics
local stats = {
    totalAttempts = 0,
    totalEncounters = 0,
    nonMagikarpEncounters = 0,
    shinyFound = false
}

-- =====================================================
-- Memory Reading Helper Functions
-- =====================================================

-- Read a 1-byte value from memory
function readByte(address)
    return memory.readbyte(address)
end

-- Read a 2-byte value from memory (little endian)
function readWord(address)
    return memory.readword(address)
end

-- Read a 4-byte value from memory (little endian)
function readDword(address)
    return memory.readdword(address)
end

-- =====================================================
-- Game State Detection
-- =====================================================

-- Check if currently fishing
function isFishing()
    local fishState = readByte(MEMORY.FISHING_STATE)
    return fishState > 0
end

-- Check if a bite occurred
function hasBite()
    local fishState = readByte(MEMORY.FISHING_STATE)
    return fishState == 2
end

-- Check if in battle
function isInBattle()
    local battleFlag = readByte(MEMORY.BATTLE_FLAG)
    return battleFlag == 1
end

-- =====================================================
-- Encounter Analysis
-- =====================================================

-- Get the species ID of the encountered Pokémon
function getEncounteredSpecies()
    local speciesAddr = MEMORY.ENCOUNTER_SLOT + MEMORY.SPECIES_OFFSET
    return readWord(speciesAddr)
end

-- Get the PID of the encountered Pokémon
function getEncounteredPID()
    local pidAddr = MEMORY.ENCOUNTER_SLOT + MEMORY.PID_OFFSET
    return readDword(pidAddr)
end

-- Get trainer ID and Secret ID from party Pokémon data
function getTrainerIDs()
    -- TID and SID are stored in the game's trainer data structure
    -- This is a simplified placeholder - actual addresses need verification
    local tid = readWord(MEMORY.PARTY_POKEMON_1 + 0x0C)
    local sid = readWord(MEMORY.PARTY_POKEMON_1 + 0x0E)
    return tid, sid
end

-- Calculate if a Pokémon is shiny using Gen 4 algorithm
function isShiny(pid, tid, sid)
    -- Extract high and low 16-bit values from PID
    local pidLow = pid % 0x10000
    local pidHigh = math.floor(pid / 0x10000)
    
    -- Shiny calculation: (TID ⊕ SID ⊕ PID_high ⊕ PID_low) < 8
    local xorResult = bit.bxor(bit.bxor(bit.bxor(tid, sid), pidHigh), pidLow)
    
    return xorResult < 8
end

-- =====================================================
-- Button Input Functions
-- =====================================================

-- Press a button for one frame
function pressButton(button)
    joypad.set(1, {[button] = true})
    emu.frameadvance()
    joypad.set(1, {[button] = false})
end

-- Wait for a number of frames
function waitFrames(frames)
    for i = 1, frames do
        emu.frameadvance()
    end
end

-- =====================================================
-- Status File Communication
-- =====================================================

-- Write status to the communication file
function writeStatus(status, details)
    local file = io.open(STATUS_FILE, "w")
    if file then
        file:write(string.format("STATUS=%s\n", status))
        file:write(string.format("ATTEMPTS=%d\n", stats.totalAttempts))
        file:write(string.format("ENCOUNTERS=%d\n", stats.totalEncounters))
        file:write(string.format("NON_MAGIKARP=%d\n", stats.nonMagikarpEncounters))
        if details then
            file:write(string.format("DETAILS=%s\n", details))
        end
        file:close()
    end
end

-- =====================================================
-- Savestate Management
-- =====================================================

-- Reload the savestate to reset
function resetToSavestate()
    savestate.load(savestate.saveslot(SAVESTATE_SLOT))
    waitFrames(30)  -- Wait for state to stabilize
end

-- =====================================================
-- Main Automation Logic
-- =====================================================

-- Cast the fishing rod
function castRod()
    writeStatus("CASTING", "Casting fishing rod...")
    
    -- Press A to use rod (adjust timing as needed)
    pressButton("A")
    waitFrames(60)  -- Wait for rod cast animation
    
    stats.totalAttempts = stats.totalAttempts + 1
end

-- Wait for a bite with timeout
function waitForBite(maxWaitFrames)
    local framesWaited = 0
    
    while framesWaited < maxWaitFrames do
        if hasBite() then
            return true
        end
        emu.frameadvance()
        framesWaited = framesWaited + 1
    end
    
    return false  -- Timeout, no bite
end

-- Trigger the encounter
function triggerEncounter()
    writeStatus("ENCOUNTER", "Bite detected! Triggering encounter...")
    
    -- Press A at the right time to hook the Pokémon
    -- Timing is critical - may need adjustment
    waitFrames(10)
    pressButton("A")
    waitFrames(180)  -- Wait for battle to start
end

-- Check the encountered Pokémon
function checkEncounter()
    stats.totalEncounters = stats.totalEncounters + 1
    
    -- Wait for battle data to load
    waitFrames(120)
    
    -- Check species
    local species = getEncounteredSpecies()
    writeStatus("CHECKING", string.format("Checking species... (ID: %d)", species))
    
    if species ~= MAGIKARP_ID then
        stats.nonMagikarpEncounters = stats.nonMagikarpEncounters + 1
        writeStatus("NOT_MAGIKARP", string.format("Species %d is not Magikarp. Resetting...", species))
        return false
    end
    
    -- It's a Magikarp! Check if shiny
    local pid = getEncounteredPID()
    local tid, sid = getTrainerIDs()
    
    writeStatus("CHECKING", string.format("Magikarp found! Checking shiny... (PID: %08X)", pid))
    
    if isShiny(pid, tid, sid) then
        writeStatus("SHINY_FOUND", string.format("SHINY MAGIKARP FOUND! PID: %08X", pid))
        stats.shinyFound = true
        return true
    else
        writeStatus("NOT_SHINY", "Not shiny. Resetting...")
        return false
    end
end

-- Main automation loop
function automationLoop()
    writeStatus("STARTING", "Automation starting...")
    
    while not stats.shinyFound do
        -- Cast the rod
        castRod()
        
        -- Wait for a bite (timeout after 10 seconds = ~600 frames at 60fps)
        local gotBite = waitForBite(600)
        
        if not gotBite then
            writeStatus("NO_BITE", "No bite. Recasting...")
            resetToSavestate()
        else
            -- Trigger the encounter
            triggerEncounter()
            
            -- Check if it's a shiny Magikarp
            local isShinyMagikarp = checkEncounter()
            
            if not isShinyMagikarp then
                -- Reset and try again
                resetToSavestate()
            else
                -- SHINY FOUND! Pause execution
                writeStatus("PAUSED", "SHINY FOUND! Automation paused.")
                return  -- Exit the loop
            end
        end
        
        -- Small delay between attempts
        waitFrames(30)
    end
end

-- =====================================================
-- Main Entry Point
-- =====================================================

-- Initialize
function initialize()
    print("===========================================")
    print("Pokémon Pearl Shiny Magikarp Fishing Bot")
    print("===========================================")
    print("Make sure you:")
    print("1. Are standing at a fishing spot")
    print("2. Have saved the game")
    print("3. Have created a savestate in slot 1")
    print("4. Have the fishing rod selected")
    print("===========================================")
    
    writeStatus("INITIALIZED", "Lua script loaded and ready")
end

-- Run the automation
initialize()

-- Uncomment the line below to start automation automatically
-- automationLoop()

-- For manual control, you can call automationLoop() from the Lua console
print("Call automationLoop() to start automation")
