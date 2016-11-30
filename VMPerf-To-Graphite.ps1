<#
.SYNOPSIS
	Read Virtual Machine statistics from vCenter and send the results to Graphite.
.DESCRIPTION
   The script uses VMWare PowerCLI to connect to a vCenter Server, read certain performance metrics from all running virtual machines and sends the results to Graphite.
   Note that only IOs are measured which are performed on a Datastore. Neither RAW Disks nor iSCSI or NFS monuted devices from INSIDE a VM are counted.
   Without the "-Verbose" switch, no output is generated, except errors.
   Note that VMWare PowerCLI has to be installed properly on the system where the script runs.
.EXAMPLE
VMPerf-To-Graphite.ps1 -Verbose
Use default values from within this script and display the status output on the screen.
.EXAMPLE
VMPerf-To-Graphite.ps1 -Verbose -Server myvcenter.vienna.acme.com -User ACME\StatsReader -Password mypass -Graphiteserver graphite1.it.acme.com -Iterations 1 -FromLastPoll Vienna_Poll.xml
Run the cmdlet just once. Write the date and time of the Poll to Vienna_Poll.xml. The next time the script runs, it will read the file and gather the metrics from VCenter starting at the last poll.
.EXAMPLE
VMPerf-To-Graphite.ps1 -Verbose -Server myvcenter.vienna.acme.com -User ACME\StatsReader -Password mypass -Graphiteserver graphite1.it.acme.com,graphdev.it.acme.com:62033 -Iterations 1 -FromLastPoll Vienna_Poll.xml
Same as above but send the metrics to two servers, graphite1.it.acme.com at (default) port 2003 and graphdev.it.acme.com on port 62033.
.EXAMPLE
VMPerf-To-Graphite.ps1 -Verbose -Server myvcenter.vienna.acme.com -User ACME\StatsReader -Password mypass -Sleepseconds 300 -Graphiteserver graphite1.it.acme.com -Group Vienna
Read the counters from the VCenter server myvcenter.vienna.acme.com, send the metrics to graphite1.it.acme.com with a metrics path of "vmperf.Vienna." and then wait 5 minutes before the next iteration.
.EXAMPLE
VMPerf-To-Graphite.ps1 -Verbose -Server myvcenter.vienna.acme.com -User ACME\StatsReader -Password mypass -Sleepseconds 300 -Graphiteserver graphite1.it.acme.com -Group Vienna -Cluster TESTDEV
Read the counters from Cluster TESTDEV in the VCenter server myvcenter.vienna.acme.com, send the metrics to graphite1.it.acme.com with a metrics path of "vmperf.Vienna." and then wait 5 minutes before the next iteration.
.EXAMPLE
VMPerf-To-Graphite.ps1 -Verbose -Iterations 1 -WhatIf | Out-GridView
Run the cmdlet just once, but do not send the metrics to Graphite, instead open a window and display the results.
.NOTES
This work is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
It is free-of-charge and it comes without any warranty, to the extent permitted by applicable law.
Matthias Rettl, 2016
Script Version 1.5.2 (2016-11-30)
.LINK
https://github.com/mothe-at/VMPerf-To-Graphite-PowerShell-Script
http://rettl.org/scripts/
http://creativecommons.org/licenses/by-nc-sa/4.0/
#>
[CmdletBinding()]
param(
	# Specifies the IP address or the DNS name of the vCenter server to which you want to connect.
    [string]$Server = "your_default_vcenter_server",
	# Specifies the user name you want to use for authenticating with the vCenter server.
    [string]$User = "vcenter_user", 
	# Specifies the password you want to use for authenticating with the vCenter server.
    [string]$Password = "vcenter_password",
	# Specifies the Internet protocol you want to use for the connection. It can be either http or https.
    [ValidateSet("http","https")][string]$Protocol = "https",
	# Specifies the VMWare Datacenters you want to receive data from. Default is to read all Clusters managed by VCenter server.
    [string[]]$Datacenter = "*",
	# Specifies the VMWare Clusters you want to receive data from. Default is to read all Clusters managed by VCenter server or, if -Datacenter is specified, all Clusters in this Datacenter.
    [string[]]$Cluster = "*",
	# Specifies one or more (separated by comma) IP addresses or the DNS names of the Graphite servers to which you want to connect.
	# You can also add the Portnumber to each Server like "grafana.acme.com:2003"
	[string[]]$Graphiteserver = "your_default_grafana_server",
	# Specifies the port on the Graphite server you want to use for the connection. Defaults to 2003.
	# You can also add the portnumber to the servers hostname or IP address in the -Graphiteserver parameter.
	[ValidateRange(1024,65536)][int]$Graphiteserverport = 2003,
	# Specifies the Group, an additional prefix for the metrics path in Graphite. The metrics path will be "vmperf.<Group>."
    [string]$Group = "Default",
	# Specifies the number of iterations. 0 = indefinitely.
	[ValidateRange(0,65536)][int]$Iterations = 0,
	# Optional path and name of an .xml file where the date and time of the last poll will be saved.
	# If the file does not exist, it will be created and overwritten after each poll.
	# If this parameter is set, the script will try to receive all metrics from the VCenter Server starting at the date and time of the last poll up to the most recent data (Real-Time).
	# This is useful if you want to schedule the script externally (with Task Scheduler, for instance) and you want to use the "-Iterations 1" parameter.
	# But be careful, VCenter stores the Real-Time statistics just for a limited number of time (1 day per default).
	[string]$FromLastPoll = "",
	# Specifies the number of seconds to wait between iterations. The counter starts after the last statistics have been sent to Graphite. 
    # Note that VCenter is collecting its performance statistics every 20 seconds and saves an average of the collected counters. It makes no sense to specify a value below 20 seconds here. The script reads the so called "Realtime" counters from VCenter which will be kept there for one hour. So do not use anything above 3600 seconds.
    # The script requests all statistics data from VCenter server since the last time they were requested, regardless of how long the Sleepseconds parameter was set. You wont miss any data.
	[ValidateRange(0,3600)][int]$Sleepseconds = 60, 
    # Indicate that the cmdlet will process but will NOT send any metrics to Graphite, instead display a list of metrics that would be sent to Graphite.
    [Switch]$Whatif,
    # Set the Log-Level for writing events to the Windows Aplication log. Valid values are Error, Warning, Information, and None. The default value is Warning.
    # Note that if you like to use logging to the Windows Event Log, you have to run this script at least once with administrative privileges on this computer!
    [ValidateSet("None","Information","Warning","Error")][String]$EventLogLevel = "Warning"
)



