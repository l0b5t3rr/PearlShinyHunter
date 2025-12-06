using System;
using System.IO;
using System.Windows.Forms;
using System.Drawing;
using System.Media;
using System.Threading;
using System.Threading.Tasks;

namespace ShinyAutomation
{
    public partial class MainForm : Form
    {
        private readonly StatusMonitor _monitor;
        private readonly Logger _logger;
        private CancellationTokenSource? _cancellationTokenSource;
        private bool _isMonitoring = false;

        // UI Controls
        private TextBox _statusTextBox = null!;
        private Label _attemptsLabel = null!;
        private Label _encountersLabel = null!;
        private Label _nonMagikarpLabel = null!;
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

        public MainForm()
        {
            // Initialize logger first
            _logger = new Logger();
            
            string statusFilePath = Path.Combine(
                Path.GetDirectoryName(Application.ExecutablePath) ?? "",
                "..", "..", "..", "..", "shared", "status.txt");
            
            _monitor = new StatusMonitor(Path.GetFullPath(statusFilePath));
            
            // Subscribe to status changes
            _monitor.StatusChanged += OnStatusChanged;
            
            this.FormClosing += MainForm_FormClosing;
            
            InitializeComponent();
        }

        private void InitializeComponent()
        {
            this.Text = "Pokémon Pearl Shiny Hunter";
            this.Size = new Size(700, 600);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.MinimumSize = new Size(650, 550);

            // Status Panel
            var statusPanel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 150,
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

            _attemptsLabel = new Label
            {
                Text = "Total Attempts: 0",
                Location = new Point(10, 45),
                Size = new Size(260, 20)
            };

            _encountersLabel = new Label
            {
                Text = "Total Encounters: 0",
                Location = new Point(10, 70),
                Size = new Size(260, 20)
            };

            _nonMagikarpLabel = new Label
            {
                Text = "Non-Magikarp: 0",
                Location = new Point(10, 95),
                Size = new Size(260, 20)
            };

            statusPanel.Controls.AddRange(new Control[] 
            { 
                _currentStatusLabel, 
                _attemptsLabel, 
                _encountersLabel, 
                _nonMagikarpLabel 
            });

            // Control Panel
            var controlPanel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 80,
                Padding = new Padding(10)
            };

            _startButton = new Button
            {
                Text = "Start Monitoring",
                Location = new Point(10, 10),
                Size = new Size(120, 30)
            };
            _startButton.Click += StartButton_Click;

            _stopButton = new Button
            {
                Text = "Stop Monitoring",
                Location = new Point(140, 10),
                Size = new Size(120, 30),
                Enabled = false
            };
            _stopButton.Click += StopButton_Click;

            _clearLogButton = new Button
            {
                Text = "Clear Log",
                Location = new Point(270, 10),
                Size = new Size(100, 30)
            };
            _clearLogButton.Click += (s, e) => _statusTextBox.Clear();

            _soundAlertCheckBox = new CheckBox
            {
                Text = "Sound Alert on Shiny",
                Location = new Point(10, 45),
                Size = new Size(200, 25),
                Checked = true
            };

            _autoFocusCheckBox = new CheckBox
            {
                Text = "Auto Focus Window",
                Location = new Point(220, 45),
                Size = new Size(200, 25),
                Checked = false
            };

