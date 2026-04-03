// pyenv-win shim - launches pwsh with pyenv.ps1
// Based on Scoop's shim pattern (MIT License)
// Compiled to bin/pyenv.exe for cmd.exe entry point

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;

namespace PyenvWin
{
    internal static class Shim
    {
        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GenerateConsoleCtrlEvent(uint dwCtrlEvent, uint dwProcessGroupId);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool SetConsoleCtrlHandler(ConsoleCtrlDelegate handler, bool add);

        private delegate bool ConsoleCtrlDelegate(uint ctrlType);

        private static Process _childProcess;

        private static bool ConsoleCtrlHandler(uint ctrlType)
        {
            // Forward Ctrl+C / Ctrl+Break to child process
            if (_childProcess != null && !_childProcess.HasExited)
            {
                GenerateConsoleCtrlEvent(ctrlType, 0);
            }
            return true;
        }

        private static string FindPwsh()
        {
            // Check PATH for pwsh.exe
            var pathDirs = (Environment.GetEnvironmentVariable("PATH") ?? "").Split(';');
            foreach (var dir in pathDirs)
            {
                if (string.IsNullOrWhiteSpace(dir)) continue;
                var candidate = Path.Combine(dir.Trim(), "pwsh.exe");
                if (File.Exists(candidate)) return candidate;
            }
            return null;
        }

        private static int Main(string[] args)
        {
            var shimDir = AppDomain.CurrentDomain.BaseDirectory;
            var scriptPath = Path.GetFullPath(Path.Combine(shimDir, "pyenv.ps1"));

            if (!File.Exists(scriptPath))
            {
                Console.Error.WriteLine("pyenv: Cannot find pyenv.ps1 at " + scriptPath);
                return 1;
            }

            var pwsh = FindPwsh();
            if (pwsh == null)
            {
                Console.Error.WriteLine("pyenv: PowerShell 7 (pwsh.exe) is required but not found in PATH.");
                Console.Error.WriteLine("Install from: https://aka.ms/install-powershell");
                return 1;
            }

            // Build argument list: pwsh -NoLogo -NoProfile -File pyenv.ps1 <args...>
            var pwshArgs = new List<string>
            {
                "-NoLogo",
                "-NoProfile",
                "-File",
                scriptPath
            };
            pwshArgs.AddRange(args);

            var startInfo = new ProcessStartInfo
            {
                FileName = pwsh,
                UseShellExecute = false,
                CreateNoWindow = false
            };

            foreach (var arg in pwshArgs)
            {
                startInfo.ArgumentList.Add(arg);
            }

            // Forward Ctrl+C to child
            SetConsoleCtrlHandler(ConsoleCtrlHandler, true);

            _childProcess = Process.Start(startInfo);
            if (_childProcess == null)
            {
                Console.Error.WriteLine("pyenv: Failed to start PowerShell.");
                return 1;
            }

            _childProcess.WaitForExit();
            return _childProcess.ExitCode;
        }
    }
}
