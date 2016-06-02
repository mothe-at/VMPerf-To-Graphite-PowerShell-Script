# v1.4.0 (2016-05-20)
* **[FIXED]** Parameter "-EventLogLevel None" could lead to an error message.
* **[ADDED]** Parameter "-FromLastPoll <xml-file>". If this parameter is set, the script will try to receive all metrics from the VCenter Server starting at the date and time of the last poll up to the most recent data (Real-Time). Best practice if you are using a scheduler to run the script with only one iteration. Check help for more information.

# v1.3.1 (2016-01-13)
* **[ADDED]** Check for Powershell Version. Script will abort if it is below Version 4.0

# v1.3.0 (2015-09-05)
* Initial published Release
