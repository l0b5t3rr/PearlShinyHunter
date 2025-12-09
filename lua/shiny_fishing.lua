
local MEMORY = {
    FISHING_STATE = 0x021D5E03,  -- Fishing state indicator (0 = not fishing, 1 = rod cast, 2 = bite)
    BATTLE_FLAG = 0x021C6094,     -- Battle indicator (0 = no battle, 1 = in battle)
    BITE_FLAG = 0x021D5E03,       -- Bite detection flag (0 = no bite, 1 = bite "!" appears) - Diamond/Pearl US
    ENCOUNTER_SLOT = 0x0226AAEC,  -- Current encounter data structure
    PARTY_POKEMON_1 = 0x022349B4, -- First Pokémon in party (for TID/SID)
    
    -- Encountered Pokémon data offsets (relative to encounter slot)
    SPECIES_OFFSET = 0x00,        -- Species ID (Magikarp = 129)
    PID_OFFSET = 0x04,            -- Personality ID (4 bytes)
}

local MAGIKARP_ID = 129
local SAVESTATE_SLOT = 1

-- =====================================================
-- Screen Detection Configuration
-- =====================================================

-- Exclamation mark detection zones (DS screens are 256x192 each)
-- The "!" appears in the center-bottom area of the top screen during fishing
local SCREEN_DETECT = {
    -- Sample points around where the "!" appears (adjust based on testing)
    EXCLAIM_POINTS = {
        {x = 128, y = 140},  -- Center point
        {x = 126, y = 138},  -- Top-left
        {x = 130, y = 138},  -- Top-right
        {x = 126, y = 142},  -- Bottom-left
        {x = 130, y = 142},  -- Bottom-right
    },
    
    -- Color threshold for exclamation mark detection
    -- The "!" is typically white/bright yellow (high RGB values)
    BRIGHTNESS_THRESHOLD = 200,  -- Minimum brightness (0-255)
    MIN_BRIGHT_PIXELS = 3,       -- Minimum number of bright pixels to confirm "!"
}

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
local LOG_FILE = scriptDir .. "..\\shared\\log_" .. os.date("%Y%m%d") .. ".txt"

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
-- Screen Detection Functions
-- =====================================================

-- Screen detection functions removed - DeSmuME doesn't support emu.getscreenpixel()

-- =====================================================
-- Game State Detection
-- =====================================================

-- Check if currently fishing
function isFishing()
    local fishState = readByte(MEMORY.FISHING_STATE)
    return fishState > 0
end

-- Check if a bite occurred (fishing state changes from previous value)
-- We need to detect when the value CHANGES, not just when it's non-zero
function hasBite(previousState)
    local fishState = readByte(MEMORY.FISHING_STATE)
    -- Bite occurs when state changes AND is non-zero
    -- This filters out the initial cast (previousState would be 0)
    return fishState ~= 0 and fishState ~= previousState and previousState ~= 0
end

-- No reliable battle flag available - use timing-based detection instead

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

-- Click on the touch screen at specific coordinates
function touchScreen(x, y, frames)
    frames = frames or 1
    for i = 1, frames do
        stylus.set({touch = true, x = x, y = y})
        emu.frameadvance()
    end
    stylus.set({touch = false})
    emu.frameadvance()
end

-- Click the Run button in battle (bottom center of touch screen)
function clickRunButton()
    print("Clicking Run button on touch screen...")
    writeLog("Clicking Run button at coordinates (128, 170)")
    
    -- Run button is in bottom center of screen
    -- DS screen is 256x192, so center is 128
    -- Bottom area is around y=170-180
    -- Click slightly above center of button to ensure hit
    touchScreen(128, 170, 3)  -- Hold for 3 frames
    waitFrames(10)
    
    -- Click again to confirm if needed
    touchScreen(128, 170, 3)
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

-- Write to activity log (appends) - matches C# format
function writeLog(message)
    local file = io.open(LOG_FILE, "a")
    if file then
        file:write(string.format("[%s] %s\n", os.date("%Y-%m-%d %H:%M:%S"), message))
        file:close()
    end
end

-- =====================================================
-- No savestate reloading - natural RNG advancement
-- =====================================================
-- RNG advances naturally through game actions (fleeing, dismissing messages, etc.)

-- =====================================================
-- Main Automation Logic
-- =====================================================

-- Dismiss the "nothing seems to be biting" message
function dismissNoBiteMessage()
    print("Dismissing 'nothing seems to be biting' message...")
    writeStatus("NO_BITE_MSG", "Dismissing no bite message")
    writeLog("Dismissing no bite message")
    
    -- Press A multiple times to get through the dialog
    for i = 1, 5 do
        pressButton("A")
        waitFrames(10)
    end
    
    -- Extra wait to ensure we're back to overworld
    waitFrames(30)
end