# ---------------------------------------
# Write Events to the Windows Event Log
# ---------------------------------------
function Write-To-Windows-EventLog ($severity, $id, $message) {
$levels="None","Information","Warning","Error"
$ell=[array]::IndexOf($levels,$EventLogLevel)
$sev=[array]::IndexOf($levels,$severity)
$logsouce=""

if (($ell -ne 0) -AND ($sev -ge $ell)) {
    $myscriptname = split-path $MyInvocation.PSCommandPath -Leaf
    $myscriptfull = $MyInvocation.ScriptName
    $l = [Environment]::NewLine

    New-EventLog –LogName Application –Source $myscriptname -ErrorAction SilentlyContinue

    $msg = $message + $l+$l + "Called by:" + $l + "$myscriptfull -Server $server -User $user -Password [**HIDDEN**] -Protocol $protocol -Datacenter $datacenter -Cluster $cluster -Group $Group -Graphiteserver $Graphiteserver -Graphiteserverport $Graphiteserverport -Sleepseconds $Sleepseconds -Iterations $Iterations -FromLastPoll $FromLastPoll -WhatIf:`$$Whatif -EventLogLevel $EventLogLevel"
    Write-EventLog –LogName Application –Source $myscriptname –EntryType $severity –EventID $id –Message $msg -Category 0

}


}

function checkiporhostname($Name,$ipho,$stoponerror) {

try {
    $ip = [System.Net.Dns]::GetHostAddresses($ipho) | select-object IPAddressToString -expandproperty  IPAddressToString
    if($ip.GetType().Name -eq "Object[]")
    {
        #If we have several ip's for that address, let's take first one
        $ip = $ip[0]
        return $ip
    }
} catch
    {
    $msg = "Unable to resolve $Name hostname or IP address $ipho. Maybe $ipho is a wrong hostname or IP!"
    Write-Verbose "$(Get-Date -format G) $msg"
    Write-To-Windows-EventLog "Error" 3006 $msg
    if ($stoponerror) { Exit } Else { Return "" }
    }

}



