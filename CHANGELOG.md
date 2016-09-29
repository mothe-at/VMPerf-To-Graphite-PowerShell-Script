# v1.5.1 (2016-09-29)
* **[FIXED]** Changed Encoding of Script to UTF-8
* **[FIXED]** Fixed a bug that causes wrong number of IOPS and KBs with multiple vDisks
* **[FIXED]** Calculate the weighted average of the read and write latency of all disks instead of the simple average

# v1.5.0 (2016-06-04)
* **[ADDED]** Added feature to send metrics to more than one carbon host at a time. Fixed [#2] (https://github.com/mothe-at/VMPerf-To-Graphite-PowerShell-Script/issues/2)
* **[ADDED]** Ability to add portnumber for carbon server with the hostname (`-Graphiteserver <hostname>[:<port>][,<hostname>[:<port>][,...]]`)

# v1.4.0 (2016-05-20)
* **[FIXED]** Parameter "-EventLogLevel None" could lead to an error message.
* **[ADDED]** Parameter "-FromLastPoll <xml-file>". If this parameter is set, the script will try to receive all metrics from the VCenter Server starting at the date and time of the last poll up to the most recent data (Real-Time). Best practice if you are using a scheduler to run the script with only one iteration. Check help for more information.

# v1.3.1 (2016-01-13)
* **[ADDED]** Check for Powershell Version. Script will abort if it is below Version 4.0

# v1.3.0 (2015-09-05)
* Initial published Release