-- Flee from battle using touch screen to click Run button
function fleeFromBattle()
    print("Fleeing from battle...")
    writeStatus("FLEEING", "Fleeing from non-shiny encounter")
    writeLog("Fleeing from battle")
    
    -- Wait for battle to FULLY load (can take ~12 seconds)
    print("Waiting for battle to fully load...")
    writeLog("Waiting 12 seconds for battle to fully load")
    waitFrames(720)  -- 12 seconds at 60fps
    
    -- Click the Run button directly on touch screen
    clickRunButton()
    waitFrames(30)
    
    -- Click again to confirm/ensure it registered
    clickRunButton()
    waitFrames(30)
    
    -- Wait for flee animation and return to overworld
    print("Waiting for flee animation...")
    waitFrames(180)
    
    -- Press A a few more times to clear any remaining text
    for i = 1, 5 do
        pressButton("A")
        waitFrames(10)
    end
    
    -- Wait additional time to ensure fully back in overworld before next cast
    print("Waiting to ensure fully returned to overworld...")
    waitFrames(120)  -- Extra 2 seconds
    
    print("Returned to overworld")
    writeLog("Flee complete, back to overworld")
end

-- Cast the fishing rod
function castRod()
    print("Casting fishing rod (attempt #" .. (stats.totalAttempts + 1) .. ")...")
    writeStatus("CASTING", "Casting fishing rod...")
    
    -- Press Y multiple times to ensure it registers (rod from registered items)
    pressButton("Y")
    waitFrames(10)
    pressButton("Y")
    waitFrames(90)  -- Wait for rod cast animation to complete
    
    stats.totalAttempts = stats.totalAttempts + 1
end

-- Wait for bite using fishing state and press A immediately when bite window opens
function waitForBite()
    print("Waiting for bite (monitoring fishing state changes)...")
    writeStatus("FISHING", "Waiting for bite...")
    
    -- Track previous fishing state to detect changes
    local previousState = 0
    
    -- Wait for initial rod cast state to stabilize
    waitFrames(30)
    previousState = readByte(MEMORY.FISHING_STATE)
    print("Initial fishing state after cast: " .. previousState)
    
    -- Now monitor for state CHANGES (indicating bite)
    while true do
        local currentState = readByte(MEMORY.FISHING_STATE)
        
        -- Log any state change for debugging
        if currentState ~= previousState then
            print("Fishing state changed: " .. previousState .. " -> " .. currentState)
            writeLog("Fishing state changed: " .. previousState .. " -> " .. currentState)
            
            -- Any change from the initial state indicates bite
            print(">>> BITE DETECTED! First state change detected")
            writeStatus("BITE", "Bite detected! Reeling in...")
            writeLog("Bite detected - first state change from " .. previousState .. " to " .. currentState)
            
            -- Wait 5 frames after detecting the change
            waitFrames(5)
            
            -- Press A multiple times to ensure it registers (same pattern as castRod)
            print(">>> PRESSING A NOW...")
            writeLog("Pressing A button")
            pressButton("A")
            waitFrames(2)
            pressButton("A")
            waitFrames(2)
            pressButton("A")
            
            -- Wait for result message to appear (either "hooked" or "nothing biting")
            print(">>> Waiting for result message...")
            writeLog("Waiting for result message")
            waitFrames(60)
            
            -- Dismiss the dialog by pressing A multiple times
            -- This works for both "hooked" and "nothing biting" messages
            print(">>> Dismissing dialog...")
            writeLog("Dismissing dialog message")
            for i = 1, 5 do
                pressButton("A")
                waitFrames(10)
            end
            
            -- Assume battle is starting after dismissing dialog
            -- We'll know for sure based on whether encounter check works
            print(">>> Dialog dismissed, assuming battle is starting...")
            writeLog("Dialog dismissed - proceeding to encounter check")
            waitFrames(30)
            return true  -- Always return true, let the encounter logic handle it
        end
        
        -- Update previous state
        previousState = currentState
        emu.frameadvance()
    end
end

-- Detect if battle is starting with single immediate check
-- "Nothing bit" = fishing state returns to 0 immediately
-- Battle starting = fishing state still non-zero
function waitForBattleOrNoBite()
    print(">>> Checking if battle is starting...")
    writeStatus("CHECKING", "Checking for battle vs no-bite...")
    writeLog("Checking fishing state to detect battle vs no-bite")
    
    -- Wait a moment for state to settle after dialog dismissal
    waitFrames(30)
    
    local fishState = readByte(MEMORY.FISHING_STATE)
    print(string.format("Fishing state check: %d", fishState))
    
    -- If fishing state is 0, we're back in overworld (nothing bit)
    if fishState == 0 then
        print(">>> Fishing state = 0, no battle (nothing bit)")
        writeLog("Fishing state = 0 - no battle occurred")
        return false
    end
    
    -- Fishing state still non-zero, assume battle is loading
    print(">>> Fishing state non-zero - battle assumed, waiting to fully load...")
    writeLog(string.format("Fishing state = %d - battle loading", fishState))
    writeStatus("BATTLE_LOADING", "Battle detected, waiting to fully load...")
    
    -- Wait for battle to fully load (12 seconds = 720 frames)
    waitFrames(720)
    
    return true  -- Battle started
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
-- Command System (Bidirectional Communication)
-- =====================================================

