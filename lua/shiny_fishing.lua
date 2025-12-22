read32Bit = memory.readdwordunsigned
read16Bit = memory.readword
read8Bit = memory.readbyte
rshift = bit.rshift
lshift = bit.lshift
band = bit.band
bxor = bit.bxor
bor = bit.bor
floor = math.floor

readByte = read8Bit
readWord = read16Bit
readDword = read32Bit

-- Memory addresses used by automation/fishing checks
local MEMORY = {
      FISHING_STATE = 0x021D5E03
}

-- Performance/config defaults
local PERF = {
      MINIMAL_UI_IN_TURBO = true,
      SUPPRESS_NOT_SHINY_WRITE = false,
      DISABLE_GUI = true,
      TURBO_SPEED = "turbo",
      COMMAND_POLL_INTERVAL = 8,
}

local JUMP_DATA = {
 {0x41C64E6D, 0x6073}, {0xC2A29A69, 0xE97E7B6A}, {0xEE067F11, 0x31B0DDE4}, {0xCFDDDF21, 0x67DBB608},
 {0x5F748241, 0xCBA72510}, {0x8B2E1481, 0x1D29AE20}, {0x76006901, 0xBA84EC40}, {0x1711D201, 0x79F01880},
 {0xBE67A401, 0x8793100}, {0xDDDF4801, 0x6B566200}, {0x3FFE9001, 0x803CC400}, {0x90FD2001, 0xA6B98800},
 {0x65FA4001, 0xE6731000}, {0xDBF48001, 0x30E62000}, {0xF7E90001, 0xF1CC4000}, {0xEFD20001, 0x23988000},
 {0xDFA40001, 0x47310000}, {0xBF480001, 0x8E620000}, {0x7E900001, 0x1CC40000}, {0xFD200001, 0x39880000},
 {0xFA400001, 0x73100000}, {0xF4800001, 0xE6200000}, {0xE9000001, 0xCC400000}, {0xD2000001, 0x98800000},
 {0xA4000001, 0x31000000}, {0x48000001, 0x62000000}, {0x90000001, 0xC4000000}, {0x20000001, 0x88000000},
 {0x40000001, 0x10000000}, {0x80000001, 0x20000000}, {0x1, 0x40000000}, {0x1, 0x80000000}}

local natureNamesList = {
 "Hardy", "Lonely", "Brave", "Adamant", "Naughty",
 "Bold", "Docile", "Relaxed", "Impish", "Lax",
 "Timid", "Hasty", "Serious", "Jolly", "Naive",
 "Modest", "Mild", "Quiet", "Bashful", "Rash",
 "Calm", "Gentle", "Sassy", "Careful", "Quirky"}

local HPTypeNamesList = {
 "Fighting", "Flying", "Poison", "Ground",
 "Rock", "Bug", "Ghost", "Steel",
 "Fire", "Water", "Grass", "Electric",
 "Psychic", "Ice", "Dragon", "Dark"}

local statusConditionNamesList = {"None", "SLP", "PSN", "BRN", "FRZ", "PAR", "PSN"}

