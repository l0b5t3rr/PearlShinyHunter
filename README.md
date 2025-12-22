Pearl Shiny Hunter — Quick Start (for non-programmers)

This package contains a small Windows controller application that automates fishing checks in Pokémon Pearl (runs alongside DeSmuME). If you just want to run the program and avoid code or build steps, follow the instructions below.

This project was largely made with the intent of trying out a nearly fully "Vibe coded" project using VSCode integrated Copilot to see how it would do without need to work around existing code or company conventions.


Download & extract

- Go to the repository's Releases page on GitHub and download the latest publish ZIP (named like `DPPShinyHunter-publish.zip`).
- Extract the ZIP to a folder you control (for example `C:\Users\You\Downloads\DPPShinyHunter`).
What you should see inside the extracted folder

- `DPPShinyHunter.exe` — the controller application you run on Windows
- Several `.dll` files the app needs (framework-dependent publish)
- A `lua` folder containing `shiny_fishing.lua` and `lua51.dll`

Requirements

- Windows with the matching .NET runtime installed (framework-dependent publish). If the Release you downloaded is framework-dependent the user must install the appropriate .NET runtime (e.g., .NET 8) from https://dotnet.microsoft.com/download.
- DeSmuME emulator (with Lua scripting enabled) and a legally obtained Pokémon ROM.

Quick run steps (end-user)

1. Ensure you have the .NET runtime installed (if the release is framework-dependent).
2. Start DeSmuME and load your Pokémon Pearl ROM.
3. In the extracted publish folder, double-click `DPPShinyHunter.exe` to start the controller application.
4. In DeSmuME go to Tools → Lua Scripting → Load `lua/shiny_fishing.lua` from the included `lua` folder.
5. Make a manual savestate in slot 1 inside DeSmuME (the Lua script uses slot 1 for fast reloads).
6. Use the controller UI to start monitoring/automation (the app can also be controlled by writing `START` to the `shared/command.txt` file if needed).

Troubleshooting

- If `DPPShinyHunter.exe` fails to start and complains about missing .NET runtime, install the appropriate .NET runtime from https://dotnet.microsoft.com/download and try again.
- If the Lua script in DeSmuME reports missing `lua51.dll`, copy `lua51.dll` from the included `lua` folder into your emulator directory or make sure the script is loaded from the included `lua` folder (both files should be together).

Distributing to others

- Attach the publish ZIP (the publish folder contents) to a GitHub Release, or upload the ZIP to your distribution channel. Make sure to mention the .NET runtime requirement when sharing the package.

License & acknowledgments

- This project is provided for educational purposes. Respect game copyrights and only use with legally obtained ROMs.
- Lua memory-reading concepts used here were inspired by examples from the PokeLua project: https://github.com/Real96/PokeLua


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

Getting the executable (recommended: use the framework-dependent publish)



- Download from GitHub Releases (recommended):
	1. On GitHub, go to the repository Releases page.
	2. Download the attached publish ZIP for the latest release (the artifact should be named similar to `DPPShinyHunter-publish.zip`).
	3. Extract the ZIP — you should see a folder containing `DPPShinyHunter.exe` and supporting DLLs.

- Local publish (if you want to build locally): use the included VS Code task or run the publish command manually (PowerShell) to produce the framework-dependent publish:

```powershell
dotnet restore controller/DPPShinyHunter.csproj



- **.NET runtime**: Users must have the matching .NET runtime (for example, .NET 8) installed. If they do not have it, they can download it from https://dotnet.microsoft.com/download.
- **Lua files**: The publish output includes a `lua` subfolder with `shiny_fishing.lua` and `lua51.dll`. Keep that `lua` folder together with the published app. DeSmuME expects the Lua script file to be provided when you open Tools → Lua Scripting. Place `lua51.dll` next to the `shiny_fishing.lua` if your DeSmuME setup needs it.

- Running the app and using the Lua script:
	1. Extract the publish folder you downloaded.
	2. Launch `DPPShinyHunter.exe` from the extracted folder.
	3. In DeSmuME, open Tools → Lua Scripting and load the script from the extracted `lua/shiny_fishing.lua` file.

- Distributing to users:

- Attach the publish ZIP to a GitHub Release (recommended). Provide simple instructions pointing users to install the .NET runtime if they don't have it and to load the `lua/shiny_fishing.lua` from the included `lua` folder in DeSmuME.


License and Acknowledgments

This project is provided for educational purposes. Respect game copyrights and only use with legally obtained ROMs.

Memory-reading techniques on the Lua side drew inspiration and examples from the PokeLua project: https://github.com/Real96/PokeLua