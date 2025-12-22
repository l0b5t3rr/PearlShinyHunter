using System;
using System.IO;
using System.Windows.Forms;
using System.Drawing;
using System.Media;
using System.Threading;
using System.Threading.Tasks;

namespace DPPShinyHunter
{
    public partial class MainForm : Form
    {
        private int _localEncounters = 0;
        private bool _shinyHandled = false;
        private string _lastEncounterDetails = string.Empty;

        private readonly StatusMonitor _monitor;
        private readonly Logger _logger;
        private CancellationTokenSource? _cancellationTokenSource;
        private bool _isMonitoring = false;

        // UI Controls
        private TextBox _statusTextBox = null!;
        private Label _encountersLabel = null!;
        private Label _shiniesLabel = null!;
        // Non-Magikarp stat removed; controller tracks attempts/encounters
        private Label _currentStatusLabel = null!;
        private Button _startButton = null!;
        private Button _stopButton = null!;
        private Button _clearLogButton = null!;
        private CheckBox _soundAlertCheckBox = null!;
        private CheckBox _autoFocusCheckBox = null!;
        private TextBox _emuPathTextBox = null!;
        private TextBox _romPathTextBox = null!;
        private Button _browseEmuButton = null!;
        private Button _browseRomButton = null!;
        private Button _launchEmuButton = null!;
        private Label _step1Label = null!;
        private Label _step2Label = null!;
        private Label _step2aLabel = null!;
        private Label _step3Label = null!;
        private Label _step4Label = null!;
        private Label _step5Label = null!;

        // Persistent stats
        private int _persistentEncounters = 0;
        private int _persistentShinies = 0;

        public MainForm()
        {
            // Initialize logger first
            _logger = new Logger();
            
            var statusPath = ResolveSharedFile("status.txt");
            _monitor = new StatusMonitor(statusPath);
            
            // Subscribe to status changes
            _monitor.StatusChanged += OnStatusChanged;
            
            this.FormClosing += MainForm_FormClosing;
            
            InitializeComponent();
        }

        private void InitializeComponent()
        {
            this.Text = "DPP Shiny Hunter";
            this.Size = new Size(850, 700);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.MinimumSize = new Size(850, 700);

            // Status Panel
            var statusPanel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 105,
                BorderStyle = BorderStyle.FixedSingle,
                Padding = new Padding(10)
            };

            _currentStatusLabel = new Label
            {
                Text = "Status: Not Started",
                Location = new Point(10, 10),
                Size = new Size(560, 25),
                Font = new Font("Segoe UI", 12, FontStyle.Bold),
                ForeColor = Color.DarkBlue
            };

            _encountersLabel = new Label
            {
                Text = "Total Encounters: 0",
                Location = new Point(10, 45),
                Size = new Size(260, 20)
            };

            _shiniesLabel = new Label
            {
                Text = "Total Shinies: 0",
                Location = new Point(10, 70),
                Size = new Size(260, 20)
            };

            // Reset Stats button on the right center of the status section
            var _resetStatsButton = new Button
            {
                Text = "Reset Stats",
                Location = new Point(700, 50),
                Size = new Size(110, 30)
            };
            _resetStatsButton.Click += (s, e) => {
                var result = MessageBox.Show("Reset saved stats (encounters and shinies)?", "Confirm Reset", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
                if (result == DialogResult.Yes)
                {
                    _persistentEncounters = 0;
                    _persistentShinies = 0;
                    _localEncounters = 0;
                    UpdateStatsLabels();
                    SaveStats();
                    LogMessage("✅ Stats reset to zero.");
                }
            };

            statusPanel.Controls.AddRange(new Control[] 
            { 
                _currentStatusLabel, 
                _encountersLabel,
                _shiniesLabel,
                _resetStatsButton
            });

            // Control Panel
            var controlPanel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 80,
                Padding = new Padding(10)
            };

            var controlTitleLabel = new Label
            {
                Text = "🎮 Hunting Controls:",
                Location = new Point(10, 5),
                Size = new Size(200, 20),
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                ForeColor = Color.DarkGreen
            };

            _startButton = new Button
            {
                Text = "▶️ Start Hunting",
                Location = new Point(10, 28),
                Size = new Size(150, 30),
                BackColor = Color.LightGreen,
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                Enabled = true
            };
            _startButton.Click += StartButton_Click;

            _stopButton = new Button
            {
                Text = "⏹️ Stop Hunting",
                Location = new Point(170, 28),
                Size = new Size(120, 30),
                Enabled = false
            };
            _stopButton.Click += StopButton_Click;