# ---------------------------------------
# Send and array with metrics to Graphite
# ---------------------------------------
function sendtographite ($metrics)
{
$maxretries = 10	# Maximum number of retries to connect to a Graphite server. Only applicable if multiple servers are specified. With only 1 server it will try forever.
$aservers = $graphiteserver -split ' '

foreach($s in 0..($aservers.count-1)){

	$cserver = $aservers[$s]
	if ($cserver.contains(":")) 
		{
			$atmp = $cserver -split ':'
			$cserver = $atmp[0]
			$cport = $atmp[1]
		}
		else
		{
			$cport = $graphiteserverport
		}
    
	$msg = "Sending $scount metrics for $vcount VMs of iteration # $iteration to Graphite server $cserver`:$cport"
    Write-Verbose "$(Get-Date -format G) $msg"
	Write-To-Windows-EventLog "Information" 1005 $msg
	$trycount = 1
	do {
		$iserr = $false
		Try
		{
			$socket = new-object system.net.sockets.tcpclient
			
			$socket.connect($cserver, $cport)
			
			$stream = $socket.getstream()
			$writer = new-object system.io.streamwriter($stream)
			
			foreach($i in 0..($metrics.count-1)){
			$writer.writeline($metrics[$i])
			}
			
			$writer.flush()
			$writer.close()
			$stream.close()
			$socket.close()
		}
		Catch
		{
			$IsErr = $true
			$ErrorMessage = $_.Exception.Message
			$FailedItem = $_.Exception.ItemName
			$msg = "Connection to $cserver`:$cport failed with $ErrorMessage! Will retry in 10 seconds"
			Write-Warning "$(Get-Date -format G) $msg"
			Write-To-Windows-EventLog "Warning" 2007 $msg
			Start-Sleep -s 10
			
			if (($trycount -ge $maxretries) -and ($aservers.count -gt 1)) {
				# Giving up this Server, it does not work, lets try the other one(s)
				$msg = "Giving up connection to $cserver`:$cport after $trycount failed attempts"
				Write-Error "$(Get-Date -format G) $msg"
				Write-To-Windows-EventLog "Error" 2007 $msg
				$IsErr = $false
			}
			
			$trycount++
			
		}
	
	} while ($IsErr)
}

}


# -----------------------------
# Connect to the VCenter Server
# -----------------------------
function connectviserver($stoponerror)
{

if ($stoponerror) { $erroraction = "Stop" } else { $erroraction = "Continue" }

do {
    $msg = "Connecting to vCenter Server $server as $user"
    Write-Verbose "$(Get-Date -format G) $msg"
    Write-To-Windows-EventLog "Information" 1002 $msg

    [void] ( $vcc = Connect-VIServer -Server $server -User $user -Password $password -Protocol $protocol -ErrorAction $erroraction -ErrorVariable err -Verbose:$false )

    if ($err) {
    	$msg = "Connection to $server failed! Will retry in 10 seconds"
       	Write-Warning "$(Get-Date -format G) $msg"
        Write-To-Windows-EventLog "Error" 3002 $msg
    	Start-Sleep -s 10
    	}
} while ($err)

[void] ($global:vmdatacenter = Get-Datacenter -Server $vcc -Name $Datacenter -ErrorAction Stop -Verbose:$false)
[void] ($global:vmcluster = Get-Cluster  -Server $vcc -Name $Cluster -Location $global:vmdatacenter -ErrorAction Stop -Verbose:$false)

return $vcc
}

function weighted_average($acount,$avalues) {
    for ($i=0; $i -lt $acount.Length; $i++) {
        $p += ($acount[$i]*$avalues[$i])
        $s += $acount[$i]
    }

    if ($s -gt 0) {
        $wa = $p/$s
    } else {
        $wa = 0
    }
    return( $wa )
}

# -----------------------------------------------------------------------------------------------------------------------------------------
# -- MAIN PROCEDURE -----------------------------------------------------------------------------------------------------------------------
# -----------------------------------------------------------------------------------------------------------------------------------------

if (!$Group.EndsWith(".")) {$Group = $Group+"."}
$prefix = "vmperf." + $Group
$global:vmdatacenter = $null
$global:vmcluster = $null

