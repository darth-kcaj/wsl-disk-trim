# WSL Disk Trim Help

## DISCLAIMER
This script is provided "as is" and should be used at your own risk. It is recommended to back up your WSL data before running this script. The author is not responsible for any data loss or other issues caused by using this script.

## Overview
Install or load the module, then call `Get-WSLDistroVhdInfo` to see your WSL distros and VHDX file information. Use `Compact-WSLDistro` to compact the VHDX files.

## Usage

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