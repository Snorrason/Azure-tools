<#
                            __________    ____      ____      ____   
                            `MMMMMMMMM   6MMMMb/   6MMMMb/   6MMMMb  
                            MM      \  8P    YM  8P    YM  8P    Y8 
                            MM        6M      Y 6M      Y 6M      Mb
                            MM    ,   MM        MM        MM      MM
                            MMMMMMM   MM        MM        MM      MM
                            MM    `   MM        MM        MM      MM
                            MM        MM        MM        MM      MM
                            MM        YM      6 YM      6 YM      M9
                            MM      /  8b    d9  8b    d9  8b    d8 
                            _MMMMMMMMM   YMMMM9    YMMMM9    YMMMM9  
                                                                    
      dM.                                                                   68b                     
     ,MMb                 /                                           /     Y89                     
     d'YM.    ___   ___  /M       _____   ___  __    __      ___     /M     ___   _____   ___  __   
    ,P `Mb    `MM    MM /MMMMM   6MMMMMb  `MM 6MMb  6MMb   6MMMMb   /MMMMM  `MM  6MMMMMb  `MM 6MMb  
    d'  YM.    MM    MM  MM     6M'   `Mb  MM69 `MM69 `Mb 8M'  `Mb   MM      MM 6M'   `Mb  MMM9 `Mb 
   ,P   `Mb    MM    MM  MM     MM     MM  MM'   MM'   MM     ,oMM   MM      MM MM     MM  MM'   MM 
   d'    YM.   MM    MM  MM     MM     MM  MM    MM    MM ,6MM9'MM   MM      MM MM     MM  MM    MM 
  ,MMMMMMMMb   MM    MM  MM     MM     MM  MM    MM    MM MM'   MM   MM      MM MM     MM  MM    MM 
  d'      YM.  YM.   MM  YM.  , YM.   ,M9  MM    MM    MM MM.  ,MM   YM.  ,  MM YM.   ,M9  MM    MM 
_dM_     _dMM_  YMMM9MM_  YMMM9  YMMMMM9  _MM_  _MM_  _MM_`YMMM9'Yb.  YMMM9 _MM_ YMMMMM9  _MM_  _MM_

#>

# Set the PowerShell version to 7.2 or 5.1 - DO NOT USE 7.1

#Requires -Version 7.2 
<#
.SYNOPSIS
   Create a logfile build for CMTrace from Microsoft SCCM and save in Blob 

.DESCRIPTION
    creates a blob container for every runbook and saves the logfile with start timestamp
    
.PARAMETER  <ParameterName>

.OUTPUTS
  None

.NOTES
  Version:        1.1 
  Author:         SSNO
  Creation Date:  April 2024
  Purpose/Change: Initial script development

  The Automation account must have a user assigned managed identity 
  
.EXAMPLE
  Azure Runbook - Run as Managed Identety <Azure>
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
Param(
)

#Set Error Action to Stop
$ErrorActionPreference = "stop"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

Write-Output "declaring variables"
# Automation Account settings - this is the Subscription where the Automation account is "Hosted"
$aa_subscription = Get-AutomationVariable -name 'aa_subscription_name'

# User assigned managed identities Client ID:  
$USI = Get-AutomationVariable -name 'UAMI_useradmin_id'

# Storage Account settings - this is the Storage account where the Copy to and from happen 
$StorageAccount = Get-AutomationVariable -name 'aa_Storageaccount'

# Runbook name wil be used to save the log into container - named after RunbookName
$RunbookName = "RemoveDeviceFromIntune"