# Check PowerShell Version and exit if it is something below Version 4.0
$psvermaj = $PSVersionTable.PSVersion.Major
$psvermin = $PSVersionTable.PSVersion.Minor
if ($psvermaj -lt 4) {
	$msg = "Unsupported PowerShell Version ($psvermaj.$psvermin). Please update your system to PowerShell Version 4.0 or above."
	Write-Error $msg
	Exit
}

# Initialize the PowerCLI environment if this is not already done.
if ( !(Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) ) {
    $msg = "Initializing VMware vSphere PowerCLI environment"
    Write-Verbose "$(Get-Date -format G) $msg"
    Write-To-Windows-EventLog "Information" 1001 $msg

    # Even is -Verbose switch is set, disable it while PowerCLI is initializing.
    $oldverbosepreference = $VerbosePreference
    $VerbosePreference = "SilentlyContinue"

    # Get the Install-Path of PowerCLI. If null then PowerCLI may not be installed.

	$idir = (Get-Module -ListAvailable -Name VMware.VimAutomation.Core).ModuleBase		# Usually something like "C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Modules\VMware.VimAutomation.Core"
	
    if ($idir -eq $null) {
        $msg="Error initializing VMWare PowerCLI environment. Cannot find path to VMWare PowerCLI in Registry. Make sure VMWare PowerCLI is installed on this host!"
        Write-Error $msg
        Write-To-Windows-EventLog "Error" 3001 $msg
        Exit
    }
    
    . "$idir\..\..\Scripts\Initialize-PowerCLIEnvironment.ps1"
    
    # Reset the Verbose setting to its previously value
    $VerbosePreference = $oldverbosepreference

}

# Try to resolve VCenter and Graphite Hostname(s) and Quit script if unsuccessful.
checkiporhostname "VCenter server" $Server True

$aservers = $graphiteserver -split ' '
foreach($s in 0..($aservers.count-1)){

	$cserver = $aservers[$s]
	if ($cserver.contains(":")) 
		{
			$atmp = $cserver -split ':'
			$cserver = $atmp[0]
		}
	checkiporhostname "Graphite" $cserver True
}    

# First attempt to connect to the VCenter server. Stop immediately if the connection fails.
$vcc = connectviserver True

$dsTab = @{}
Get-Datastore -Verbose:$false | where {$_.Type -eq "NFS"} | %{
  $dsName = $_.Name
  $_.ExtensionData.Host | %{
    $NfsUuid = $_.MountInfo.Path.Split('/')[3]
    if(!$dsTab.ContainsKey($NfsUuid)){
      $dsTab.Add($NfsUuid,$dsName)
    }
  }
}

$metrics =	"datastore.numberreadaveraged.average",
			"datastore.numberwriteaveraged.average",
			"datastore.write.average",
			"datastore.read.average",
			"datastore.totalreadlatency.average",
			"datastore.totalwritelatency.average",
			"cpu.usage.average"

$iteration = 1

# For the very first iteration, receive the last <sleepseconds> stats from VCenter
$timespan = New-TimeSpan -Seconds $sleepseconds
$starttime = (Get-Date)-$timespan

if ($FromLastPoll -ne "") {
	$FromLastPoll = [System.IO.Path]::GetFullPath($FromLastPoll)
	if (Test-Path $FromLastPoll) {
		Write-Verbose "Reading last polling time from $FromLastPoll"
		$starttime = Import-Clixml $FromLastPoll
		Write-Verbose "Last polling time was $starttime"
	}
}

