function Get-WSLDistroVhdInfo {
    param(
        [switch]$All = $false,
        [switch]$IncludeDocker = $false
    )
    
    $items = Get-ChildItem -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss
    foreach ($item in $items) {
        $distroName = $item.GetValue("DistributionName")
        if ($All -or ($distroName -and ($IncludeDocker -or $distroName -notmatch 'docker-desktop'))) {
            $basePath = $item.GetValue("BasePath")
            $vhdPath = Join-Path $basePath "ext4.vhdx"
            $size = (Get-Item $vhdPath -ErrorAction SilentlyContinue).Length
            [PSCustomObject]@{
                Distro    = $distroName
                VhdxPath  = $vhdPath
                SizeBytes = $size
            }
        }
    }
}

function Compact-WSLDistro {
    param(
        [Parameter(Mandatory)]
        [string]$Distro
    )

    function Test-IsAdmin {
        $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if (-not (Test-IsAdmin)) {
        Write-Host "This script must be run as an administrator. Restarting with elevated privileges..."
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& { $PSCommandPath -Distro '$Distro' }`"" -Verb RunAs
        return
    }

    Write-Host "Running fstrim on $Distro..."
    wsl.exe -d $Distro sudo fstrim /
    
    Write-Host "Shutting down WSL..."
    wsl.exe --shutdown

    Write-Host "Retrieving VHDX path for $Distro..."
    $distroInfo = Get-WSLDistroVhdInfo -All | Where-Object { $_.Distro -eq $Distro }

    if ($distroInfo) {
        $vhdPath = $distroInfo.VhdxPath
        Write-Host "VHDX path found: $vhdPath"
        
        $beforeSize = (Get-Item $vhdPath -ErrorAction SilentlyContinue).Length
        Write-Host "Before compaction size: $($beforeSize / 1MB) MB"
        
        $scriptContent = @"
select vdisk file="$vhdPath"
attach vdisk readonly
compact vdisk
detach vdisk
exit
"@
        $tempPath = [IO.Path]::GetTempFileName()
        Set-Content -Path $tempPath -Value $scriptContent
        
        Write-Host "Running diskpart to compact VHDX..."
        Start-Process diskpart -ArgumentList "/s $tempPath" -Wait
        
        Write-Host "Cleaning up temporary files..."
        Remove-Item $tempPath
        
        $afterSize = (Get-Item $vhdPath -ErrorAction SilentlyContinue).Length
        Write-Host "After compaction size: $($afterSize / 1MB) MB"
        
        $reclaimedSpace = ($beforeSize - $afterSize) / 1MB
        Write-Host "Disk space reclaimed: $reclaimedSpace MB"
        
        Write-Host "Compaction of $Distro completed."
    }
    else {
        Write-Host "Distro not found in registry."
    }
}

Export-ModuleMember -Function Get-WSLDistroVhdInfo,Compact-WSLDistro