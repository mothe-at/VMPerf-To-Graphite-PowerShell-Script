#VMPerf-To-Graphite
A comprehensive PowerShell Script to read Virtual Machine statistics from vCenter and send the results to Graphite/Grafana. It pulls Disk and CPU metrics from the "Realtime" statistics in VCenter, aggregates the data and sends them to carbon (which is the data-receiver for Graphite). It is intended to run as a background task forever. It contains various error checking mechanisms and will not stop, even if VCenter or the Graphite servers are rebooted.

Please check all the available parameters with Get-Help -full.

![](http://rettl.org/scripts/grafana1-full.png)

## Features
Blabla
## Prerequisites
- Make sure you have installed VMWare PowerCLI v5.8 or above on the machine where the script will run.
- Check the [Version of PowerShell] (http://stackoverflow.com/questions/1825585/determine-installed-powershell-version) and update it to [PowerShell v4] (https://www.microsoft.com/en-US/download/details.aspx?id=40855) or above (POSH 2.x will cause problems, the Script will abort if the PowerShell Version is <4).
- Check if the ["Statistics Level" in VCenter] (http://rettl.org/scripts/vcenter.png) for the shortest period is set to "Level 2" or higher.
- Download the VMPerf-To-Graphite.ps1 script and save it on your server.
- Open a new PowerShell Window, read the documentation of the script carefully and discover all the various options and parameters.

## How to use the script?
Schallala