:crawlerloop while(($iteration -le $iterations) -OR ($iterations -eq 0)) {

	$msg = "Receiving list of VMs from vCenter server $server"
	Write-Verbose "$(Get-Date -format G) $msg"
    Write-To-Windows-EventLog "Information" 1003 $msg

    $errorcounter = 0
	do {
		$vms = Get-VM -Location $global:vmcluster -ErrorAction SilentlyContinue -ErrorVariable err -Verbose:$false | Sort -Unique | where-object {$_.ExtensionData.Config.ManagedBy.extensionKey -NotLike "com.vmware.vcDr*" -and $_.PowerState -eq "PoweredOn"}
		if ($err) {
            $errorcounter = $errorcounter +1
            if ($errorcounter % 10 -eq 0)
                # The connection failed for 10 consecutive times. Seems the connection to VCenter server got lost. Maybe the server was rebooted?
                # Try to reconnect to the server, do not Stop the script if the reconnect fails, try indefinitely.
                { $vcc = connectviserver False }
            else
                # The Get-VM function failed. Wait for 10 seconds and try again. Don't Panic.
                {
			    $msg = "Connection to $server failed! Will retry in 10 seconds"
			    Write-Warning "$(Get-Date -format G) $msg"
                Write-To-Windows-EventLog "Warning" 2003 $msg
			    Start-Sleep -s 10
                }
			}
	} while ($err)

	$vcount = $vms.count

    # Remember the time where the last statistics-collection started.
    # For the next iteration, get the stats from this time until now, regardless how long the last iteration took.
    $laststart = Get-Date

    if ($vcount -gt 0)
    {

	    $msg = "Receiving metrics for $vcount VMs from vCenter server $server"
	    Write-Verbose "$(Get-Date -format G) $msg"
        Write-To-Windows-EventLog "Information" 1004 $msg

        # Receive the statistics for all running VMs, remove duplicates and create an array nice to step through.	
        $i = 0;
        [System.Collections.ArrayList]$stats = @()
        foreach ($vmc in $vms) {

            $i = $i + 1
            Write-Progress -Activity "Receiving metrics..." -CurrentOperation "Virtual Machine ($i/$vcount): $($vmc.Name)" -Id 666 -PercentComplete ($i / $vcount * 100)

	        $stat = Get-Stat -Entity $vmc -Stat $metrics -Realtime -Start $starttime -ErrorAction SilentlyContinue -Verbose:$false |
                Group-Object -Property {$_.Entity.Name+$_.Timestamp}  | %{
	        	    New-Object PSObject -Property @{
	        	    VM = $_.Group[0].Entity.Name
	        	    Timestamp = $_.Group[0].Timestamp
	        	    Datastore = $dsTab[$_.Group[0].Instance]
	        	    ReadIOPS = $_.Group | where {$_.MetricId -eq "datastore.numberreadaveraged.average"} |
	        	    	Measure-Object -Property Value -Sum |
	        	    	select -ExpandProperty Sum
	        	    WriteIOPS = $_.Group | where {$_.MetricId -eq "datastore.numberwriteaveraged.average"} |
	        	    	Measure-Object -Property Value -Sum |
	        	    	select -ExpandProperty Sum
	        	    ReadKBps = $_.Group | where {$_.MetricId -eq "datastore.read.average"} |
	        	    	Measure-Object -Property Value -Sum |
	        	    	select -ExpandProperty Sum
	        	    WriteKBps = $_.Group | where {$_.MetricId -eq "datastore.write.average"} |
	        	    	Measure-Object -Property Value -Sum |
	        	    	select -ExpandProperty Sum
		
					ReadLat = weighted_average ($_.Group | where {$_.MetricId -eq "datastore.numberreadaveraged.average"} | Sort-Object Instance, Timestamp).Value ($_.Group | where {$_.MetricId -eq "datastore.totalreadlatency.average"} | Sort-Object Instance, Timestamp).Value
					WriteLat = weighted_average ($_.Group | where {$_.MetricId -eq "datastore.numberwriteaveraged.average"} | Sort-Object Instance, Timestamp).Value ($_.Group | where {$_.MetricId -eq "datastore.totalwritelatency.average"} | Sort-Object Instance, Timestamp).Value

	        	    #ReadLat = $_.Group | where {$_.MetricId -eq "datastore.totalreadlatency.average"} |
	        	    #	Measure-Object -Property Value -Average |
					#	select -ExpandProperty Average
	        	    #WriteLat = $_.Group | where {$_.MetricId -eq "datastore.totalwritelatency.average"} |
	        	    #	Measure-Object -Property Value -Average |
	        	    #	select -ExpandProperty Average
	        	    CPU = $_.Group | where {$_.MetricId -eq "cpu.usage.average"} |
	        	    	Measure-Object -Property Value -Average |
	        	    	select -ExpandProperty Average
	        	    }
	            }

            [void] ($stats.add($stat))
            

        }
        Write-Progress -Activity "Receiving metrics..." -Completed -Id 666

        $starttime = $laststart

		if ($FromLastPoll -ne "") {
				Write-Verbose "Writing last Poll date and time ($starttime) to $FromLastPoll"
				$starttime  | Export-Clixml $FromLastPoll
		}
	    
        $scount = $stats.count
	    $results = @{}
	    foreach ($statx in $stats){

            if ($statx -ne $null) { 

                foreach ($stat in $statx){

                # Replace characters not allowed and with an underscore and then any trailing and repeating underscores
                $vm = ($stat.VM) -replace '[^a-zA-Z0-9_\-]','_' -replace '[_]+','_'
                while ($vm.EndsWith("_")) { $vm = $vm.Substring(0,$vm.Length-1) }

	    	    $totaliops = $stat.ReadIOPS + $stat.WriteIOPS
	    	    $totalkbps = $stat.ReadKBps + $stat.WriteKBps
	    
	    	    $result = $prefix + $vm + ".ReadIOPS " + [int]$stat.ReadIOPS + " " + (get-date(($stat.Timestamp).touniversaltime()) -uformat "%s")
	    	    $results.add($results.count, $result)
	    	    $result = $prefix + $vm + ".WriteIOPS " + [int]$stat.WriteIOPS + " " + (get-date(($stat.Timestamp).touniversaltime()) -uformat "%s")
	    	    $results.add($results.count, $result)
	    	    $result = $prefix + $vm + ".TotalIOPS " + [int]$totaliops + " " + (get-date(($stat.Timestamp).touniversaltime()) -uformat "%s")
	    	    $results.add($results.count, $result)
	    	    $result = $prefix + $vm + ".ReadKBps " + [int]$stat.ReadKBps + " " + (get-date(($stat.Timestamp).touniversaltime()) -uformat "%s")
	    	    $results.add($results.count, $result)
	    	    $result = $prefix + $vm + ".WriteKBps " + [int]$stat.WriteKBps + " " + (get-date(($stat.Timestamp).touniversaltime()) -uformat "%s")
	    	    $results.add($results.count, $result)
	    	    $result = $prefix + $vm + ".TotalKBps " + [int]$totalkbps + " " + (get-date(($stat.Timestamp).touniversaltime()) -uformat "%s")
	    	    $results.add($results.count, $result)
	    	    $result = $prefix + $vm + ".ReadLatency " + $stat.ReadLat + " " + (get-date(($stat.Timestamp).touniversaltime()) -uformat "%s")
	    	    $results.add($results.count, $result)
	    	    $result = $prefix + $vm + ".WriteLatency " + $stat.WriteLat + " " + (get-date(($stat.Timestamp).touniversaltime()) -uformat "%s")
	    	    $results.add($results.count, $result)
	    	    $result = $prefix + $vm + ".CPU " + [int]$stat.CPU + " " + (get-date(($stat.Timestamp).touniversaltime()) -uformat "%s")
	    	    $results.add($results.count, $result)
                
                }
            }
	    }

	    $scount = $results.count
	    
        if (!$Whatif)
            {
            # Sends the metrics to Graphite.
	        sendtographite $results
            }
        else
            {
            # Instead of sending the metrics to Graphite, send them to the console or pipe.
            $results.Values
            }
    }

	if(($iteration -lt $iterations) -OR ($iterations -eq 0)) {
		$msg = "$(Get-Date -format G) Sleeping for $sleepseconds seconds. Hit ENTER to stop sleeping or ESC to abort the script."
		Write-Verbose $msg

        # Sleep for $sleepseconds but let the user abort sleeping or the entire script
        $wakeuptime = (Get-Date)+$timespan
        $Host.UI.RawUI.FlushInputBuffer()
        :sleepmode while($true) {

            do {
                Start-Sleep -milliseconds 250
                } until ($Host.UI.RawUI.KeyAvailable -or (Get-Date) -ge $wakeuptime)

            if ((Get-Date) -ge $wakeuptime) { break sleepmode }

            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

            switch ($key.VirtualKeyCode) {

                13 { break sleepmode }
                27 {
                    $title = "Abort Script"
                    $message = "Do you really want to abort the script?"
                    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Aborts the script."
                    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Continues with the script."
                    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
                    $result = $host.ui.PromptForChoice($title, $message, $options, 1) 
                    switch ($result)
                        {
                            0 {break crawlerloop}
                            1 {continue sleepmode}
                        }
                    }
                default {
                    $Host.UI.RawUI.FlushInputBuffer()
                    continue sleepmode
                     }
            }

        }
        $Host.UI.RawUI.FlushInputBuffer()
	}
	
	$iteration += 1
}

# Disconnect the VCenter server connection after the last iteration
Disconnect-VIServer -Server $vcc -Force -Confirm:$false -Verbose:$false
