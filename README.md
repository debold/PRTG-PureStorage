# PRTG-PureStorage
You can use this script to monitor some essential information about your PURE storage system using PRTG EXE/Advanced sensor. For this to work you need to install the PURE PowerShell module from PSGallery onto your PRTG probe using the following command:

`Install-Module -Name PureStoragePowerShellSDK`

As PRTG runs in 32-bit environment (even on 64-bit Windows installation), be sure to install the module in **32-bit PowerShell**, else it will not work.

After installation is complete, save this script to the **Custom Sensors\EXEXML** file on your probe servers. Now create a new *EXE/Advanced" sensor and select the PowerShell file you just saved from the dropdown. You need to provide two parameters:
1. **StorageAddress**
This is the IP address or hostname of your PURE storage system, which can be fetched from the parent object in your PRTG tree using the variable `%host`
2. **ApiToken**
Instead of providing a username and password, you can retrieve an API token for a user account (READ access to PURE is sufficient) from your PURE storage webconsole. Use this token here to authenticate the scripts requests.

**Example:** `-ApiToken "abcde-a9d7a87-000000" -StorageAddress %host`

The sensor will provide the following channels:
1. **Hardware ok count** The script retrieves the count of devices that report the status **ok**.
2. **Hardware not installed count** This is the number of devices, reporting **not installed**.
3. **Hardware NOT ok count** Every other hardware state except for OK and NOT INSTALLED will be counted here.
4. **Volumes (Bytes** Reports the size in TB assigned to volumes in the PURE storage system.
5. **Total used space (Bytes)** is the really occupied storage on the system.
6. **Total sorage capacity (Bytes)** represents the total capacity of the system. This value should only change, if there is a hardware extension.
7. **Free space (Bytes)** shows the total capacity reduced by the total used storage in TB.
8. **Free space (%)** The free space in percent.
9. **IOPS - Writes/sec** shows the current write operations per second.
10. **IOPS - Reads/sec** shows the current read operations per second.
11. **Write latency (ms)** represents the time in milliseconds, the write IO currently takes.
12. **Read latency (ms)** represents the time in milliseconds, the read IO currently takes.

Further reading:
https://www.team-debold.de/2018/09/09/prtg-monitoring-your-pure-storage-system/
