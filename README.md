## Key Features:

1. **Battery Information** (for laptops):
   - Shows battery status, charge level, and estimated power draw
   - Calculates current power consumption when on battery

2. **Processor Monitoring**:
   - Current CPU usage and clock speeds
   - Performance metrics

3. **System Resource Usage**:
   - RAM utilization
   - Disk activity
   - Network activity

4. **Power Consumption Estimates**:
   - Breaks down estimated power usage by component
   - Provides total system power estimate
   - Includes base system, CPU, RAM, storage, and GPU estimates

5. **Continuous Monitoring Option**:
   - Real-time updates every 5 seconds
   - Shows current CPU/memory usage and power estimates

## How to Use:

1. **Save the script** as `PowerMonitor.ps1`
2. **Run it in PowerShell** (you may need to run as Administrator for some features)
3. **Set execution policy** if needed: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Important Notes:

- The power estimates are approximations based on typical component power draws
- For laptops, it can provide more accurate readings using battery data
- GPU power varies dramatically (20W idle to 300W+ gaming)
- For precise measurements, consider using hardware power meters

The script provides both a one-time snapshot and continuous monitoring options, making it easy to understand your PC's power consumption patterns under different workloads.
