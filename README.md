This is a small Windows controller application that automates fishing checks in Pokémon Pearl (runs alongside DeSmuME). If you just want to run the program and avoid code or build steps, follow the instructions below.

This project was largely made with the intent of trying out a nearly fully "Vibe coded" project using VSCode integrated Copilot to see how it would do without need to work around existing conventions of a codebase. As such the code itself might be a bit messy.


Download & extract

- Go to the repository's Releases page on GitHub and download the latest publish ZIP
- Extract the ZIP to a folder you control (for example `C:\Users\You\Downloads\DPPShinyHunter`).
What you should see inside the extracted folder

- `DPPShinyHunter.exe` — the controller application you run on Windows
- A `lua` folder containing `shiny_fishing.lua` and `lua51.dll`

Requirements

- Windows with the matching .NET runtime installed (framework-dependent publish). If the Release you downloaded is framework-dependent the user must install the appropriate .NET runtime (e.g., .NET 8) from https://dotnet.microsoft.com/download.
- DeSmuME emulator (with Lua scripting enabled) and a Gen4 Pokemon ROM.

Startup Guide

1. After ensuring the above requirements are met, in the extracted folder, launch DPPShinyHunter.exe
2. In the launched window, set the paths to your DeSmuME emulator and the Gen4 DS ROM you are using, and click launch
3. Once the emulator opens, in the emulator window, open Tools -> lua Scripting -> New Lua Scripting Window
4. From there, browse to the DPPShinyHunting folder and select shiny_fishing.lua, this will reset the game when starting
5. Navigate the game menus and load your save as normal, then go to any fishing spot, preferably surfing to avoid misinputs
6. Make sure your fishing rod is equipped to the Y button (Should not be actively using when starting)
7. Press start hunting and the automation loop will start, running at 400% speed and auto-fishing until any shiny is detected
8. Could potentially cause issues if already running a boosted speed so if you run into issues try setting to normal speed
9. When a shiny is found it will make a slot one save state and notify with sound and a window depending on user settings

Troubleshooting

- If `DPPShinyHunter.exe` fails to start and complains about missing .NET runtime, install the appropriate .NET runtime from https://dotnet.microsoft.com/download and try again.
- If the Lua script in DeSmuME reports missing `lua51.dll`, copy `lua51.dll` from the included `lua` folder into your emulator directory or make sure the script is loaded from the included `lua` folder (both files should be together).

License & acknowledgments

- This project is provided for educational purposes. Respect game copyrights and only use with legally obtained ROMs.
- Lua memory-reading concepts used here were largely borrowed from the PokeLua project: https://github.com/Real96/PokeLua
