using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace ShinyAutomation
{
    public class StatusMonitor
    {
        private readonly string _statusFilePath;
        private FileSystemWatcher? _watcher;
        private string _lastRawContent = string.Empty;
        private StatusInfo? _lastStatus;

        public event EventHandler<StatusChangedEventArgs>? StatusChanged;

        public StatusMonitor(string statusFilePath)
        {
            _statusFilePath = statusFilePath;
        }

        public async Task StartMonitoringAsync(CancellationToken cancellationToken)
        {
            // Ensure directory exists
            var dir = Path.GetDirectoryName(_statusFilePath) ?? ".";
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);

            // Create minimal status file if missing
            if (!File.Exists(_statusFilePath))
            {
                await File.WriteAllTextAsync(_statusFilePath, "STATUS=READY\n", cancellationToken);
            }

            // Seed last raw content
            try { _lastRawContent = File.ReadAllText(_statusFilePath); } catch { _lastRawContent = string.Empty; }

            // Set up watcher
            try
            {
                _watcher = new FileSystemWatcher(Path.GetDirectoryName(_statusFilePath) ?? ".", Path.GetFileName(_statusFilePath))
                {
                    NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.FileName | NotifyFilters.Size,
                    EnableRaisingEvents = true,
                    IncludeSubdirectories = false
                };

                _watcher.Changed += async (s, e) =>
                {
                    try
                    {
                        await Task.Delay(50, cancellationToken);
                        var raw = File.ReadAllText(_statusFilePath);
                        raw = raw.Replace("\r\n", "\n").Trim('\0');
                        if (!string.Equals(raw, _lastRawContent, StringComparison.Ordinal))
                        {
                            _lastRawContent = raw;
                            var status = await ReadStatusFileAsync(cancellationToken);
                            RaiseIfChanged(status);
                        }
                    }
                    catch (OperationCanceledException) { }
                    catch { /* ignore transient read errors */ }
                };
            }
            catch (Exception ex)
            {
                Console.WriteLine($"FileSystemWatcher failed: {ex.Message}");
            }

            // Polling fallback
            while (!cancellationToken.IsCancellationRequested)
            {
                try
                {
                    if (File.Exists(_statusFilePath))
                    {
                        try
                        {
                            var raw = File.ReadAllText(_statusFilePath);
                            if (!string.Equals(raw, _lastRawContent, StringComparison.Ordinal))
                            {
                                _lastRawContent = raw;
                                await Task.Delay(50, cancellationToken);
                                var status = await ReadStatusFileAsync(cancellationToken);
                                RaiseIfChanged(status);
                            }
                        }
                        catch (IOException) { /* locked briefly */ }
                    }

                    await Task.Delay(200, cancellationToken);
                }
                catch (OperationCanceledException)
                {
                    throw;
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Status monitor error: {ex.Message}");
                    await Task.Delay(1000, cancellationToken);
                }
            }
        }

        private async Task<StatusInfo> ReadStatusFileAsync(CancellationToken cancellationToken)
        {
            var status = new StatusInfo();
            try
            {
                string[] lines = await File.ReadAllLinesAsync(_statusFilePath, cancellationToken);
                foreach (var line in lines)
                {
                    if (string.IsNullOrWhiteSpace(line)) continue;
                    var parts = line.Split('=', 2);
                    if (parts.Length != 2) continue;
                    var key = parts[0].Trim().ToUpperInvariant();
                    var value = parts[1].Trim();
                    switch (key)
                    {
                        case "STATUS": status.State = value; break;
                        case "DETAILS": status.Details = value; break;
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error parsing status file: {ex.Message}");
            }
            return status;
        }

        private void RaiseIfChanged(StatusInfo status)
        {
            // Dedupe identical consecutive state+details
            if (_lastStatus != null && string.Equals(_lastStatus.State, status.State, StringComparison.Ordinal) &&
                string.Equals(_lastStatus.Details ?? string.Empty, status.Details ?? string.Empty, StringComparison.Ordinal))
            {
                return;
            }

            _lastStatus = status;
            StatusChanged?.Invoke(this, new StatusChangedEventArgs(status));
        }
    }

    public class StatusInfo
    {
        public string State { get; set; } = "UNKNOWN";
        public string Details { get; set; } = string.Empty;
    }

    public class StatusChangedEventArgs : EventArgs
    {
        public StatusInfo Status { get; }

        public StatusChangedEventArgs(StatusInfo status)
        {
            Status = status;
        }
    }
}