local mapAttributeData = {
 0, 0, 2, 2, 0, 2, 2, 0, 2, 0, 0, 2, 0, 0, 0, 0,
 3, 3, 3, 1, 1, 3, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
 0, 0, 3, 0, 2, 2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 2, 1, 0, 0, 0, 2, 1, 0, 0, 2, 1, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

emu.reset()

local gameCode = read32Bit(0x2FFFE0C)
local gameVersionCode = band(gameCode, 0xFFFFFF)
local gameVersion = ""
local gameLanguageCode = rshift(gameCode, 24)
local gameLanguage = ""
local wrongGameVersion = true

if gameVersionCode == 0x414441 then  -- Check game version
 gameVersion = "Diamond"
elseif gameVersionCode == 0x415041 then
 gameVersion = "Pearl"
elseif gameVersionCode == 0x555043 then
 gameVersion = "Platinum"
elseif gameVersionCode == 0x475049 then
 gameVersion = "SoulSilver"
elseif gameVersionCode == 0x4B5049 then
 gameVersion = "HeartGold"
end

function getGameAddrOffset(offset)
 return gameVersion == "Pearl" and offset or 0
end

local mtIndexAddr, pidPointerAddr, delayAddr, currentSeedAddr, mtSeedAddr, trainerIDsPointerAddr, tempCurrentSeedDuringBattleAddr
local koreanOffset = 0

if gameLanguageCode == 0x44 then  -- Check game language and set addresses
 gameLanguage = "GER"
 mtIndexAddr = 0x2105CE8 + getGameAddrOffset(0x8)
 pidPointerAddr = 0x21070EC
 delayAddr = 0x21C4A24
 currentSeedAddr = 0x21C4E88
 mtSeedAddr = 0x21C4E8C
 trainerIDsPointerAddr = 0x21C5B08
 tempCurrentSeedDuringBattleAddr = 0x27E3A3C
elseif gameLanguageCode == 0x45 then
 gameLanguage = "EUR/USA"
 mtIndexAddr = 0x2105BA8 + getGameAddrOffset(0x8)
 pidPointerAddr = 0x2106FAC
 delayAddr = 0x21C48E4
 currentSeedAddr = 0x21C4D48
 mtSeedAddr = 0x21C4D4C
 trainerIDsPointerAddr = 0x21C59C8
 tempCurrentSeedDuringBattleAddr = 0x27E3A3C
elseif gameLanguageCode == 0x46 then
 gameLanguage = "FRE"
 mtIndexAddr = 0x2105D28 + getGameAddrOffset(0x8)
 pidPointerAddr = 0x210712C
 delayAddr = 0x21C4A64
 currentSeedAddr = 0x21C4EC8
 mtSeedAddr = 0x21C4ECC
 trainerIDsPointerAddr = 0x21C5B48
 tempCurrentSeedDuringBattleAddr = 0x27E3A3C
elseif gameLanguageCode == 0x49 then
 gameLanguage = "ITA"
 mtIndexAddr = 0x2105C88 + getGameAddrOffset(0x8)
 pidPointerAddr = 0x210708C
 delayAddr = 0x21C49C4
 currentSeedAddr = 0x21C4E28
 mtSeedAddr = 0x21C4E2C
 trainerIDsPointerAddr = 0x21C5AA8
 tempCurrentSeedDuringBattleAddr = 0x27E3A3C
elseif gameLanguageCode == 0x4A then
 gameLanguage = "JPN"
 isBaseVersion = band(read8Bit(0x2FFFE6C), 0xF) == 0xC
 mtIndexAddr = (isBaseVersion and 0x2107464 or 0x21075A4) + getGameAddrOffset(0x8)
 pidPointerAddr = isBaseVersion and 0x2108804 or 0x2108944
 delayAddr = isBaseVersion and 0x21C6144 or 0x21C6284
 currentSeedAddr = isBaseVersion and 0x21C65A8 or 0x21C66E8
 mtSeedAddr = isBaseVersion and 0x21C65AC or 0x21C66EC
 trainerIDsPointerAddr = isBaseVersion and 0x21C7234 or 0x21C7374
 tempCurrentSeedDuringBattleAddr = 0x27E39F0
elseif gameLanguageCode == 0x4B then
 gameLanguage = "KOR"
 koreanOffset = 0x44
 mtIndexAddr = 0x21030A8 + getGameAddrOffset(0x8)
 pidPointerAddr = 0x21045AC
 delayAddr = 0x21C1EE4
 currentSeedAddr = 0x21C2348
 mtSeedAddr = 0x21C234C
 trainerIDsPointerAddr = 0x21C2FC8
 tempCurrentSeedDuringBattleAddr = 0x27E363C
elseif gameLanguageCode == 0x53 then
 gameLanguage = "SPA"
 mtIndexAddr = 0x2105D48 + getGameAddrOffset(0x8)
 pidPointerAddr = 0x210714C
 delayAddr = 0x21C4A84
 currentSeedAddr = 0x21C4EE8
 mtSeedAddr = 0x21C4EEC
 trainerIDsPointerAddr = 0x21C5B68
 tempCurrentSeedDuringBattleAddr = 0x27E3A3C
end

function printGameInfo()
 if gameVersion == "" then  -- Print game info
  print("Version: Unknown game")
 elseif gameVersion ~= "Diamond" and gameVersion ~= "Pearl" then
  print(string.format("Version: %s - Wrong game version! Use Diamond/Pearl instead\n", gameVersion))
 elseif gameLanguage == "" then
  print("Version: "..gameVersion)
  print("Language: Unknown language\n")
 else
  wrongGameVersion = false
  print("Version: "..gameVersion)
  print(string.format("Language: %s\n", gameLanguage))
 end
end

printGameInfo()

-- Minimal always-on UI: top bar for TID/SID and capture box
function setBackgroundBoxes()
      gui.box(0, 0, 254, 22, "#0000007F", "#0000007F") -- top bar
      gui.box(120, 40, 235, 75, "#0000007F", "#0000007F") -- capture box
end

local dateTime = {["month"] = 1, ["day"] = 1, ["year"] = 0, ["hour"] = 0, ["minute"] = 0, ["second"] = 0}

function setDateTime()
 local dateTimeAddr = 0x23FFDE8

 dateTime["year"] = string.format("%02X", read8Bit(dateTimeAddr))
 dateTime["month"] = string.format("%02X", read8Bit(dateTimeAddr + 0x1))
 dateTime["day"] = string.format("%02X", read8Bit(dateTimeAddr + 0x2))
 dateTime["hour"] = string.format("%02X", read8Bit(dateTimeAddr + 0x4) % 0x40)
 dateTime["minute"] = string.format("%02X", read8Bit(dateTimeAddr + 0x5))
 dateTime["second"] = string.format("%02X", read8Bit(dateTimeAddr + 0x6))
end

-- Removed mode/tab UI functions (always-on capture + TID/SID)

function buildSeedFromDelay(delay)
 local ab = ((dateTime["month"] * dateTime["day"]) + dateTime["minute"] + dateTime["second"]) % 0x100
 local cd = dateTime["hour"]
 local efgh = dateTime["year"] + delay

 return ((ab * 0x1000000) + (cd * 0x10000) + efgh) % 0x100000000
end

local prevMTSeed, initialSeed, tempCurrentSeed, mtCounter, hitDelay , hitDate, battleStartJumpFlag = 0, 0, 0, 0, 0, "2000/01/01\n00:00:00", false

function setInitialSeed(mtSeed, delay)
 if prevMTSeed ~= mtSeed and delay ~= 0 then
  prevMTSeed = mtSeed
  initialSeed = mtSeed
  tempCurrentSeed = mtSeed
  local mtSeedTest = buildSeedFromDelay(delay)
  local mtSeedTest2 = buildSeedFromDelay(delay - 1)
  local mtSeedTest3 = buildSeedFromDelay(delay - 2)
  local initilSeedGenerationFlag = mtSeed == mtSeedTest and 0 or mtSeed == mtSeedTest2 and 1 or
                                   mtSeed == mtSeedTest3 and 2 or nil

  if initilSeedGenerationFlag then
   print(string.format("Initial Seed: %08X", initialSeed))
   hitDelay = delay - initilSeedGenerationFlag
   hitDate = string.format("20%s/%s/%s\n%s:%s:%s", dateTime["year"], dateTime["month"], dateTime["day"],
                           dateTime["hour"], dateTime["minute"], dateTime["second"])
  end
 elseif delay == 0 then
  prevMTSeed = 0
  initialSeed = 0
  tempCurrentSeed = 0
  mtCounter = 0
  hitDelay = 0
  hitDate = "2000/01/01\n00:00:00"
  battleStartJumpFlag = false
 end
end

function LCRNG(s, mul, sum)
 local a = rshift(mul, 16) * (s % 0x10000) + rshift(s, 16) * (mul % 0x10000)
 local b = (mul % 0x10000) * (s % 0x10000) + (a % 0x10000) * 0x10000 + sum

 return b % 0x100000000
end

function LCRNGDistance(state0, state1)
 local mask = 1
 local dist = 0

 if state0 ~= state1 then
  for _, data in ipairs(JUMP_DATA) do
   local mult, add = unpack(data)

   if state0 == state1 then
    break
   end

   if band(bxor(state0, state1), mask) ~= 0 then
    state0 = LCRNG(state0, mult, add)
    dist = dist + mask
   end

   mask = lshift(mask, 1)
  end

  tempCurrentSeed = state1
 end

 return dist > 999 and dist - 0x100000000 or dist
end

local lastCurrentSeedBeforeBattle, advances = 0, 0

function shinyCheck(PID, trainerTID, trainerSID)
 trainerTID = trainerTID or nil
 trainerSID = trainerSID or nil

 if not trainerTID then
  trainerTID, trainerSID = getTrainerIDs()
 end

 local lowPID = band(PID, 0xFFFF)
 local highPID = rshift(PID, 16)
 local shinyTypeValue = bxor(bxor(trainerTID, trainerSID), bxor(lowPID, highPID))

 if shinyTypeValue < 8 then
  return "green", shinyTypeValue == 0 and " (Square)" or " (Star)"
 end

 return nil, ""
end

function getRngInfo()
 local mtSeed = read32Bit(mtSeedAddr)
 local current = read32Bit(currentSeedAddr)
 local delay = read32Bit(delayAddr)
 local mtIndex = read32Bit(mtIndexAddr)

 if mtSeed == current then  -- Set the initial seed when the MT seed is equal to the LCRNG current seed
  setInitialSeed(mtSeed, delay)
 elseif prevMTSeed ~= mtSeed then  -- Check when the value of the MT seed changes in RAM
  if mtIndex ~= 624 and initialSeed ~= 0 then  -- Avoid advancing the MT counter when the MT seed changes the first time
   mtCounter = mtCounter + 1
  end

  prevMTSeed = mtSeed
 elseif current == buildSeedFromDelay(delay) then  -- Check when initial battle seed is set on current seed address
  local lastCurrentSeedBeforeBattleAddr = read32Bit(currentSeedAddr - 0x4) + 0x15E4
  lastCurrentSeedBeforeBattle = read32Bit(lastCurrentSeedBeforeBattleAddr)
  battleStartJumpFlag = true
 elseif tempCurrentSeed == read32Bit(tempCurrentSeedDuringBattleAddr) and tempCurrentSeed ~= 0 then  -- Check when current seed is set on battle temp current seed address
  lastCurrentSeedBeforeBattle = tempCurrentSeed
  battleStartJumpFlag = true
 elseif current == lastCurrentSeedBeforeBattle then  -- Check when battle ends
  battleStartJumpFlag = false
 end

 if not battleStartJumpFlag then  -- Calculate prng jumps only when not in battle
  advances = mtSeed == current and 0 or advances + LCRNGDistance(tempCurrentSeed, current)
 end

 local mtAdvances = (mtIndex - 624) + (mtCounter * 624)

 if mtAdvances < 0 and initialSeed ~= 0 then  -- Avoid negative MT advances (this may happens in korean games)
  mtCounter = mtCounter + 1
 end

 return current, mtAdvances, delay
end

local showInitialSeedInfoText = true

function getInitialSeedInfoInput()
 local key = input.get()

 if key["7"] or key["numpad7"] then
  showInitialSeedInfoText = false
 elseif key["8"] or key["numpad8"] then
  showInitialSeedInfoText = true
 end

 gui.box(1, 180, 110, 190, "#0000007F", "#0000007F")
 gui.text(2, 182, showInitialSeedInfoText and "7 - Hide Seed info" or "8 - Show Seed info")
end

function showInitialSeedInfo(delay)
 local delayOffset = 21

 gui.box(1, 67, 164, 141, "#0000007F", "#0000007F")
 gui.text(2, 68, string.format("Next Initial Seed: %08X", buildSeedFromDelay(delay + delayOffset, true)))
 gui.text(2, 79, string.format("Next Delay: %d", delay + delayOffset))
 gui.text(2, 90, string.format("Delay: %d", delay))
 gui.text(2, 101, string.format("Hit Delay: %d", hitDelay))
 gui.text(2, 112, string.format("Hit Date/Hour:\n%s", hitDate))
end

function showDateTime()
end

local showRngInfoText = true

function showRngInfo()
end

function getTrainerIDs()
 local trainerIDsAddr = read32Bit(trainerIDsPointerAddr) + 0x288
 local trainerIDs = read32Bit(trainerIDsAddr)
 local TID = band(trainerIDs, 0xFFFF)
 local SID = rshift(trainerIDs, 16)

 return TID, SID
end

function showTrainerIDs()
 local trainerTID, trainerSID = getTrainerIDs()
 local disable_gui = PERF and PERF.DISABLE_GUI
 local minimal_ui = PERF and PERF.MINIMAL_UI_IN_TURBO
 if not disable_gui and not (TURBO_ACTIVE and minimal_ui) then
       gui.text(5, 6, string.format("TID: %05d", trainerTID), "white")
       gui.text(90, 6, string.format("SID: %05d", trainerSID), "white")
 end
end

function showInfo(pidAddr)
 local pokemonPID = read32Bit(pidAddr)
 local disable_gui = PERF and PERF.DISABLE_GUI
 local minimal_ui = PERF and PERF.MINIMAL_UI_IN_TURBO
 if not disable_gui and not (TURBO_ACTIVE and minimal_ui) then
       gui.text(125, 45, "PID:")
       gui.text(155, 45, string.format("%08X", pokemonPID), "white")
 end
end

local prevKeyRoamerSlot, roamerSlotIndex = {}, 0

local prevStateKey = {}

function getSaveStateInput()
 prevStateKey = input.get()
end


function main()
      if not wrongGameVersion then
            getSaveStateInput()
            setDateTime()
            local disable_gui = PERF and PERF.DISABLE_GUI
            local minimal_ui = PERF and PERF.MINIMAL_UI_IN_TURBO
            if not disable_gui and not (TURBO_ACTIVE and minimal_ui) then
                  setBackgroundBoxes()
                  showTrainerIDs()

                  local pidAddr = read32Bit(pidPointerAddr)
                  local enemyAddr = pidAddr + 0x59D88 + koreanOffset
                  showInfo(enemyAddr)
            end
      end
end

-- ===================================================
-- Shiny fishing automation logic
-- ===================================================

-- Set up paths for status/log files
local scriptPath = debug.getinfo(1, "S").source:sub(2)
local scriptDir = scriptPath:match("(.*/)")
if not scriptDir then
      scriptDir = scriptPath:match("(.*\\)")
end
if not scriptDir then
      scriptDir = ""
end
local STATUS_FILE = (scriptDir .. "..\\shared\\status.txt")
local LOG_FILE = (scriptDir .. "..\\shared\\log_" .. os.date("%Y%m%d") .. ".txt")
local COMMAND_FILE = scriptDir .. "..\\shared\\command.txt"

local function ensure_shared_dir_and_files()
      local sharedDir = scriptDir .. "..\\shared\\"
      sharedDir = string.gsub(sharedDir, "/", "\\")
      local ok, err = pcall(function()
            local attr = lfs and lfs.attributes(sharedDir) or nil
      end)
      if not ok or not package then
            os.execute('mkdir "' .. sharedDir .. '" >nul 2>nul')
      else
            os.execute('mkdir "' .. sharedDir .. '" >nul 2>nul')
      end
      -- Ensure command and status files exist with minimal content
      local function ensure_file(path, contents)
            local f = io.open(path, "r")
            if f then f:close(); return end
            local tmp = path .. ".tmp"
            local w = io.open(tmp, "w")
            if w then
                  if contents then w:write(contents) end
                  w:close()
                  os.remove(path)
                  os.rename(tmp, path)
            end
      end
      ensure_file(COMMAND_FILE, "")
      ensure_file(STATUS_FILE, "STATUS=READY\n")
end

-- Try to create shared dir and files (best-effort)
pcall(ensure_shared_dir_and_files)

print(string.format("[Lua] STATUS_FILE => %s", STATUS_FILE))
print(string.format("[Lua] COMMAND_FILE => %s", COMMAND_FILE))

local foundShiny = false
local TURBO_ACTIVE = false

-- Temporary testing flag: when true, `checkEncounter` will report a shiny immediately
local SIMULATE_SHINY = false

-- File helpers
function writeStatus(status, details)
      -- Only write final statuses to the controller to avoid duplicate triggers
      if status ~= "SHINY_FOUND" and status ~= "NOT_SHINY" and status ~= "READY" then
            writeLog(string.format("SUPPRESSED STATUS=%s DETAILS=%s", tostring(status), tostring(details or "")))
            return
      end

      -- Optionally suppress frequent NOT_SHINY writes to reduce disk I/O when turbo automation is active
      if PERF.SUPPRESS_NOT_SHINY_WRITE and status == "NOT_SHINY" and TURBO_ACTIVE then
            -- only log locally, controller will infer attempts via polling
            writeLog(string.format("SUPPRESSED frequent NOT_SHINY for PID details=%s", tostring(details or "")))
            return
      end

      -- Write atomically using a temp file then rename. Only include minimal fields for the controller.
      local tmp = STATUS_FILE .. ".tmp"
      local file = io.open(tmp, "w")
      if file then
            file:write(string.format("STATUS=%s\n", status))
            if details then file:write(string.format("DETAILS=%s\n", details)) end
            file:close()
            -- Replace old file
            local okRemove, remErr = pcall(function() os.remove(STATUS_FILE) end)
            local okRename, renErr = pcall(function() os.rename(tmp, STATUS_FILE) end)
      end
end

-- Simplified logger: print directly to Lua console. File logging disabled for verbosity.
function writeLog(message)
      if TURBO_ACTIVE then
            -- Only log important events while turbo is active to reduce CPU overhead
            if string.find(message, "SHINY FOUND") or string.find(message, "START") or string.find(message, "STOP") or string.find(message, "Failed to") or string.find(message, "Emulator speed") then
                  print(string.format("[LOG %s] %s", os.date("%Y-%m-%d %H:%M:%S"), message))
            end
      else
            print(string.format("[LOG %s] %s", os.date("%Y-%m-%d %H:%M:%S"), message))
      end
end

-- Input helpers
function pressButton(button)
      joypad.set(1, {[button] = true})
      emu.frameadvance()
      joypad.set(1, {[button] = false})
end

function touchScreen(x, y, frames)
      frames = frames or 1
      for i = 1, frames do stylus.set({touch = true, x = x, y = y}); emu.frameadvance() end
      stylus.set({touch = false}); emu.frameadvance()
end

function waitFrames(frames)
      for i = 1, frames do emu.frameadvance() end
end

function clickRunButton()
      writeLog("Clicking Run button at coordinates (128, 170)")
      touchScreen(128, 170, 3)
      waitFrames(10)
      touchScreen(128, 170, 3)
end

function dismissNoBiteMessage()
      writeLog("Dismissing no bite message")
      for i = 1, 5 do pressButton("A"); waitFrames(10) end
      waitFrames(30)
end

function fleeFromBattle()
      writeLog("Flee from battle - waiting for load and clicking Run")
      waitFrames(720)
      clickRunButton()
      waitFrames(30)
      clickRunButton()
      waitFrames(30)
      waitFrames(180)
      for i = 1, 5 do pressButton("A"); waitFrames(10) end
      waitFrames(120)
      writeLog("Flee complete, back to overworld")
end

function castRod()
      writeLog("Casting rod")
      pressButton("Y"); waitFrames(10)
      pressButton("Y"); waitFrames(90)
end

function waitForBite()
      writeLog("Waiting for bite - monitoring fishing state changes")
      local previousState = 0
      waitFrames(10)
      previousState = readByte(0x021D5E03)
      while true do
            local currentState = readByte(0x021D5E03)
            if currentState ~= previousState then
                  writeLog(string.format("Bite detected (state %d -> %d)", previousState, currentState))
                  waitFrames(1)
                  pressButton("A"); waitFrames(2)
                  pressButton("A"); waitFrames(2)
                  pressButton("A")
                  waitFrames(60)
                  for i = 1, 5 do pressButton("A"); waitFrames(10) end
                  waitFrames(30)
                  return true
            end
            previousState = currentState
            emu.frameadvance()
      end
end

function waitForBattleOrNoBite()
      writeLog("Checking fishing state to determine battle vs no-bite")
      waitFrames(30)
      local fishState = readByte(0x021D5E03)
      if fishState == 0 then
            writeLog("No battle occurred")
            return false
      end
      writeLog(string.format("Battle loading (state %d)", fishState))
      local stableFramesNeeded = 30
      local stableFrameCount = 0
      local lastState = fishState
      local totalFrames = 0
      local maxWaitFrames = 720
      local reachedZero = false
      while totalFrames < maxWaitFrames do
            emu.frameadvance(); totalFrames = totalFrames + 1
            local currentState = readByte(0x021D5E03)
            if currentState ~= lastState then
                        stableFrameCount = 0; lastState = currentState
                        if currentState == 0 then reachedZero = true end
            else
                  stableFrameCount = stableFrameCount + 1
                  if currentState == 0 and stableFrameCount >= stableFramesNeeded then return true end
            end
      end
      writeLog(string.format("Battle load timeout after %d frames - state: %d", totalFrames, lastState))
      return true
end

function getEncounteredPID()
      writeLog("Getting encountered PID")
      local pidAddr = read32Bit(pidPointerAddr)
      local enemyAddr = pidAddr + 0x59D88 + koreanOffset
      return read32Bit(enemyAddr)
end
function checkEncounter(simulate)
      writeLog("Starting encounter check")
      waitFrames(120)

      local pid = getEncounteredPID()

      if simulate then
            -- Simulation path only when explicitly requested
            local tid, sid = getTrainerIDs()
            writeLog(string.format("Simulated check - PID=%08X TID=%05d SID=%05d", pid, tid, sid))
            -- Write only the final result for the controller: SHINY_FOUND
            foundShiny = true
            -- Protected savestate save: try/catch using pcall to avoid script crash
            local ok, err = pcall(function()
                  savestate.save(1)
            end)
            if ok then
                  writeLog(string.format("Savestate saved to slot 1 for PID=%08X (simulated)", pid))
            else
                  writeLog(string.format("Failed to save savestate: %s", tostring(err)))
            end
            writeStatus("SHINY_FOUND", string.format("SHINY FOUND PID: %08X", pid))
            writeLog(string.format("SHINY FOUND! PID=%08X (simulated)", pid))
            return true
      else
            local tid, sid = getTrainerIDs()
            writeLog(string.format("Checking shiny... PID=%08X TID=%05d SID=%05d", pid, tid, sid))
            local color, badge = shinyCheck(pid, tid, sid)

            if color then
                  foundShiny = true
                  -- Protected savestate save: try/catch using pcall to avoid script crash
                  local ok, err = pcall(function()
                        savestate.save(1)
                  end)
                  if ok then
                        writeLog(string.format("Savestate saved to slot 1 for PID=%08X (type: %s%s)", pid, color, badge or ""))
                  else
                        writeLog(string.format("Failed to save savestate: %s", tostring(err)))
                  end
                  writeStatus("SHINY_FOUND", string.format("SHINY FOUND PID: %08X", pid))
                  writeLog(string.format("SHINY FOUND! PID=%08X (type: %s%s)", pid, color, badge or ""))
                  return true
            else
                  writeStatus("NOT_SHINY", string.format("PID=%08X", pid))
                  writeLog(string.format("Not shiny: PID=%08X", pid))
                  return false
            end
      end
end

-- Command system
local COMMAND_FILE = scriptDir .. "..\\shared\\command.txt"
local lastCommand = ""
local isPaused = false
local commandPollCounter = 0

function readCommand()
      local candidates = { COMMAND_FILE }
      table.insert(candidates, (string.gsub(COMMAND_FILE, "\\", "/")))
      table.insert(candidates, (string.gsub(COMMAND_FILE, "/", "\\")))

      for _, path in ipairs(candidates) do
            local file = io.open(path, "r")
            if file then
                  local command = file:read("*line")
                  file:close()
                  if command then
                        command = (string.gsub(command, "%s+", ""))
                        command = string.upper(command)
                        print(string.format("[Lua] read command '%s' from %s", command, path))
                        return command
                  end
            else
                  -- print which candidate failed to open (debug)
                  -- avoid spamming by not printing every loop once automation runs rapidly
            end
      end

      return ""
end

function clearCommand()
      local file = io.open(COMMAND_FILE, "w")
      if file then file:write(""); file:close() end
end

function processCommands()
      -- Read commands on every frame for responsive STOP/PAUSE behavior
      local command = readCommand()
      if command ~= "" and command ~= lastCommand then
            lastCommand = command
            if command == "START" then
                  clearCommand(); writeLog("START command received from controller"); foundShiny = false; return "START"
            elseif command == "PAUSE" then
                  clearCommand(); isPaused = true; writeLog("PAUSE command received from controller"); return "PAUSE"
            elseif command == "RESUME" then
                  clearCommand(); isPaused = false; writeLog("RESUME command received from controller"); return "RESUME"
            elseif command == "STOP" then
                  clearCommand(); writeLog("STOP command received from controller"); -- ensure turbo flag cleared
                  TURBO_ACTIVE = false
                  emu.speedmode("normal")
                  return "STOP"
            elseif command == "SIM_ON" then
                  clearCommand(); SIMULATE_SHINY = true; writeLog("SIMULATE mode ON"); return nil
            elseif command == "SIM_OFF" then
                  clearCommand(); SIMULATE_SHINY = false; writeLog("SIMULATE mode OFF"); return nil
            end
      end
      return nil
end

function automationLoopWithPause()
      emu.speedmode(PERF.TURBO_SPEED)
      TURBO_ACTIVE = true
      writeLog("Emulator speed set to turbo for automation")
      writeLog("Starting automation - will flee from non-shiny battles to advance RNG naturally")
      while not foundShiny do
            writeLog(string.format("Automation loop: paused=%s", tostring(isPaused)))
            local cmd = processCommands()
            if cmd == "STOP" then emu.speedmode("normal"); writeLog("Automation stopped - speed reset to normal"); return end
            while isPaused do emu.frameadvance(); local resumeCmd = processCommands(); if resumeCmd == "RESUME" then break elseif resumeCmd == "STOP" then emu.speedmode("normal"); return end end
            writeLog("About to cast rod")
            castRod()
            waitForBite()
            local gotBattle = waitForBattleOrNoBite()
            if not gotBattle then writeLog("Nothing bit - dismissing message and trying again..."); dismissNoBiteMessage()
            else local isShinyMagikarp = checkEncounter(SIMULATE_SHINY); if not isShinyMagikarp then fleeFromBattle() else emu.speedmode("normal"); TURBO_ACTIVE = false; writeLog("Shiny found! Speed reset to normal"); writeLog("SHINY FOUND - automation paused"); return end end
            waitFrames(20)
      end
end

-- Initialization
function initialize()
      writeLog("Lua script loaded. Waiting for START command from UI")
      clearCommand()
end

initialize()

-- Top-level frame loop: draw UI and watch for START
while true do
      if not wrongGameVersion then main() end
      local cmd = processCommands()
      if cmd == "START" then automationLoopWithPause(); emu.speedmode("normal"); if not foundShiny then writeStatus("READY", "Ready for next command") end end
      emu.frameadvance()
end