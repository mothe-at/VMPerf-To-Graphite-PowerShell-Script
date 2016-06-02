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
### Syntax
`VMPerf-To-Graphite.ps1 [[-Server] <String>] [[-User] <String>] [[-Password] <String>] [[-Protocol] <String>] [[-Datacenter] <String[]>] [[-Cluster] <String[]>] [[-Graphiteserver] <String>] [[-Graphiteserverport] <Int32>] [[-Group] <String>] [[-Sleepseconds] <Int32>] [[-Iterations] <Int32>] [[-FromLastPoll] <String>] [-Whatif] [[-EventLogLevel] <String>] [<CommonParameters>]`

### Parameters and Description
```
\-Server <String>
    Specifies the IP address or the DNS name of the vCenter server to which you want to connect.

    Required?                    false
    Position?                    1
    Default value                your_default_vcenter_server
    Accept pipeline input?       false
    Accept wildcard characters?  false

\-User <String>
    Specifies the user name you want to use for authenticating with the vCenter server.

    Required?                    false
    Position?                    2
    Default value                vcenter_user
    Accept pipeline input?       false
    Accept wildcard characters?  false

\-Password <String>
    Specifies the password you want to use for authenticating with the vCenter server.

    Required?                    false
    Position?                    3
    Default value                vcenter_password
    Accept pipeline input?       false
    Accept wildcard characters?  false

\-Protocol <String>
    Specifies the Internet protocol you want to use for the connection. It can be either http or https.

    Required?                    false
    Position?                    4
    Default value                https
    Accept pipeline input?       false
    Accept wildcard characters?  false

\-Datacenter <String[]>
    Specifies the VMWare Datacenters you want to receive data from. Default is to read all Clusters managed by
    VCenter server.

    Required?                    false
    Position?                    5
    Default value                *
    Accept pipeline input?       false
    Accept wildcard characters?  false

\-Cluster <String[]>
    Specifies the VMWare Clusters you want to receive data from. Default is to read all Clusters managed by
    VCenter server or, if -Datacenter is specified, all Clusters in this Datacenter.

    Required?                    false
    Position?                    6
    Default value                *
    Accept pipeline input?       false
    Accept wildcard characters?  false

\-Graphiteserver <String>
    Specifies the IP address or the DNS name of the Graphite server to which you want to connect.

    Required?                    false
    Position?                    7
    Default value                your_default_grafana_server
    Accept pipeline input?       false
    Accept wildcard characters?  false

\-Graphiteserverport <Int32>
    Specifies the port on the Graphite server you want to use for the connection. Defaults to 2003.

    Required?                    false
    Position?                    8
    Default value                2003
    Accept pipeline input?       false
    Accept wildcard characters?  false

\-Group <String>
    Specifies the Group, an additional prefix for the metrics path in Graphite. The metrics path will be
    "vmperf.<Group>."

    Required?                    false
    Position?                    9
    Default value                Default
    Accept pipeline input?       false
    Accept wildcard characters?  false

\-Sleepseconds <Int32>
    Specifies the number of seconds to wait between iterations. The counter starts after the last statistics have
    been sent to Graphite.
    Note that VCenter is collecting its performance statistics every 20 seconds and saves an average of the
    collected counters. It makes no sense to specify a value below 20 seconds here. The script reads the so called
    "Realtime" counters from VCenter which will be kept there for one hour. So do not use anything above 3600
    seconds.
    The script requests all statistics data from VCenter server since the last time they were requested,
    regardless of how long the Sleepseconds parameter was set. You wont miss any data.

    Required?                    false
    Position?                    10
    Default value                60
    Accept pipeline input?       false
    Accept wildcard characters?  false

\-Iterations <Int32>
    Specifies the number of iterations. 0 = indefinitely.

    Required?                    false
    Position?                    11
    Default value                0
    Accept pipeline input?       false
    Accept wildcard characters?  false

\-FromLastPoll <String>
    Optional path and name of an .xml file where the date and time of the last poll will be saved.
    If the file does not exist, it will be created and overwritten after each poll.
    If this parameter is set, the script will try to receive all metrics from the VCenter Server starting at the
    date and time of the last poll up to the most recent data (Real-Time).
    This is useful if you want to schedule the script externally (with Task Scheduler, for instance) and you want
    to use the "-Iterations 1" parameter.
    But be careful, VCenter stores the Real-Time statistics just for a limited number of time (1 day per default).

    Required?                    false
    Position?                    12
    Default value
    Accept pipeline input?       false
    Accept wildcard characters?  false

\-Whatif [<SwitchParameter>]
    Indicate that the cmdlet will process but will NOT send any metrics to Graphite, instead display a list of
    metrics that would be sent to Graphite.

    Required?                    false
    Position?                    named
    Default value                False
    Accept pipeline input?       false
    Accept wildcard characters?  false

\-EventLogLevel <String>
    Set the Log-Level for writing events to the Windows Aplication log. Valid values are Error, Warning,
    Information, and None. The default value is Warning.
    Note that if you like to use logging to the Windows Event Log, you have to run this script at least once with
    administrative privileges on this computer!

    Required?                    false
    Position?                    13
    Default value                Warning
    Accept pipeline input?       false
    Accept wildcard characters?  false

<CommonParameters>
    This cmdlet supports the common parameters: Verbose, Debug,
    ErrorAction, ErrorVariable, WarningAction, WarningVariable,
    OutBuffer, PipelineVariable, and OutVariable. For more information, see
    about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).
```



