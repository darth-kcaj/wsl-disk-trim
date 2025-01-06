# WSL Disk Trim Help

## DISCLAIMER
This script is provided "as is" and should be used at your own risk. It is recommended to back up your WSL data before running this script. The author is not responsible for any data loss or other issues caused by using this script.



## Usage 
WSL has a great feature where as you add files and data to your virtual Linux Distro, it dynamically expands the disk space allocated to the virtual hard drive. Handy! However (at the time of writing), if you free up space on the WSL OS, the VHD does not dynamically shrink to reclaim the space on the host... not so handy!
I've made this module as a convenience to myself to quickly perform maintenance on the VHDX files to shrink them back down. Use at your own risk!

Install or load the module, then call `Get-WSLDistroVhdInfo` to see your WSL distros and VHDX file information. Use `Compact-WSLDistro` to compact the VHDX files.

### Setting Execution Policy
First, set the execution policy to allow running scripts in the current session:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
```

### Importing the Module
Import the module:
```powershell
Import-Module .\WslListDistros.psm1
```

Alternatively, download and import the module directly from GitHub:
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/darth-kcaj/wsl-disk-trim/refs/heads/main/WslDiskTrim.psm1" -OutFile "WslListDistros.psm1"; Import-Module .\WslListDistros.psm1
```

### Getting WSL Distro VHDX Information
Retrieve information about the VHDX files for WSL distributions:
```powershell
Get-WSLDistroVhdInfo
```

### Compacting a WSL Distro VHDX
Compact the VHDX file for a specific WSL distribution:
```powershell
Compact-WSLDistro -Distro "Ubuntu"
```

### Example
Here is a full example of how to use the module:
```powershell
# Set the execution policy for the current session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned

# Import the module
Import-Module .\WslListDistros.psm1

# Get VHDX information for all WSL distributions
Get-WSLDistroVhdInfo -All

# Compact the VHDX file for the "Ubuntu" distribution
Compact-WSLDistro -Distro "Ubuntu"
```

### Error Handling and Feedback
The script now includes error handling for potential issues such as missing VHDX files, failed diskpart operations, and missing registry keys or values. Detailed error messages are logged to provide feedback for troubleshooting.

### Administrative Privileges
The script requires administrative privileges to run. If the script is not run as an administrator, it will prompt for elevation.
