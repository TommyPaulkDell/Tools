# Tools
All tools are run from ISE as administorator. They do not work from PowerShell. 
-------------------------------------------------------------------------------------------------------------------------------------------------
## Dell System Updater
   This tool will automatically download and 
   install Drivers/Firmware on Dell Servers
  
  HowToUse:
    From ISE as admin copy and paste the following to run Dell Sysem Updater
      iex ('$module="DellSystemUpdater";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://github.com/DellProSupportGse/Tools/blob/main/DellSystemUpdater.ps1'));Invoke-DellSystemUpdater

-------------------------------------------------------------------------------------------------------------------------------------------------
## TSR Collector
   This tool is used to collect TSRs from
    all nodes in a cluster"

  HowToUse:
    From ISE as admin copy and paste the following to run
      iex ('$module="TSRCollector";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://github.com/DellProSupportGse/Tools/blob/main/TSRCollector.ps1'));Invoke-TSRCollector

-------------------------------------------------------------------------------------------------------------------------------------------------