            controlPanel.Controls.AddRange(new Control[] 
            { 
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
            // Setup Panel
            var setupPanel = CreateSetupPanel();

            this.Controls.Add(_statusTextBox);
            this.Controls.Add(logLabel);
            this.Controls.Add(controlPanel);
            this.Controls.Add(statusPanel);
            this.Controls.Add(setupPanel);

            LogMessage("Application started. Waiting for monitoring to begin...");
            LoadSettings();
        }

        private Panel CreateSetupPanel()
        {
            var setupPanel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 120,
                BorderStyle = BorderStyle.FixedSingle,
                Padding = new Padding(10)
            };

            var titleLabel = new Label
            {
                Text = "Setup (Optional - for convenience):",
                Location = new Point(10, 5),
                Size = new Size(300, 20),
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
                Size = new Size(440, 20),
                PlaceholderText = "Path to DeSmuME.exe (optional)"
            };

            _browseEmuButton = new Button
            {
                Text = "Browse",
                Location = new Point(540, 27),
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
                Size = new Size(440, 20),
                PlaceholderText = "Path to Pokemon Pearl ROM (optional)"
            };

            _browseRomButton = new Button
            {
                Text = "Browse",
                Location = new Point(540, 57),
                Size = new Size(70, 23)
            };
            _browseRomButton.Click += BrowseRomButton_Click;

            // Launch Button
            _launchEmuButton = new Button
            {
                Text = "🚀 Launch Emulator with ROM",
                Location = new Point(95, 88),
                Size = new Size(200, 25),
                Enabled = false
            };
            _launchEmuButton.Click += LaunchEmuButton_Click;

            var instructionLabel = new Label
            {
                Text = "After launching, load your savestate and run the Lua script from: lua/shiny_fishing.lua",
                Location = new Point(300, 88),
                Size = new Size(360, 30),
                ForeColor = Color.DarkBlue,
                Font = new Font("Segoe UI", 8)
            };

            setupPanel.Controls.AddRange(new Control[]
            {
                titleLabel,
                emuLabel, _emuPathTextBox, _browseEmuButton,
                romLabel, _romPathTextBox, _browseRomButton,
                _launchEmuButton, instructionLabel
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
                
                LogMessage($"Launched DeSmuME with ROM: {Path.GetFileName(romPath)}");
                LogMessage("Next steps: Load your savestate (F1) and load the Lua script:");
                LogMessage($"  → {Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "..", "..", "..", "lua", "shiny_fishing.lua"))}");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Failed to launch emulator: {ex.Message}", "Error", 
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
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
                string settingsPath = Path.Combine(
                    AppDomain.CurrentDomain.BaseDirectory, 
                    "..", "..", "..", "..", "shared", "user_settings.json");
                
                settingsPath = Path.GetFullPath(settingsPath);
                
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
                string settingsPath = Path.Combine(
                    AppDomain.CurrentDomain.BaseDirectory, 
                    "..", "..", "..", "..", "shared", "user_settings.json");
                
                settingsPath = Path.GetFullPath(settingsPath);

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

            LogMessage("Started monitoring status file...");
            
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

        private void StopButton_Click(object? sender, EventArgs e)
        {
            if (!_isMonitoring) return;

            _cancellationTokenSource?.Cancel();
            _isMonitoring = false;
            _startButton.Enabled = true;
            _stopButton.Enabled = false;

            LogMessage("Monitoring stopped.");
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

            // Update statistics
            _attemptsLabel.Text = $"Total Attempts: {e.Status.Attempts}";
            _encountersLabel.Text = $"Total Encounters: {e.Status.Encounters}";
            _nonMagikarpLabel.Text = $"Non-Magikarp: {e.Status.NonMagikarp}";

            // Update current status with color coding
            _currentStatusLabel.Text = $"Status: {e.Status.State}";
            _currentStatusLabel.ForeColor = GetStatusColor(e.Status.State);

            // Log the event
            string message = $"[{DateTime.Now:HH:mm:ss}] {e.Status.State}";
            if (!string.IsNullOrEmpty(e.Status.Details))
            {
                message += $" - {e.Status.Details}";
            }
            LogMessage(message);

            // Handle shiny found
            if (e.Status.State == "SHINY_FOUND")
            {
                HandleShinyFound(e.Status);
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
            string message = $"SHINY MAGIKARP FOUND!\n\n{status.Details}\n\nAttempts: {status.Attempts}\nEncounters: {status.Encounters}";
            
            // Flash the window
            if (_autoFocusCheckBox.Checked)
            {
                FlashWindow();
            }

            MessageBox.Show(message, "🌟 SHINY FOUND! 🌟", 
                MessageBoxButtons.OK, MessageBoxIcon.Information);

            // Log to file
            _logger.LogShinyFound(status);
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
    }
}