            _clearLogButton = new Button
            {
                Text = "Clear Log",
                Location = new Point(300, 28),
                Size = new Size(100, 30)
            };
            _clearLogButton.Click += (s, e) => _statusTextBox.Clear();

            _soundAlertCheckBox = new CheckBox
            {
                Text = "🔔 Sound Alert",
                Location = new Point(410, 30),
                Size = new Size(120, 25),
                Checked = true
            };

            _autoFocusCheckBox = new CheckBox
            {
                Text = "🔔 Auto Focus",
                Location = new Point(540, 30),
                Size = new Size(120, 25),
                Checked = false
            };

            controlPanel.Controls.AddRange(new Control[] 
            { 
                controlTitleLabel,
                _startButton, 
                _stopButton, 
                _clearLogButton,
                _soundAlertCheckBox,
                _autoFocusCheckBox
            });

            // Log Panel
            var logLabel = new Label
            {
                Text = "Activity Log:",
                Dock = DockStyle.Top,
                Height = 25,
                Padding = new Padding(10, 5, 0, 0),
                Font = new Font("Segoe UI", 9, FontStyle.Bold)
            };

            _statusTextBox = new TextBox
            {
                Multiline = true,
                Dock = DockStyle.Fill,
                ScrollBars = ScrollBars.Vertical,
                ReadOnly = true,
                Font = new Font("Consolas", 9),
                BackColor = Color.White
            };

            // Add controls to form
            var setupPanel = CreateSetupPanel();
            var instructionPanel = CreateInstructionPanel();

            this.Controls.Add(_statusTextBox);
            this.Controls.Add(logLabel);
            this.Controls.Add(controlPanel);
            this.Controls.Add(instructionPanel);
            this.Controls.Add(statusPanel);
            this.Controls.Add(setupPanel);

            LogMessage("Application started. Follow the step-by-step guide to begin hunting!");
            LoadSettings();
            LoadStats();
        }

        // Resolve a file located in the repository's `shared` folder by walking upward from the exe location.
        private string ResolveSharedFile(string fileName)
        {
            var baseDir = AppDomain.CurrentDomain.BaseDirectory;
            // Walk up to 6 levels to find the workspace root that contains `shared`
            var dir = baseDir;
            for (int i = 0; i < 6; i++)
            {
                var candidate = Path.Combine(dir, "shared", fileName);
                if (File.Exists(candidate) || Directory.Exists(Path.Combine(dir, "shared")))
                {
                    return Path.GetFullPath(candidate);
                }
                dir = Path.GetFullPath(Path.Combine(dir, ".."));
            }
            // Fallback to the original relative path
            return Path.GetFullPath(Path.Combine(baseDir, "..", "..", "..", "..", "shared", fileName));
        }

        private string ResolveProjectFile(string relativePath)
        {
            var baseDir = AppDomain.CurrentDomain.BaseDirectory;
            var dir = baseDir;
            for (int i = 0; i < 6; i++)
            {
                var candidate = Path.Combine(dir, relativePath);
                if (File.Exists(candidate)) return Path.GetFullPath(candidate);
                dir = Path.GetFullPath(Path.Combine(dir, ".."));
            }
            return Path.GetFullPath(Path.Combine(baseDir, "..", "..", "..", "..", relativePath));
        }

        private Panel CreateInstructionPanel()
        {
            var panel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 190,
                BorderStyle = BorderStyle.FixedSingle,
                Padding = new Padding(10),
                BackColor = Color.FromArgb(240, 248, 255)
            };

            var titleLabel = new Label
            {
                Text = "📋 Quick Start Guide (More detailed in ReadMe):",
                Location = new Point(10, 5),
                Size = new Size(300, 25),
                Font = new Font("Segoe UI", 10, FontStyle.Bold),
                ForeColor = Color.DarkBlue
            };

            _step1Label = CreateStepLabel("1. Set emulator/ROM paths and click Launch or launch DeSmuME manually", 10, 38);
            _step2Label = CreateStepLabel("2. In DeSmuME: Tools → Lua Scripting → Load 'lua/shiny_fishing.lua'", 10, 62);
            _step2aLabel = CreateStepLabel("2a. If you see errors, copy lua51.dll from the included lua folder into the emulator folder", 26, 86);
            _step3Label = CreateStepLabel("3. Load through the menus and navigate to a fishing spot with rod selected, preferably surfing to reduce misinputs", 10, 110);
            _step4Label = CreateStepLabel("4. Click 'Start Hunting' to start automation. Ensure the emulator window is not minimized while hunting", 10, 134);
            _step5Label = CreateStepLabel("5. When a shiny is found the automation will pause, create a save state on slot 1, and play a notification", 10, 158);

