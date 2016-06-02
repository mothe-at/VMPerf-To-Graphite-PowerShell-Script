#VMPerf-To-Graphite
A comprehensive PowerShell Script to read Virtual Machine statistics from vCenter and send the results to Graphite/Grafana. It pulls Disk and CPU metrics from the "Realtime" statistics in VCenter, aggregates the data and sends them to carbon (which is the data-receiver for Graphite). It is intended to run as a background task forever. It contains various error checking mechanisms and will not stop, even if VCenter or the Graphite servers are rebooted.

Please check all the available parameters with Get-Help -full.

![](http://rettl.org/scripts/grafana1-full.png)

## Prerequisites
- Make sure you have installed VMWare PowerCLI v5.8 or above on the machine where the script will run.
- Check the [Version of PowerShell] (http://stackoverflow.com/questions/1825585/determine-installed-powershell-version) and update it to [PowerShell v4] (https://www.microsoft.com/en-US/download/details.aspx?id=40855) or above (POSH 2.x will cause problems, the Script will abort if the PowerShell Version is <4).
- Check if the ["Statistics Level" in VCenter] (http://rettl.org/scripts/vcenter.png) for the shortest period is set to "Level 2" or higher.
- Download the VMPerf-To-Graphite.ps1 script and save it on your server.
- Open a new PowerShell Window, read the documentation of the script carefully and discover all the various options and parameters.

## How to use the script?
### Modes of Operation
Usually you would like to collect statistics 24/7, having the most accurate numbers in Graphite/Grafana. Remember that collecting data from VSphere and feeding them into Graphite a) takes some time, depending on the size of your deployment, the performance of your VCenter Server, the network connection speed, etc. and b) takes some resources, CPU, memory, storage.

Pulling data from VCenter is done by an API which is good, but not really ultra-fast. A collection of 1.000 VMs can take a few minutes, running the script every 10 seconds makes no sense. But this is not a big problem, even if you pull data just every 30 minutes, you will find statistics data much more granular in your graphs. If the values are collected, sending them to Carbon is just a matter of seconds or even less, even over slow WAN links.

A good practice could be pulling data every 15 minutes for small/medium deployments (500 VMs or below) or 30 minutes for larger scale enterprises.

There are two ways you can infinitely run the script:

##### Use Windows Task Scheduler to call the script every n minutes
This is the best practice. You call the script in your desired interval with Windows Task Scheduler or any other scheduling service of your choice. Calling it with the appropriate parameters will let the script run forever, even if something went wrong with PowerShell, PowerCLI or something else.

To achive this, the script must "know" about the last time statistics were successfully collected from VCenter. If so, the script will try to pull all statistics data from the time of the last run up till now. To remember date and time of the last poll the script will save this information in an XML file. You have to specify the path and filename of this XLM file with the parameter `-FromLastPoll <Filename>`. Lets say you are pulling data from several different VCenter Servers, you have to specify a unique filename for each job.

You also have to tell the script just to run once and then quit using the `-Iterations 1` parameter.


Calling the script could look something like this:

`PS C:\>VMPerf-To-Graphite.ps1 -Verbose -Server myvcenter.vienna.acme.com -User ACME\StatsReader -Password mypass
-Graphiteserver graphite1.it.acme.com -Iterations 1 -FromLastPoll Vienna_Poll.xml`

It does not matter if you wait 10 minutes or 10 hours until you run the script the next time, it will gather all metrics starting at the time of the last succesfull poll. But remember that VCenter only stores real-time data for the last 24 hours by default!

##### Call the script and let it control the iterations and sleep-times
This is the second way, you call the script once without the `-Iterations` parameter and it will run forever (or until you cancel it). Here you can specify the `-Sleepseconds <Int32>` parameter which controls the time it waits after each iteration.

The script has extensive error handling but nevertheless it could happen that a PowerShell or PowerCLI process unexpetedly stopps or, even worse, hangs and does not return control back to the script. It could take hours until you realize that no data is collected for a certain amount of time and, murphy sais, you will for sure need this data desperately.

To call the script to run infinitely, waiting 5 minutes between each iteration, call this:

`PS C:\>VMPerf-To-Graphite.ps1 -Verbose -Server myvcenter.vienna.acme.com -User ACME\StatsReader -Password mypass
-Sleepseconds 300 -Graphiteserver graphite1.it.acme.com -Group Vienna`

================

## Syntax
`VMPerf-To-Graphite.ps1 [[-Server] <String>] [[-User] <String>] [[-Password] <String>] [[-Protocol] <String>] [[-Datacenter] <String[]>] [[-Cluster] <String[]>] [[-Graphiteserver] <String>] [[-Graphiteserverport] <Int32>] [[-Group] <String>] [[-Sleepseconds] <Int32>] [[-Iterations] <Int32>] [[-FromLastPoll] <String>] [-Whatif] [[-EventLogLevel] <String>] [<CommonParameters>]`

### Parameters and Description
```
-Server <String>
    Specifies the IP address or the DNS name of the vCenter server to which you want to connect.

    Required?                    false
    Position?                    1
    Default value                your_default_vcenter_server
    Accept pipeline input?       false
    Accept wildcard characters?  false

-User <String>
    Specifies the user name you want to use for authenticating with the vCenter server.

    Required?                    false
    Position?                    2
    Default value                vcenter_user
    Accept pipeline input?       false
    Accept wildcard characters?  false

-Password <String>
    Specifies the password you want to use for authenticating with the vCenter server.

    Required?                    false
    Position?                    3
    Default value                vcenter_password
    Accept pipeline input?       false
    Accept wildcard characters?  false

-Protocol <String>
    Specifies the Internet protocol you want to use for the connection. It can be either http or https.

    Required?                    false
    Position?                    4
    Default value                https
    Accept pipeline input?       false
    Accept wildcard characters?  false

-Datacenter <String[]>
    Specifies the VMWare Datacenters you want to receive data from. Default is to read all Clusters managed by
    VCenter server.

    Required?                    false
    Position?                    5
    Default value                *
    Accept pipeline input?       false
    Accept wildcard characters?  false

-Cluster <String[]>
    Specifies the VMWare Clusters you want to receive data from. Default is to read all Clusters managed by
    VCenter server or, if -Datacenter is specified, all Clusters in this Datacenter.

    Required?                    false
    Position?                    6
    Default value                *
    Accept pipeline input?       false
    Accept wildcard characters?  false

-Graphiteserver <String>
    Specifies the IP address or the DNS name of the Graphite server to which you want to connect.

    Required?                    false
    Position?                    7
    Default value                your_default_grafana_server
    Accept pipeline input?       false
    Accept wildcard characters?  false

-Graphiteserverport <Int32>
    Specifies the port on the Graphite server you want to use for the connection. Defaults to 2003.

    Required?                    false
    Position?                    8
    Default value                2003
    Accept pipeline input?       false
    Accept wildcard characters?  false

-Group <String>
    Specifies the Group, an additional prefix for the metrics path in Graphite. The metrics path will be
    "vmperf.<Group>."

    Required?                    false
    Position?                    9
    Default value                Default
    Accept pipeline input?       false
    Accept wildcard characters?  false

-Sleepseconds <Int32>
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

-Iterations <Int32>
    Specifies the number of iterations. 0 = indefinitely.

    Required?                    false
    Position?                    11
    Default value                0
    Accept pipeline input?       false
    Accept wildcard characters?  false

-FromLastPoll <String>
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

-Whatif [<SwitchParameter>]
    Indicate that the cmdlet will process but will NOT send any metrics to Graphite, instead display a list of
    metrics that would be sent to Graphite.

    Required?                    false
    Position?                    named
    Default value                False
    Accept pipeline input?       false
    Accept wildcard characters?  false

-EventLogLevel <String>
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

## Examples
### Example 1
`PS C:\>VMPerf-To-Graphite.ps1 -Verbose`

Use default values from within this script and display the status output on the screen.

### Example 2
`PS C:\>VMPerf-To-Graphite.ps1 -Verbose -Server myvcenter.vienna.acme.com -User ACME\StatsReader -Password mypass
-Sleepseconds 300 -Graphiteserver graphite1.it.acme.com -Group Vienna`

Read the counters from the VCenter server myvcenter.vienna.acme.com, send the metrics to graphite1.it.acme.com
with a metrics path of "vmperf.Vienna." and then wait 5 minutes before the next iteration.

### Example 3
`PS C:\>VMPerf-To-Graphite.ps1 -Verbose -Server myvcenter.vienna.acme.com -User ACME\StatsReader -Password mypass
-Sleepseconds 300 -Graphiteserver graphite1.it.acme.com -Group Vienna -Cluster TESTDEV`

Read the counters from Cluster TESTDEV in the VCenter server myvcenter.vienna.acme.com, send the metrics to
graphite1.it.acme.com with a metrics path of "vmperf.Vienna." and then wait 5 minutes before the next iteration.

### Example 4
`PS C:\>VMPerf-To-Graphite.ps1 -Verbose -Iterations 1 -WhatIf | Out-GridView`

Run the cmdlet just once, but do not send the metrics to Graphite, instead open a window and display the results.

### Example 5
`PS C:\>VMPerf-To-Graphite.ps1 -Verbose -Server myvcenter.vienna.acme.com -User ACME\StatsReader -Password mypass
-Graphiteserver graphite1.it.acme.com -Iterations 1 -FromLastPoll Vienna_Poll.xml`

Run the cmdlet just once. Write the date and time of the Poll to Vienna_Poll.xml. The next time the script runs,
it will read the file and gather the metrics from VCenter starting at the last poll.


