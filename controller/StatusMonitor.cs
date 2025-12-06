using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace ShinyAutomation
{
    public class StatusMonitor
    {
        private readonly string _statusFilePath;
        private DateTime _lastModified = DateTime.MinValue;
        
        public event EventHandler<StatusChangedEventArgs>? StatusChanged;

        public StatusMonitor(string statusFilePath)
        {
            _statusFilePath = statusFilePath;
        }

        public async Task StartMonitoringAsync(CancellationToken cancellationToken)
        {
            // Ensure the directory exists
            string? directory = Path.GetDirectoryName(_statusFilePath);
            if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }

            // Create initial status file if it doesn't exist
            if (!File.Exists(_statusFilePath))
            {
                await File.WriteAllTextAsync(_statusFilePath, 
                    "STATUS=WAITING\nATTEMPTS=0\nENCOUNTERS=0\nNON_MAGIKARP=0\n", 
                    cancellationToken);
            }

            while (!cancellationToken.IsCancellationRequested)
            {
                try
                {
                    if (File.Exists(_statusFilePath))
                    {
                        var lastWrite = File.GetLastWriteTime(_statusFilePath);
                        
                        if (lastWrite > _lastModified)
                        {
                            _lastModified = lastWrite;
                            
                            // Small delay to ensure file write is complete
                            await Task.Delay(50, cancellationToken);
                            
                            var status = await ReadStatusFileAsync(cancellationToken);
                            OnStatusChanged(status);
                        }
                    }
                    
                    await Task.Delay(250, cancellationToken); // Check every 250ms
                }
                catch (IOException)
                {
                    // File might be locked, try again
                    await Task.Delay(100, cancellationToken);
                }
                catch (OperationCanceledException)
                {
                    throw; // Re-throw cancellation
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"Error reading status file: {ex.Message}");
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
                
                foreach (string line in lines)
                {
                    if (string.IsNullOrWhiteSpace(line)) continue;
                    
                    var parts = line.Split('=', 2);
                    if (parts.Length != 2) continue;
                    
                    string key = parts[0].Trim();
                    string value = parts[1].Trim();
                    
                    switch (key)
                    {
                        case "STATUS":
                            status.State = value;
                            break;
                        case "ATTEMPTS":
                            status.Attempts = int.TryParse(value, out int attempts) ? attempts : 0;
                            break;
                        case "ENCOUNTERS":
                            status.Encounters = int.TryParse(value, out int encounters) ? encounters : 0;
                            break;
                        case "NON_MAGIKARP":
                            status.NonMagikarp = int.TryParse(value, out int nonMagikarp) ? nonMagikarp : 0;
                            break;
                        case "DETAILS":
                            status.Details = value;
                            break;
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error parsing status file: {ex.Message}");
            }
            
            return status;
        }

        protected virtual void OnStatusChanged(StatusInfo status)
        {
            StatusChanged?.Invoke(this, new StatusChangedEventArgs(status));
        }
    }

    public class StatusInfo
    {
        public string State { get; set; } = "UNKNOWN";
        public int Attempts { get; set; }
        public int Encounters { get; set; }
        public int NonMagikarp { get; set; }
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