            panel.Controls.AddRange(new Control[] 
            { 
                titleLabel, 
                _step1Label, 
                _step2Label, 
                _step2aLabel,
                _step3Label, 
                _step4Label,
                _step5Label
            });

            return panel;
        }

        private Label CreateStepLabel(string text, int x, int y)
        {
            return new Label
            {
                Text = $"⭕ {text}",
                Location = new Point(x, y),
                Size = new Size(800, 20),
                Font = new Font("Segoe UI", 9),
                ForeColor = Color.Black
            };
        }

        // Taskbar flashing (bring user's attention)
        [System.Runtime.InteropServices.StructLayout(System.Runtime.InteropServices.LayoutKind.Sequential)]
        private struct FLASHWINFO
        {
            public uint cbSize;
            public IntPtr hwnd;
            public uint dwFlags;
            public uint uCount;
            public uint dwTimeout;
        }

        private const uint FLASHW_STOP = 0;
        private const uint FLASHW_CAPTION = 0x00000001;
        private const uint FLASHW_TRAY = 0x00000002;
        private const uint FLASHW_ALL = FLASHW_CAPTION | FLASHW_TRAY;
        private const uint FLASHW_TIMERNOFG = 0x0000000C;

        [System.Runtime.InteropServices.DllImport("user32.dll")] 
        private static extern bool FlashWindowEx(ref FLASHWINFO pwfi);

        private void FlashTaskbar(uint count = 5)
        {
            try
            {
                var fInfo = new FLASHWINFO();
                fInfo.cbSize = (uint)System.Runtime.InteropServices.Marshal.SizeOf(typeof(FLASHWINFO));
                fInfo.hwnd = this.Handle;
                fInfo.dwFlags = FLASHW_ALL;
                fInfo.uCount = count;
                fInfo.dwTimeout = 0;
                FlashWindowEx(ref fInfo);
            }
            catch { /* ignore if platform not supported */ }
        }

        private Panel CreateSetupPanel()
        {
            var setupPanel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 95,
                BorderStyle = BorderStyle.FixedSingle,
                Padding = new Padding(10)
            };

            var titleLabel = new Label
            {
                Text = "🎯 Emulator & ROM Setup:",
                Location = new Point(10, 5),
                Size = new Size(400, 20),
                Font = new Font("Segoe UI", 9, FontStyle.Bold)
            };

            // Emulator Path
            var emuLabel = new Label
            {
                Text = "DeSmuME:",
                Location = new Point(10, 30),
                Size = new Size(80, 20)
            };

            _emuPathTextBox = new TextBox
            {
                Location = new Point(95, 28),
                Size = new Size(580, 20),
                PlaceholderText = "Path to DeSmuME.exe"
            };

            _browseEmuButton = new Button
            {
                Text = "Browse",
                Location = new Point(685, 27),
                Size = new Size(70, 23)
            };
            _browseEmuButton.Click += BrowseEmuButton_Click;

            // ROM Path
            var romLabel = new Label
            {
                Text = "ROM:",
                Location = new Point(10, 60),
                Size = new Size(80, 20)
            };

            _romPathTextBox = new TextBox
            {
                Location = new Point(95, 58),
                Size = new Size(580, 20),
                PlaceholderText = "Path to Pokemon Pearl ROM"
            };

            _browseRomButton = new Button
            {
                Text = "Browse",
                Location = new Point(685, 57),
                Size = new Size(70, 23)
            };
            _browseRomButton.Click += BrowseRomButton_Click;

            // Launch Button
            _launchEmuButton = new Button
            {
                Text = "Launch",
                Location = new Point(765, 27),
                Size = new Size(60, 54),
                Enabled = false,
                Font = new Font("Segoe UI", 8, FontStyle.Bold)
            };
            _launchEmuButton.Click += LaunchEmuButton_Click;

            setupPanel.Controls.AddRange(new Control[]
            {
                titleLabel,
                emuLabel, _emuPathTextBox, _browseEmuButton,
                romLabel, _romPathTextBox, _browseRomButton,
                _launchEmuButton
            });

            return setupPanel;
        }

        private void BrowseEmuButton_Click(object? sender, EventArgs e)
        {
            using var dialog = new OpenFileDialog
            {
                Filter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*",
                Title = "Select DeSmuME Executable"
            };

            if (dialog.ShowDialog() == DialogResult.OK)
            {
                _emuPathTextBox.Text = dialog.FileName;
                SaveSettings();
                UpdateLaunchButtonState();
            }
        }

        private void BrowseRomButton_Click(object? sender, EventArgs e)
        {
            using var dialog = new OpenFileDialog
            {
                Filter = "NDS ROM Files (*.nds)|*.nds|All Files (*.*)|*.*",
                Title = "Select Pokemon Pearl ROM"
            };

            if (dialog.ShowDialog() == DialogResult.OK)
            {
                _romPathTextBox.Text = dialog.FileName;
                SaveSettings();
                UpdateLaunchButtonState();
            }
        }

        private void LaunchEmuButton_Click(object? sender, EventArgs e)
        {
            try
            {
                string emuPath = _emuPathTextBox.Text;
                string romPath = _romPathTextBox.Text;

                if (!File.Exists(emuPath))
                {
                    MessageBox.Show("Emulator path is invalid.", "Error", 
                        MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                if (!File.Exists(romPath))
                {
                    MessageBox.Show("ROM path is invalid.", "Error", 
                        MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                // Launch DeSmuME with the ROM
                var startInfo = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = emuPath,
                    Arguments = $"\"{romPath}\"",
                    UseShellExecute = true
                };

                System.Diagnostics.Process.Start(startInfo);
                
                LogMessage($"✅ Launched DeSmuME with ROM: {Path.GetFileName(romPath)}");
                LogMessage("📋 Next: Follow steps 3-4 in the guide above");
                LogMessage($"   Lua script location: {ResolveProjectFile("lua\\shiny_fishing.lua")}");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to launch emulator: {ex.Message}", "Error", 
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }



        private void WriteCommandFile(string command)
        {
            string commandPath = ResolveSharedFile("command.txt");
            try
            {
                var tempPath = commandPath + ".tmp";
                File.WriteAllText(tempPath, command + Environment.NewLine);
                // Replace atomically by deleting old file then moving temp into place
                if (File.Exists(commandPath))
                {
                    File.Delete(commandPath);
                }
                File.Move(tempPath, commandPath);
            }
            catch (Exception ex)
            {
                LogMessage($"⚠️ Failed writing command file: {ex.Message}");
            }
        }

        private void UpdateLaunchButtonState()
        {
            _launchEmuButton.Enabled = 
                !string.IsNullOrWhiteSpace(_emuPathTextBox.Text) && 
                !string.IsNullOrWhiteSpace(_romPathTextBox.Text);
        }

        private void SaveSettings()
        {
            try
            {
                string settingsPath = ResolveSharedFile("user_settings.json");
                
                var settings = new
                {
                    emulator_path = _emuPathTextBox.Text,
                    rom_path = _romPathTextBox.Text
                };

                string json = System.Text.Json.JsonSerializer.Serialize(settings, 
                    new System.Text.Json.JsonSerializerOptions { WriteIndented = true });
                
                File.WriteAllText(settingsPath, json);
            }
            catch
            {
                // Silently fail if we can't save settings
            }
        }

        private void LoadSettings()
        {
            try
            {
                string settingsPath = ResolveSharedFile("user_settings.json");

                if (File.Exists(settingsPath))
                {
                    string json = File.ReadAllText(settingsPath);
                    var settings = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, string>>(json);

                    if (settings != null)
                    {
                        if (settings.TryGetValue("emulator_path", out string? emuPath))
                            _emuPathTextBox.Text = emuPath ?? "";
                        
                        if (settings.TryGetValue("rom_path", out string? romPath))
                            _romPathTextBox.Text = romPath ?? "";
                        
                        UpdateLaunchButtonState();
                    }
                }
            }
            catch
            {
                // Silently fail if we can't load settings
            }
        }

        private async void StartButton_Click(object? sender, EventArgs e)
        {
            if (_isMonitoring) return;

            _cancellationTokenSource = new CancellationTokenSource();
            _isMonitoring = true;
            _startButton.Enabled = false;
            _stopButton.Enabled = true;

            LogMessage("🎣 Starting hunting session...");
            LogMessage("✅ Monitoring status file");
            
            // Send START command to Lua
            try
            {
                // Clear any leftover status from previous runs so controller doesn't react immediately
                ResetStatusFile();
                // Reset internal tracking for a fresh session
                _shinyHandled = false;
                _lastEncounterDetails = string.Empty;
                LogMessage("✅ Status file reset to READY before starting");
                WriteCommandFile("START");
                LogMessage("✅ START command sent to Lua - savestate will be auto-created");
                LogMessage("🚀 Hunting begins immediately!");
            }
            catch (Exception ex)
            {
                LogMessage($"⚠️ Failed to send START command: {ex.Message}");
            }
            
            try
            {
                await _monitor.StartMonitoringAsync(_cancellationTokenSource.Token);
            }
            catch (OperationCanceledException)
            {
                LogMessage("Monitoring stopped by user.");
            }
            catch (Exception ex)
            {
                LogMessage($"Error during monitoring: {ex.Message}");
                MessageBox.Show($"Error: {ex.Message}", "Monitoring Error", 
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        // Overwrite the shared status file with a minimal READY state to avoid leftover triggers
        private void ResetStatusFile()
        {
            string statusPath = ResolveSharedFile("status.txt");
            try
            {
                var tempPath = statusPath + ".tmp";
                File.WriteAllText(tempPath, "STATUS=READY" + Environment.NewLine);
                if (File.Exists(statusPath)) File.Delete(statusPath);
                File.Move(tempPath, statusPath);
            }
            catch (Exception ex)
            {
                LogMessage($"⚠️ Failed resetting status file: {ex.Message}");
            }
        }

        private void StopButton_Click(object? sender, EventArgs e)
        {
            if (!_isMonitoring) return;

            // Send STOP command to Lua
            try
            {
                WriteCommandFile("STOP");
                LogMessage("⏹️ STOP command sent to Lua");
            }
            catch { /* Ignore errors on stop */ }

            _cancellationTokenSource?.Cancel();
            _isMonitoring = false;
            _startButton.Enabled = true;
            _stopButton.Enabled = false;

            // Reset shiny handled flag when stopping
            _shinyHandled = false;
            _lastEncounterDetails = string.Empty;

            LogMessage("Hunting stopped.");
        }

        private void MainForm_FormClosing(object? sender, FormClosingEventArgs e)
        {
            _cancellationTokenSource?.Cancel();
        }

        private void OnStatusChanged(object? sender, StatusChangedEventArgs e)
        {
            if (InvokeRequired)
            {
                Invoke(new Action(() => OnStatusChanged(sender, e)));
                return;
            }
            // Increment local counters based on concise status messages from Lua
            // CASTING: attempt started; BATTLE_LOADING or BITE indicates an encounter starting
            // Only increment encounters when a result arrives (NOT_SHINY or SHINY_FOUND)
            if (e.Status.State == "NOT_SHINY" || e.Status.State == "SHINY_FOUND")
            {
                // Avoid double-counting the same encounter result for identical repeated events
                var details = e.Status.Details ?? string.Empty;
                // If this is a repeated SHINY_FOUND with identical details and we've already handled it, ignore entirely
                if (e.Status.State == "SHINY_FOUND" && _shinyHandled && string.Equals(_lastEncounterDetails, details, StringComparison.Ordinal))
                {
                    return;
                }

                _localEncounters++;
                // update persistent encounters and save
                _persistentEncounters++;
                UpdateStatsLabels();
                SaveStats();
                LogMessage($"[{DateTime.Now:HH:mm:ss}] Encounter #{_localEncounters} result: {e.Status.State}{(string.IsNullOrEmpty(details) ? "" : " - " + details)}");
            }

            // Update current status and log concise details
            _currentStatusLabel.Text = $"Status: {e.Status.State}";
            _currentStatusLabel.ForeColor = GetStatusColor(e.Status.State);

            // Only log checking and commands-related states; final results already logged above.
            var detailText = string.IsNullOrEmpty(e.Status.Details) ? "" : $" - {e.Status.Details}";
            if (e.Status.State == "CHECKING" || e.Status.State == "NO_BITE_MSG" || e.Status.State == "FLEEING")
            {
                LogMessage($"[{DateTime.Now:HH:mm:ss}] {e.Status.State}{detailText}");
            }

            // Handle shiny found: only when state equals SHINY_FOUND
            if (e.Status.State == "SHINY_FOUND")
            {
                var details = e.Status.Details ?? string.Empty;
                // If already handled and details identical we returned earlier. Otherwise, handle now.
                HandleShinyFound(e.Status);
                // Mark as handled for this unique details string so later duplicate events are ignored
                _shinyHandled = true;
                _lastEncounterDetails = details;
            }
        }

        private Color GetStatusColor(string status)
        {
            return status switch
            {
                "SHINY_FOUND" => Color.Gold,
                "CASTING" => Color.Blue,
                "CHECKING" => Color.Orange,
                "NOT_SHINY" => Color.Red,
                "NOT_MAGIKARP" => Color.DarkRed,
                "NO_BITE" => Color.Gray,
                "ENCOUNTER" => Color.Green,
                _ => Color.DarkBlue
            };
        }

        private void HandleShinyFound(StatusInfo status)
        {
            // Play sound alert
            if (_soundAlertCheckBox.Checked)
            {
                try
                {
                    SystemSounds.Exclamation.Play();
                    // Play multiple times for emphasis
                    Task.Run(async () =>
                    {
                        for (int i = 0; i < 3; i++)
                        {
                            await Task.Delay(500);
                            SystemSounds.Exclamation.Play();
                        }
                    });
                }
                catch { /* Ignore sound errors */ }
            }

            // Show notification
            string message = $"SHINY FOUND!\n\n{status.Details}\n\nEncounters: {_localEncounters}";
            
            // Flash the window
            if (_autoFocusCheckBox.Checked)
            {
                FlashWindow();
                FlashTaskbar();
            }

            MessageBox.Show(message, "🌟 SHINY FOUND! 🌟", 
                MessageBoxButtons.OK, MessageBoxIcon.Information);

            // Log to file
            _logger.LogShinyFound(status);

            // Update persistent shinies count and save
            _persistentShinies++;
            UpdateStatsLabels();
            SaveStats();

            // Automatically stop hunting after handling shiny
            try
            {
                StopHuntingInternal();
            }
            catch { /* non-fatal */ }
        }

        private void UpdateStatsLabels()
        {
            _encountersLabel.Text = $"Total Encounters: {_persistentEncounters}";
            _shiniesLabel.Text = $"Total Shinies: {_persistentShinies}";
        }

        private void LoadStats()
        {
            try
            {
                string statsPath = ResolveSharedFile("stats.json");
                if (File.Exists(statsPath))
                {
                    var json = File.ReadAllText(statsPath);
                    var dict = System.Text.Json.JsonSerializer.Deserialize<Dictionary<string,int>>(json);
                    if (dict != null)
                    {
                        dict.TryGetValue("encounters", out _persistentEncounters);
                        dict.TryGetValue("shinies", out _persistentShinies);
                    }
                }
            }
            catch { /* ignore load errors */ }
            // ensure labels reflect loaded stats
            UpdateStatsLabels();
        }

        private void SaveStats()
        {
            try
            {
                string statsPath = ResolveSharedFile("stats.json");
                var dict = new Dictionary<string,int>
                {
                    ["encounters"] = _persistentEncounters,
                    ["shinies"] = _persistentShinies
                };
                var json = System.Text.Json.JsonSerializer.Serialize(dict, new System.Text.Json.JsonSerializerOptions { WriteIndented = true });
                var tmp = statsPath + ".tmp";
                File.WriteAllText(tmp, json);
                if (File.Exists(statsPath)) File.Delete(statsPath);
                File.Move(tmp, statsPath);
            }
            catch (Exception ex)
            {
                LogMessage($"⚠️ Failed saving stats: {ex.Message}");
            }
        }

        // Internal stop helper used both by Stop button and automatic stop
        private void StopHuntingInternal()
        {
            if (!_isMonitoring) return;

            try
            {
                WriteCommandFile("STOP");
                LogMessage("⏹️ STOP command sent to Lua (automatic stop)");
            }
            catch (Exception ex)
            {
                LogMessage($"⚠️ Failed sending STOP command: {ex.Message}");
            }

            _cancellationTokenSource?.Cancel();
            _isMonitoring = false;
            _startButton.Enabled = true;
            _stopButton.Enabled = false;
            LogMessage("Hunting stopped.");
        }

        private void FlashWindow()
        {
            try
            {
                this.Activate();
                this.BringToFront();
                this.Focus();
            }
            catch { /* Ignore focus errors */ }
        }

        private void LogMessage(string message)
        {
            if (InvokeRequired)
            {
                Invoke(new Action(() => LogMessage(message)));
                return;
            }

            _statusTextBox.AppendText(message + Environment.NewLine);
            _logger.Log(message);
        }

        // Test helper removed; testing should be triggered from the Lua script only
    }
}
