function Get-WSLDistroVhdInfo {
    param(
        [switch]$All = $false,
        [switch]$IncludeDocker = $false
    )
    
    $items = Get-ChildItem -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss -ErrorAction SilentlyContinue
    if (-not $items) {
        Write-Error "Failed to retrieve WSL distributions from registry."
        return
    }

    foreach ($item in $items) {
        $distroName = $item.GetValue("DistributionName", $null)
        if ($All -or ($distroName -and ($IncludeDocker -or $distroName -notmatch 'docker-desktop'))) {
            $basePath = $item.GetValue("BasePath", $null)
            if (-not $basePath) {
                Write-Error "BasePath not found for distribution: $distroName"
                continue
            }

            $vhdPath = Join-Path $basePath "ext4.vhdx"
            $size = (Get-Item $vhdPath -ErrorAction SilentlyContinue).Length
            if (-not $size) {
                Write-Error "Failed to retrieve size for VHDX file: $vhdPath"
                continue
            }

            [PSCustomObject]@{
                Distro    = $distroName
                VhdxPath  = $vhdPath
                SizeBytes = $size
            }
        }
    }
}

function Optimize-WSLDistro {
    param(
        [Parameter(Mandatory)]
        [string]$Distro
    )

    function Test-IsAdmin {
        $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if (-not (Test-IsAdmin)) {
        Write-Host "This script must be run as an administrator. Exiting function..."
        return
    }

    Write-Host "Running fstrim on $Distro..."
    try {
        wsl.exe -d $Distro sudo fstrim /
    } catch {
        Write-Error "Failed to run fstrim on ${Distro}: $_"
        return
    }
    
    Write-Host "Shutting down WSL..."
    try {
        wsl.exe --shutdown
    } catch {
        Write-Error "Failed to shut down WSL: $_"
        return
    }

    Write-Host "Retrieving VHDX path for $Distro..."
    $distroInfo = Get-WSLDistroVhdInfo -All | Where-Object { $_.Distro -eq $Distro }

    if ($distroInfo) {
        $vhdPath = $distroInfo.VhdxPath
        Write-Host "VHDX path found: $vhdPath"
        
        $beforeSize = (Get-Item $vhdPath -ErrorAction SilentlyContinue).Length
        if (-not $beforeSize) {
            Write-Error "Failed to retrieve size for VHDX file: $vhdPath"
            return
        }
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
        try {
            Start-Process diskpart -ArgumentList "/s $tempPath" -Wait
        } catch {
            Write-Error "Failed to run diskpart: $_"
            Remove-Item $tempPath -ErrorAction SilentlyContinue
            return
        }
        
        Write-Host "Cleaning up temporary files..."
        Remove-Item $tempPath -ErrorAction SilentlyContinue
        
        $afterSize = (Get-Item $vhdPath -ErrorAction SilentlyContinue).Length
        if (-not $afterSize) {
            Write-Error "Failed to retrieve size for VHDX file after compaction: $vhdPath"
            return
        }
        Write-Host "After compaction size: $($afterSize / 1MB) MB"
        
        $reclaimedSpace = ($beforeSize - $afterSize) / 1MB
        Write-Host "Disk space reclaimed: $reclaimedSpace MB"
        
        Write-Host "Compaction of $Distro completed."
    }
    else {
        Write-Error "Distro not found in registry."
    }
}

Export-ModuleMember -Function Get-WSLDistroVhdInfo,Optimize-WSLDistro
