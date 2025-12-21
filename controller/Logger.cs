using System;
using System.IO;

namespace DPPShinyHunter
{
    public class Logger
    {
        private readonly string _logFilePath;

        public Logger()
        {
            string logDirectory = Path.Combine(
                AppDomain.CurrentDomain.BaseDirectory,
                "..", "..", "..", "..", "shared");
            
            logDirectory = Path.GetFullPath(logDirectory);
            
            if (!Directory.Exists(logDirectory))
            {
                Directory.CreateDirectory(logDirectory);
            }

            _logFilePath = Path.Combine(logDirectory, $"log_{DateTime.Now:yyyyMMdd}.txt");
        }

        public void Log(string message)
        {
            try
            {
                string logEntry = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {message}";
                File.AppendAllText(_logFilePath, logEntry + Environment.NewLine);
            }
            catch
            {
                // Silently fail if logging doesn't work
            }
        }

        public void LogShinyFound(StatusInfo status)
        {
            try
            {
                string shinyLogPath = Path.Combine(
                    Path.GetDirectoryName(_logFilePath) ?? "",
                    "shiny_encounters.txt");

                string entry = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] " +
                              $"SHINY FOUND! {status.Details}" +
                              Environment.NewLine;

                File.AppendAllText(shinyLogPath, entry);
            }
            catch
            {
                // Silently fail if logging doesn't work
            }
        }
    }
}
