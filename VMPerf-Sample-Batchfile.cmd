@echo off
REM =============================================================================================================
REM VMPerf-To-Graphite-PowerShell-Script
REM
REM Sample Batch-File you can run from Windows Scheduled Tasks. (Every 10 minues, for instance)
REM Please adjust the SET Variables accordingly
REM PLEASE AVOID ANY SPECIAL CHARACTERS, ESPECIALLY IN THE "VMP_GROUP" FIELD (Use a-z0-9, no Blanks, no Periods!)
REM
REM =============================================================================================================
REM https://github.com/mothe-at/VMPerf-To-Graphite-PowerShell-Script
REM =============================================================================================================

cd /D C:\VMPerf

SET VMP_VCENTER_SERVER = YOUR_VCENTER_SERVER
SET VMP_VCENTER_USER = YOUR_VCENTER_USER
SET VMP_VCENTER_PASS = YOUR_VCENTER_PASSWORD
SET VMP_GRAPHITE_SERVER = YOUR_GRAPHITE_SERVER[:PORT]
SET VMP_GROUP = YOUR_GROUP

powershell.exe .\VMPerf-To-Graphite.ps1 -server %VMP_VCENTER_SERVER% -user %VMP_VCENTER_USER% -password %VMP_VCENTER_PASS% -Graphiteserver %VMP_GRAPHITE_SERVER% -Iterations 1 -Group %VMP_GROUP% -EventLogLevel Warning -FromLastPoll VMPerf_%VMP_GROUP%.xml -Verbose >> VMPerf_%VMP_GROUP%.log 2>&1

