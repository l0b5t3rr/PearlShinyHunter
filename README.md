Pokemon DPP Shiny Magikarp Hunter

An automated shiny hunting tool for Gen4 DS pokemon games using the DeSmuME emulator with a Lua script and a C# Windows Forms controller application.

This project was largely made with the intent of trying out a nearly fully "Vibe coded" project using VSCode integrated Copilot to see how it would do without need to work around existing code or company conventions.

Usage and Quick Start

Prerequisites

- DeSmuME emulator (with Lua scripting enabled)
- Pokemon Diamond Pearl or Platinum ROM (US recommended)
 

Steps

1. Build and run the controller application (from the `controller/` folder):

```powershell
dotnet build controller/DPPShinyHunter.csproj
dotnet run --project controller/DPPShinyHunter.csproj
```

2. Launch DeSmuME and load your Pokemon Pearl ROM.

3. In DeSmuME, open Tools → Lua Scripting and load `lua/shiny_fishing.lua`.

4. In the emulator, make a manual savestate in slot 1 (the Lua script expects slot 1 for fast reloads).

5. In the controller UI click "Start Monitoring" and then "Start Automation" (or write `START` to `shared/command.txt`).

Getting the executable (for non-programmers)

- Download from GitHub Actions: this repository's workflow produces a self-contained Windows publish and uploads it as an artifact named `DPPShinyHunter-publish`. To download the latest build go to Actions → select the latest `Build and Publish` run → download the `DPPShinyHunter-publish` artifact and extract it. The extracted folder contains `DPPShinyHunter.exe` and the `shiny_fishing.lua` script.
- Local publish (if you want to build locally): use the included VS Code task or run the publish command manually (PowerShell):

```powershell
dotnet restore controller/DPPShinyHunter.csproj
dotnet publish controller/DPPShinyHunter.csproj -c Release -r win-x64 -p:SelfContained=true -o controller/bin/Release/net8.0-windows/publish-selfcontained
```

- VS Code task: open the Command Palette → Tasks: Run Task → choose `Publish (self-contained, win-x64)` to produce the same publish folder.

- What's included in the publish folder

- `DPPShinyHunter.exe` and the .NET runtime files required to run it (self-contained)
- `shiny_fishing.lua` (copied from the repo `lua` folder so DeSmuME can load it)
- `lua51.dll` (if required) and any native files the app needs at runtime
- Note: the ROM itself is not included and must be supplied by you.

- Distributing to users

- For end users, attach the artifact zip to a GitHub Release or provide the zipped artifact downloaded from Actions. Users can extract and run `DPPShinyHunter.exe` without needing to install the .NET runtime, then open DeSmuME → Tools → Lua Scripting → load the provided `shiny_fishing.lua`.

License and Acknowledgments

This project is provided for educational purposes. Respect game copyrights and only use with legally obtained ROMs.

Memory-reading techniques on the Lua side drew inspiration and examples from the PokeLua project: https://github.com/Real96/PokeLua