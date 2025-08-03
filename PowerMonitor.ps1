# PC Power Consumption Monitor
# This script provides detailed power consumption information for your PC

Write-Host "=== PC Power Consumption Monitor ===" -ForegroundColor Green
Write-Host "Gathering power information..." -ForegroundColor Yellow
Write-Host ""

function Get-PowerInfo {
    try {
        # Get battery information (for laptops)
        Write-Host "--- Battery Information ---" -ForegroundColor Cyan
        $batteries = Get-WmiObject -Class Win32_Battery -ErrorAction SilentlyContinue
        
        if ($batteries) {
            foreach ($battery in $batteries) {
                Write-Host "Battery Name: $($battery.Name)"
                Write-Host "Battery Status: $($battery.BatteryStatus)"
                Write-Host "Charge Remaining: $($battery.EstimatedChargeRemaining)%"
                Write-Host "Design Capacity: $($battery.DesignCapacity) mWh"
                Write-Host "Full Charge Capacity: $($battery.FullChargeCapacity) mWh"
                
                # Calculate current power draw (if discharging)
                if ($battery.BatteryStatus -eq 1) {  # 1 = Discharging
                    $estimatedRuntime = $battery.EstimatedRunTime
                    if ($estimatedRuntime -gt 0) {
                        $currentCapacity = ($battery.EstimatedChargeRemaining / 100) * $battery.FullChargeCapacity
                        $powerDraw = [math]::Round($currentCapacity / ($estimatedRuntime / 60), 2)
                        Write-Host "Estimated Power Draw: $powerDraw mW" -ForegroundColor Yellow
                    }
                }
                Write-Host ""
            }
        } else {
            Write-Host "No battery detected (Desktop PC)" -ForegroundColor Gray
            Write-Host ""
        }

        # Get processor power information
        Write-Host "--- Processor Power Information ---" -ForegroundColor Cyan
        $processors = Get-WmiObject -Class Win32_Processor
        foreach ($proc in $processors) {
            Write-Host "Processor: $($proc.Name)"
            Write-Host "Current Clock Speed: $($proc.CurrentClockSpeed) MHz"
            Write-Host "Max Clock Speed: $($proc.MaxClockSpeed) MHz"
            Write-Host "Load Percentage: $($proc.LoadPercentage)%"
            
            # Try to get TDP information from registry or estimate
            try {
                $cpuPower = Get-Counter "\Processor Information(_Total)\% Processor Performance" -ErrorAction SilentlyContinue
                if ($cpuPower) {
                    Write-Host "Processor Performance: $([math]::Round($cpuPower.CounterSamples[0].CookedValue, 2))%"
                }
            } catch {
                Write-Host "Processor Performance: Unable to retrieve"
            }
        }
        Write-Host ""

        # Get power scheme information
        Write-Host "--- Power Scheme Information ---" -ForegroundColor Cyan
        $powerScheme = powercfg /getactivescheme
        Write-Host "Active Power Scheme: $($powerScheme -replace '.*\((.*)\).*', '$1')"
        Write-Host ""

        # Get system power consumption estimates
        Write-Host "--- System Power Estimates ---" -ForegroundColor Cyan
        
        # CPU utilization for power estimation
        $cpuUsage = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 3
        $avgCpuUsage = ($cpuUsage.CounterSamples | Measure-Object -Property CookedValue -Average).Average
        Write-Host "Average CPU Usage: $([math]::Round($avgCpuUsage, 2))%"

        # Memory usage
        $totalRAM = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
        $availableRAM = (Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory / 1MB
        $usedRAM = $totalRAM - ($availableRAM / 1024)
        $ramUsagePercent = ($usedRAM / $totalRAM) * 100
        Write-Host "RAM Usage: $([math]::Round($usedRAM, 2)) GB / $([math]::Round($totalRAM, 2)) GB ($([math]::Round($ramUsagePercent, 1))%)"

        # Disk activity
        try {
            $diskActivity = Get-Counter "\PhysicalDisk(_Total)\% Disk Time" -ErrorAction SilentlyContinue
            if ($diskActivity) {
                Write-Host "Disk Activity: $([math]::Round($diskActivity.CounterSamples[0].CookedValue, 2))%"
            }
        } catch {
            Write-Host "Disk Activity: Unable to retrieve"
        }

        # Network activity
        try {
            $networkCounters = Get-Counter "\Network Interface(*)\Bytes Total/sec" -ErrorAction SilentlyContinue
            if ($networkCounters) {
                $totalNetworkBytes = ($networkCounters.CounterSamples | Where-Object {$_.InstanceName -notlike "*Loopback*" -and $_.InstanceName -notlike "*isatap*"} | Measure-Object -Property CookedValue -Sum).Sum
                Write-Host "Network Activity: $([math]::Round($totalNetworkBytes / 1MB, 2)) MB/s"
            }
        } catch {
            Write-Host "Network Activity: Unable to retrieve"
        }

        Write-Host ""

        # Power consumption estimation
        Write-Host "--- Estimated Power Consumption ---" -ForegroundColor Cyan
        Write-Host "Note: These are rough estimates based on typical component power draws" -ForegroundColor Yellow
        
        # Base system power (motherboard, fans, etc.)
        $basePower = 50
        
        # CPU power estimation (typical desktop CPU: 65-125W TDP)
        $estimatedCpuPower = 85 * ($avgCpuUsage / 100)
        
        # RAM power (typical: 3-5W per 8GB stick)
        $estimatedRamPower = ($totalRAM / 8) * 4
        
        # Storage power (SSD: 2-3W, HDD: 6-10W - assuming mixed)
        $estimatedStoragePower = 5
        
        # GPU power (very rough estimate - varies greatly)
        $estimatedGpuPower = 30  # Idle/light load estimate
        
        $totalEstimatedPower = $basePower + $estimatedCpuPower + $estimatedRamPower + $estimatedStoragePower + $estimatedGpuPower
        
        Write-Host "Base System Power: ~$basePower W"
        Write-Host "CPU Power (estimated): ~$([math]::Round($estimatedCpuPower, 1)) W"
        Write-Host "RAM Power (estimated): ~$([math]::Round($estimatedRamPower, 1)) W"
        Write-Host "Storage Power (estimated): ~$estimatedStoragePower W"
        Write-Host "GPU Power (estimated): ~$estimatedGpuPower W (idle/light load)"
        Write-Host ""
        Write-Host "Total Estimated Power Consumption: ~$([math]::Round($totalEstimatedPower, 1)) W" -ForegroundColor Green
        Write-Host ""
        Write-Host "Important Notes:" -ForegroundColor Red
        Write-Host "- These are rough estimates and actual consumption may vary significantly"
        Write-Host "- GPU power can range from 20W (idle) to 300W+ (gaming/rendering)"
        Write-Host "- Monitor power is not included in these estimates"
        Write-Host "- For accurate measurements, use a hardware power meter (kill-a-watt, etc.)"

    } catch {
        Write-Host "Error retrieving power information: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-ContinuousMonitoring {
    Write-Host ""
    Write-Host "--- Continuous Power Monitoring ---" -ForegroundColor Magenta
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
    Write-Host ""
    
    $iteration = 1
    while ($true) {
        Write-Host "=== Update #$iteration - $(Get-Date -Format 'HH:mm:ss') ===" -ForegroundColor Green
        
        # Quick power metrics
        try {
            $cpu = Get-Counter "\Processor(_Total)\% Processor Time" -ErrorAction SilentlyContinue
            $cpuUsage = [math]::Round($cpu.CounterSamples[0].CookedValue, 1)
            
            $memory = Get-WmiObject -Class Win32_OperatingSystem
            $memUsed = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 1)
            
            # Estimate power based on current usage
            $estimatedPower = 50 + (85 * ($cpuUsage / 100)) + 20 + 5 + 30
            
            Write-Host "CPU Usage: $cpuUsage% | Memory Usage: $memUsed% | Estimated Power: ~$([math]::Round($estimatedPower, 1))W"
            
        } catch {
            Write-Host "Error in monitoring loop: $($_.Exception.Message)"
        }
        
        Start-Sleep -Seconds 5
        $iteration++
    }
}

# Main execution
Get-PowerInfo

Write-Host ""
$choice = Read-Host "Would you like to start continuous monitoring? (y/n)"
if ($choice -eq 'y' -or $choice -eq 'Y') {
    Start-ContinuousMonitoring
} else {
    Write-Host ""
    Write-Host "Monitoring complete. Run this script again for updated information." -ForegroundColor Green
    Write-Host ""
    Write-Host "Pro tip: For the most accurate power measurements, consider using:" -ForegroundColor Cyan
    Write-Host "- Hardware power meters (Kill A Watt, smart plugs with power monitoring)"
    Write-Host "- Software like HWiNFO64 for detailed component power readings"
    Write-Host "- Built-in laptop battery reports: 'powercfg /batteryreport'"
}