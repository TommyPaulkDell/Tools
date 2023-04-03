    <#
    .Synopsis
       Invoke-LogCollector
    .DESCRIPTION
       This tool is used to collect logs from nodes or all nodes in a cluster and bring them back to a single location
    .EXAMPLE
       Invoke-GetLogs
    #>
Function Invoke-LogCollector{
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High')]
        param($param)

#region Telemetry Information
Write-Host "Logging Telemetry Information..."
function add-TableData1 {
    [CmdletBinding()] 
        param(
            [Parameter(Mandatory = $true)]
            [string] $tableName,

            [Parameter(Mandatory = $true)]
            [string] $PartitionKey,

            [Parameter(Mandatory = $true)]
            [string] $RowKey,

            [Parameter(Mandatory = $true)]
            [array] $data,
            
            [Parameter(Mandatory = $false)]
            [array] $SasToken
        )
        $storageAccount = "gsetools"

        # Allow only add and update access via the "Update" Access Policy on the CluChkTelemetryData table
        # Ref: az storage table generate-sas --connection-string 'USE YOUR KEY' -n "CluChkTelemetryData" --policy-name "Update" 
        If(-not($SasToken)){
            $sasWriteToken = "?sv=2019-02-02&si=LogCollectorUpdate&sig=Jj%2FImBN5rknIuc3TnLf6141lZvHPMvlzJhHAS7CsWOU%3D&tn=LogCollectorTelemetryData"
        }Else{$sasWriteToken=$SasToken}

        $resource = "$tableName(PartitionKey='$PartitionKey',RowKey='$Rowkey')"

        # should use $resource, not $tableNmae
        $tableUri = "https://$storageAccount.table.core.windows.net/$resource$sasWriteToken"
       # Write-Host   $tableUri 

        # should be headers, because you use headers in Invoke-RestMethod
        $headers = @{
            Accept = 'application/json;odata=nometadata'
        }

        $body = $data | ConvertTo-Json
        #This will write to the table
        #write-host "Invoke-RestMethod -Method PUT -Uri $tableUri -Headers $headers -Body $body -ContentType application/json"
		try {
			$item = Invoke-RestMethod -Method PUT -Uri $tableUri -Headers $headers -Body $body -ContentType application/json
		} catch {
			#write-warning ("table $tableUri")
			#write-warning ("headers $headers")
		}
		
}# End function add-TableData
    

Function EndScript{  
    break
}
Clear-Host
# Logs
$DateTime=Get-Date -Format yyyyMMdd_HHmmss
Start-Transcript -NoClobber -Path "C:\programdata\Dell\LogCollector\LogCollector_$DateTime.log"
# Clean up
IF(Test-Path -Path "$((Get-Item $env:temp).fullname)\logs"){ Remove-Item "$((Get-Item $env:temp).fullname)\logs" -Recurse -Confirm:$false -Force}
$Ver="1.1"
# Generating a unique report id to link telemetry data to report data
    $CReportID=""
    $CReportID=(new-guid).guid

$data = @{
    Region=$env:UserDomain
    Version=$Ver
    ReportID=$CReportID
}
$RowKey=(new-guid).guid
$PartitionKey="LogCollector"
add-TableData1 -TableName "LogCollectorTelemetryData" -PartitionKey $PartitionKey -RowKey $RowKey -data $data
#endregion End of Telemetry data

$text = @"
v$Ver
  _                 ___     _ _        _           
 | |   ___  __ _   / __|___| | |___ __| |_ ___ _ _ 
 | |__/ _ \/ _' | | (__/ _ \ | / -_) _|  _/ _ \ '_|
 |____\___/\__, |  \___\___/_|_\___\__|\__\___/_|  
           |___/                                   
"@
Write-Host $text
Write-Host ""
Write-Host "We are committed to providing the best possible customer experience. To do so, we would like to collect some information about your usage of our service."
$consent = (Read-Host "Do you consent to provide environment information (such as hostnames, IP Addresses, etc.) to improve the customer experience? (Y/[N]) ").ToUpper()
if ($consent -eq "Y") {
  # Collect data to improve customer experience
  Write-Host "Thank you for participating in our program. Your input is valuable to us!"
} else {
  $consent = "N"
  # Do not collect data
  Write-Host "We respect your decision. Your privacy is important to us."
}
#only collect personal data when $consent eq 'Y'
$CaseNumber =""
$CaseNumber = Read-Host -Prompt "Please enter the relevant technical support case number"
# Run Menu
Function ShowMenu{
    do
     {
         $selection=""
         Clear-Host
         Write-Host $text
         Write-Host ""
         Write-Host "============ Please make a selection ==================="
         Write-Host ""
         Write-Host "Press '1' to Collect Show Tech-Support(s)"
         Write-Host "Press '2' to Collect Support Assist Collection(s)"
         Write-Host "Press '3' to Collect PrivateCloud.DiagnosticInfo (SDDC)"
         Write-Host "Press '4' to Collect All"
         Write-Host "Press 'H' to Display Help"
         Write-Host "Press 'Q' to Quit"
         Write-Host ""
         $selection = Read-Host "Please make a selection"
     }
    until ($selection -match '[1-4,qQ,hH]')
    $Global:CollectSTS  = "N"
    $Global:CollectSDDC = "N"
    $Global:CollectTSR  = "N"
    IF($selection -imatch 'h'){
        Clear-Host
        Write-Host ""
        Write-Host "What's New in"$Ver":"
        Write-Host $WhatsNew 
        Write-Host ""
        Write-Host "Useage:"
        Write-Host "    Make a select by entering a comma delimited string of numbers from the menu."
        Write-Host ""
        Write-Host "        Example: 1 will Collect Show Tech-Support(s) only and create a report."
        Write-Host "                 Show Tech-Support is a log collection from a Dell switch."
        Write-Host ""
        Write-Host "        Example: 1,3 will Collect Show Tech-Support(s) and "
        Write-Host "                     PrivateCloud.DiagnosticInfo (SDDC) and create a report."
        Write-Host ""
        Pause
        ShowMenu
    }
    IF($selection -match 1){
        Write-Host "Gathering Show Tech-Support(s)..."
        $Global:CollectSTS = "Y"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-Expression('$module="GetShowTech";$repo="PowershellScripts"'+(new-object System.net.webclient).DownloadString('https://raw.githubusercontent.com/DellProSupportGse/Tools/main/GetShowTech.ps1'));Invoke-GetShowTech -confirm:$False -CaseNumber $Casenumber

    }

    IF($selection -match 2){
        Write-Host "Collect Support Assist Collection(s)..."
        $Global:CollectTSR  = "Y"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-Expression('$module="TSRCollector";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DellProSupportGse/Tools/main/TSRCollector.ps1'));Invoke-TSRCollector -confirm:$False -CaseNumber $CaseNumber

    }
    IF($selection -match 3){
        Write-Host "Collect PrivateCloud.DiagnosticInfo (SDDC)..."
        $Global:CollectSDDC = "Y"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-Expression('$module="SDDC";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DellProSupportGse/Tools/main/RunSDDC.ps1'));Invoke-RunSDDC -confirm:$False -CaseNumber $CaseNumber

    }
    ElseIF($selection -eq 4){
        IF(Test-Path -Path "$((Get-Item $env:temp).fullname)\logs"){ Remove-Item "$((Get-Item $env:temp).fullname)\logs" -Recurse -Confirm:$false -Force}
        Write-Host "Collect Show Tech-Support(s) + Support Assist Collection(s) + PrivateCloud.DiagnosticInfo (SDDC)..."
        $Global:CollectSTS  = "Y"
        $Global:CollectSDDC = "Y"
        $Global:CollectTSR  = "Y"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-Expression('$module="GetShowTech";$repo="PowershellScripts"'+(new-object System.net.webclient).DownloadString('https://raw.githubusercontent.com/DellProSupportGse/Tools/main/GetShowTech.ps1'));Invoke-GetShowTech -confirm:$False -CaseNumber $Casenumber
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-Expression('$module="TSRCollector";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DellProSupportGse/Tools/main/TSRCollector.ps1'));Invoke-TSRCollector -LeaveShare:$True -confirm:$False -CaseNumber $Casenumber
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;Invoke-Expression('$module="SDDC";$repo="PowershellScripts"'+(new-object net.webclient).DownloadString('https://raw.githubusercontent.com/DellProSupportGse/Tools/main/RunSDDC.ps1'));Invoke-RunSDDC -confirm:$False -CaseNumber $Casenumber
        # Remove share
            Write-Host "Removing SMB share called Logs..."
            Remove-SmbShare -Name "Logs" -Force
        ZipNClean
    }
    IF($selection -imatch 'q'){
        Write-Host "Bye Bye..."
        EndScript
    }
}#End of ShowMenu
Function ZipNClean{
    # Zip up
        Write-Host "Compressing Logs..."
        $MyTemp=(Get-Item $env:temp).fullname
        $DT=Get-Date -Format "yyyyMMddHHmm"
        IF(Test-Path -Path "$MyTemp\logs"){
            Compress-Archive -Path "$MyTemp\logs\*.*" -DestinationPath "c:\dell\LogCollector_$($DT)"
            Sleep 60            
            IF(Test-Path -Path "c:\dell\LogCollector_$($DT).zip"){
                Write-Host "Logs can be found here: C:Dell\LogCollector_$($DT).zip"
                # Clean up
                Write-Host "Clean up..."
                Remove-Item "$MyTemp\logs" -Recurse -Confirm:$false -Force
                cd c:\dell
                Invoke-Expression "explorer ."
            }Else{
                Write-Host "ERROR: Failed to compress $MyTemp\logs." -ForegroundColor Red
                cd "$MyTemp\logs"
                Invoke-Expression "explorer ."
            }

        }

}
ShowMenu
Stop-Transcript
}# End invoke-LogCollector