local COMMAND_FILE = scriptDir .. "..\\shared\\command.txt"
local lastCommand = ""
local isPaused = false

-- Read command from C# controller
function readCommand()
    local file = io.open(COMMAND_FILE, "r")
    if file then
        local command = file:read("*line")
        file:close()
        return command or ""
    end
    return ""
end

-- Clear command file
function clearCommand()
    local file = io.open(COMMAND_FILE, "w")
    if file then
        file:write("")
        file:close()
    end
end

-- Check for commands from C# controller
function processCommands()
    local command = readCommand()
    
    if command ~= "" and command ~= lastCommand then
        lastCommand = command
        
        if command == "START" then
            clearCommand()
            writeStatus("STARTING", "Automation starting via controller command...")
            return "START"
        elseif command == "PAUSE" then
            clearCommand()
            isPaused = true
            writeStatus("PAUSED", "Automation paused by user")
            return "PAUSE"
        elseif command == "RESUME" then
            clearCommand()
            isPaused = false
            writeStatus("RESUMING", "Automation resumed")
            return "RESUME"
        elseif command == "STOP" then
            clearCommand()
            writeStatus("STOPPED", "Automation stopped by user")
            return "STOP"
        end
    end
    
    return nil
end

-- Modified automation loop with pause support
function automationLoopWithPause()
    -- Set emulator to 400% speed for faster automation
    emu.speedmode("turbo")
    print("Emulator speed set to 400% (turbo mode)")
    writeLog("Emulator speed set to 400% for automation")
    
    writeStatus("STARTING", "Starting automation (natural RNG progression)...")
    writeLog("Starting automation - will flee from non-shiny battles to advance RNG naturally")
    
    while not stats.shinyFound do
        -- Check for pause/stop commands
        local cmd = processCommands()
        if cmd == "STOP" then
            emu.speedmode("normal")
            print("Automation stopped - speed reset to normal")
            writeLog("Automation stopped - speed reset to normal")
            return  -- Exit completely
        end
        
        -- If paused, wait
        while isPaused do
            emu.frameadvance()
            local resumeCmd = processCommands()
            if resumeCmd == "RESUME" then
                break
            elseif resumeCmd == "STOP" then
                emu.speedmode("normal")
                print("Automation stopped - speed reset to normal")
                return
            end
        end
        
        -- Cast the rod
        castRod()
        
        -- Wait for bite using fishing state detection
        waitForBite()  -- Always returns true after detecting state change
        
        -- Now check if we're actually entering battle or if nothing bit
        local gotBattle = waitForBattleOrNoBite()
        
        if not gotBattle then
            writeStatus("NO_BITE", "Nothing bit. Dismissing message and trying again...")
            print("No battle detected, dismissing message...")
            dismissNoBiteMessage()
        else
            -- We're in battle! Check if it's a shiny Magikarp
            local isShinyMagikarp = checkEncounter()
            
            if not isShinyMagikarp then
                -- Flee from battle to advance RNG naturally
                fleeFromBattle()
            else
                -- SHINY FOUND! Reset speed and pause execution
                emu.speedmode("normal")
                print("SHINY FOUND! Emulator speed reset to normal")
                writeLog("Shiny found! Speed reset to normal")
                writeStatus("PAUSED", "SHINY FOUND! Automation paused.")
                return  -- Exit the loop
            end
        end
        
        -- Small delay between attempts
        waitFrames(20)
    end
end

-- Command monitoring loop (runs continuously)
function commandMonitorLoop()
    while true do
        local cmd = processCommands()
        
        if cmd == "START" then
            -- Start the automation
            automationLoopWithPause()
            
            -- After automation ends, reset speed and go back to monitoring
            emu.speedmode("normal")
            if not stats.shinyFound then
                writeStatus("READY", "Ready for next command")
            end
        end
        
        emu.frameadvance()
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
    print("Script is now monitoring for commands from the UI")
    print("Click 'Start Automation' in the controller app to begin")
    print("===========================================")
    
    writeStatus("READY", "Lua script loaded. Waiting for START command from UI")
    clearCommand()  -- Clear any old commands
end

-- Run the automation
initialize()

-- Start command monitoring loop
commandMonitorLoop()

-- Note: You can still manually call automationLoop() if needed for testing