#-----------------------------------------------------------[Local Functions]------------------------------------------------------
function Write-Log {
  param (
    [String]$Message,
    [Parameter(Mandatory = $false)]
    [ValidateSet("Info", "Warning", "Error")]
    [String]$Type = "Info"
  )

  switch ($Type) {
    "Info" { [int]$Type = 1 }
    "Warning" { [int]$Type = 2 }
    "Error" { [int]$Type = 3 }
  }

  $msg = "<![LOG[$($Message)]LOG]!>"
  $msg += "<time=`"$(Get-Date -Format HH:mm:ss.000+000)`" date=`"$(Get-Date -Format MM-dd-yyyy)`""
  $msg += " component=`"$($RunbookName) `""
  $msg += " context=`"$($RunbookId) `"" 
  $msg += " type=`"$($type)`""
  $msg += " thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`""
  $msg += " file=`"`">"
  add-content $LogFilePath -Value $msg 
  # Write-Output $msg # uncomment this line to also output the message to the job log - when debugging the runbook
}

function Complete-Logfile {
  try {
    Connect-AzAccount -identity -AccountId $USI -Subscription $aa_subscription
    $ctx = New-AzStorageContext -StorageAccountName $StorageAccount -UseConnectedAccount
  }
  catch {  }
  try {
    $existingContainer = Get-AzStorageContainer -Name $RunbookName.ToLower() -Context $ctx -ErrorAction SilentlyContinue
    if ($null -eq $existingContainer) {
      New-AzStorageContainer -Name $RunbookName.ToLower() -Context $ctx 
    }
  }
  catch {
    write-log -Message "not able to create container in Storrage account: $StorageAccount to Container: $($RunbookName.ToLower()) "  -Type Error
  }
  try {
    try {
      $oldLogFile = "$env:temp/$RunbookName.old"
      Get-AzStorageBlobContent -Container $RunbookName.ToLower() -Blob "$RunbookName.Log" -Destination $oldLogFile -Context $ctx
      if ((Get-Item $oldLogFile).length -gt 32MB) {
        Set-AzStorageBlobContent -Context $ctx -Container $RunbookName.ToLower() -File $oldLogFile -Blob "$RunbookName.old.log" -Force
        New-Item -Path $oldLogFile -ItemType File
      }
    }
    catch {
      New-Item -Path $oldLogFile -ItemType File
    }
    Add-Content -Path $oldLogFile -Value (Get-Content -Path $LogFilePath)
    Set-AzStorageBlobContent -Context $ctx -Container $RunbookName.ToLower() -File $oldLogFile -Blob "$RunbookName.Log" -Force
  }
  catch { 
    Write-Output "not able to write to Storrage account: $StorageAccount to Container: $($RunbookName.ToLower()) " 
    get-content $LogFilePath
  }
}


#----------------------------------------------------------[ Process WebhookData ]----------------------------------------------------------
		 # Collect properties of WebhookData
     $WebhookName     = $WebHookData.WebhookName
     $WebhookHeaders  = $WebHookData.RequestHeader
     $WebhookBody     = $WebHookData.RequestBody
 
     $Payload = $WebhookBody | ConvertFrom-Json  
 
     $DeviceName = $Payload.DeviceName

    IF($null -eq $Payload){
      Write-output "No device name provided in request"
      Exit 1
    }

#-----------------------------------------------------------[ Initiate logging ]------------------------------------------------------------
try {
  $StartTime = Get-date
  $LogFilePath = "$Env:temp/$RunbookName.Log"
}
catch {
  $excep = $(if ($error[0].Exception -contains ("`"")) { $error[0].Exception -Replace ("`"", "'") }else { $error[0].Exception })
  Write-Log -Message ("Failed - Exception Caught at line $($error[0].InvocationInfo.ScriptLineNumber), $excep" | out-string) -Type Error
  Continue
}
#------------------------------------------------[ Connect and run as User assigned managed Identety ]----------------------------------------------------
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null
# Connect using a System Assigned Managed Identity - the Subscription tag is there in case you have several subscriptions 
try {
  Write-log -Message "Connecting to Azure using System Assigned Managed Identity"
  Connect-AzAccount -identity -AccountId $USI -Subscription $aa_subscription
}
catch {
  Write-log -Message "There is no user-assigned identity with AccountID $USI Aborting." -Type Error
  $excep = $(if($error[0].Exception -contains ("`"")){$error[0].Exception -Replace ("`"","'")}else{$error[0].Exception})
  Write-log -Message ("Failed - Exception Caught at line $($error[0].InvocationInfo.ScriptLineNumber), $excep" | out-string) -Type Error
  Break
}

try {
  Write-log -Message "Connecting to MS Graph"
  Connect-MgGraph -Identity -ClientId $USI -NoWelcome 
}
catch {
  Write-log -Message "the logon to MS Graph failed - check the log for details" -Type Error
  $excep = $(if($error[0].Exception -contains ("`"")){$error[0].Exception -Replace ("`"","'")}else{$error[0].Exception})
  Write-log -Message ("Failed - Exception Caught at line $($error[0].InvocationInfo.ScriptLineNumber), $excep" | out-string) -Type Error
  Break
}
#-----------------------------------------------------------[Execution]------------------------------------------------------------
try {
  $Device = Get-MgDevice -Filter "DisplayName -eq '$DeviceName'"
  $DeviceId = $Device.ObjectId   
  IF($null -eq $DeviceId){
    write-log -Message "Device $DeviceName not found"
    Break
  }
  Remove-MgDevice -DeviceId $DeviceId
  Write-log -Message "Device $DeviceName have been deleted from Intune"
}
catch {
  $excep = $(if($error[0].Exception -contains ("`"")){$error[0].Exception -Replace ("`"","'")}else{$error[0].Exception})
  Write-log -Message ("Failed - Exception Caught at line $($error[0].InvocationInfo.ScriptLineNumber), $excep" | out-string) -Type Error
}
#-----------------------------------------------------------[Finalization]------------------------------------------------------------
finally {
  Write-Log -Message ("Runbook finished - total runtime: $((([DateTime]::Now) - $StartTime).TotalSeconds) Seconds"  | out-string ) -Type Info
  Complete-Logfile
}