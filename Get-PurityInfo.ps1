<#
    .SYNOPSIS
    Retrieves basic monitoring information from a PURE storage device for PRTG monitoring.

    .DESCRIPTION
    This script uses the PURE storage Powershell module to get information, like health state, capacity and performance values
    from the PURE storage device and sends to to PRTG in json format.

    .PARAMETER ApiToken 
    This token is used for the REST connection to PURE instead of username and password. It can be generated using the PURE storage 
    web interface.

    .PARAMETER StorageAddress
    The StorageAddress represents the IP address or DNS name of the PURE storage device. In PRTG use the variable %host to fill in the
    hostname or ip of the parent device.

    .EXAMPLE
    Sample call from PRTG (EXE/Advanced sensor)
    Get-PurityInfo.ps1 -ApiToken "abcde-a9d7a87-000000" -StorageAddress %host

    .NOTES
    You need to install the PURE PowerShell module from PSGallery in your 32-bit(!) PowerShell environment using the following command.

    Install-Module -Name PureStoragePowerShellSDK

    And be sure to set your execution policy (also in 32-bit PowerShell) to unrestricted.

    https://support.purestorage.com/Solutions/Microsoft_Platform_Guide/a_Windows_PowerShell/aa1_Install_PowerShell_SDK_using_PowerShell_Gallery

    Author:  Marc Debold
    Version: 1.0
    Version History:
        1.0  04.09.2018  Initial release
#>
[CmdletBinding()] param(
    [Parameter()] $ApiToken = $null,
    [Parameter()] $StorageAddress = $null
)

# Function to return json formatted error message to PRTG
function Raise-PrtgError {
    [CmdletBinding()] param(
        [Parameter(Mandatory = $true)] $Message
    )
    @{
        "prtg" = @{
            "error" = 1;
            "message" = $Message
        }
    } | ConvertTo-Json
    Exit
}

# Check API token
if ($ApiToken -eq $null) {
    Raise-PrtgError -Message "API token missing. Please supply Pure API token in function call"
}

# Check PURE storage address
if ($StorageAddress -eq $null) {
    Raise-PrtgError -Message "StorageAddress missing. Please supply PURE storage IP or DNS name in function call"
}

# Try to connect to PURE storage system
try {
    $FlashArray = New-PfaArray -EndPoint $StorageAddress -ApiToken $ApiToken -IgnoreCertificateError -ErrorAction Stop
} catch {
    Raise-PrtgError -Message "Could not connect to PURE storage using address '$StorageAddress'. Error code: $($_.Exception.Message)"
}

# Retrieve hardware status information
try {
    $HardwareState = Get-PfaAllHardwareAttributes -Array $FlashArray -ErrorAction Stop
} catch {
    Raise-PrtgError -Message "Could not retrieve hardware info from PURE storage. Error code: $($_.Exception.Message)"
}

# Retrieve IO performance values
try {
    $Performance = Get-PfaArrayIOMetrics -Array $FlashArray -ErrorAction Stop
} catch {
    Raise-PrtgError -Message "Could not retrieve IO metrics from PURE storage. Error code: $($_.Exception.Message)"
}

# Retrieve storage capacity info
try {
    $Space = Get-PfaArraySpaceMetrics -Array $FlashArray -ErrorAction Stop
} catch {
    Raise-PrtgError -Message "Could not retrieve capacity info from PURE storage. Error code: $($_.Exception.Message)"
}

# Format and output the information gathered
# Eventually format floats in german localization?
#$language = New-Object System.Globalization.CultureInfo("de-DE")
$HwGroup = $HardwareState | Group-Object -Property "status" | Select-Object Name,Count
@{
    "prtg" = @{
        "result" = @(
            @{
                "channel" = "Hardware ok count";
                "value" = ($HwGroup | ? { $_.Name -eq "ok" }).Count;
                "unit" = "Count"
            };
            @{
                "channel" = "Hardware not installed count";
                "value" = ($HwGroup | ? { $_.Name -eq "not_installed" }).Count;
                "unit" = "Count"
            };
            @{
                "channel" = "Hardware NOT ok count";
                "value" = ($HwGroup | ? { $_.Name -notin @("ok", "not_installed") }).Count;
                "unit" = "Count";
                "limitmode" = 1;
                "limitmaxerror" = 1;
                "limiterrormsg" = "At least 1 hardware component has a critical state"
            };
            @{
                "channel" = "Volumes (Bytes)";
                "value" = $Space.volumes/1TB;
                "unit" = "Custom";
                "customunit" = "TB";
                "float" = 1;
                "DecimalMode" = "3"
            };
            @{
                "channel" = "Total used space (Bytes)";
                "value" = $Space.total/1TB;
                "unit" = "Custom";
                "customunit" = "TB";
                "float" = 1;
                "DecimalMode" = 3
            };
            @{
                "channel" = "Total sorage capacity (Bytes)";
                "value" = $Space.capacity/1TB;
                "unit" = "Custom";
                "customunit" = "TB";
                "float" = 1;
                "DecimalMode" = 3
            };
            @{
                "channel" = "Free space (Bytes)";
                "value" = ($Space.capacity - $Space.total)/1TB;
                "unit" = "Custom";
                "customunit" = "TB";
                "float" = 1;
                "DecimalMode" = 3
            };
            @{
                "channel" = "Free space (%)";
                "value" = ($Space.capacity - $Space.total)/$Space.capacity*100
                "unit" = "Percent";
                "float" = 1;
                "limitmode" = 1;
                "limitminerror" = 10;
                "limiterrormsg" = "Free space has reached critical level";
                "limitminwarning" = 20;
                "limitwarningmsg" = "Free space has dropped below warning level"
            };
            @{
                "channel" = "IOPS - Writes/sec";
                "value" = $Performance.writes_per_sec;
                "unit" = "Custom";
                "customunit" = "IO/s";
            };
            @{
                "channel" = "IOPS - Reads/sec";
                "value" = $Performance.reads_per_sec;
                "unit" = "Custom";
                "customunit" = "IO/s";
            };
            @{
                "channel" = "Write latency (ms)";
                "value" = $Performance.usec_per_write_op/1000;
                "unit" = "Custom";
                "customunit" = "ms";
                "float" = 1;
                "decimalmode" = 3
            };
            @{
                "channel" = "Read latency (ms)";
                "value" = $Performance.usec_per_read_op/1000;
                "unit" = "Custom";
                "customunit" = "ms";
                "float" = 1;
                "decimalmode" = 3
            };
)
    }
} | ConvertTo-Json -Depth 3