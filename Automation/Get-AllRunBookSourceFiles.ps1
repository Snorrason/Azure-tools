<#
              ____                                                                              
             6MMMMb\                                                                            
            6M'    `
            MM       ___  __     _____   ___  __ ___  __    ___      ____     _____   ___  __   
            YM.      `MM 6MMb   6MMMMMb  `MM 6MM `MM 6MM  6MMMMb    6MMMMb\  6MMMMMb  `MM 6MMb  
             YMMMMb   MMM9 `Mb 6M'   `Mb  MM69 "  MM69 " 8M'  `Mb  MM'    ` 6M'   `Mb  MMM9 `Mb 
                 `Mb  MM'   MM MM     MM  MM'     MM'        ,oMM  YM.      MM     MM  MM'   MM 
                  MM  MM    MM MM     MM  MM      MM     ,6MM9'MM   YMMMMb  MM     MM  MM    MM 
                  MM  MM    MM MM     MM  MM      MM     MM'   MM       `Mb MM     MM  MM    MM 
            L    ,M9  MM    MM YM.   ,M9  MM      MM     MM.  ,MM  L    ,MM YM.   ,M9  MM    MM 
            MYMMMM9  _MM_  _MM_ YMMMMM9  _MM_    _MM_    `YMMM9'Yb.MYMMMM9   YMMMMM9  _MM_  _MM_
                                                                                                
                                                                                                                                                                                                                              
                                                                                                                                    
                                                                                    
       _                                                                                                                              ___         
      dM.                                                                   68b                                                       `MM         
     ,MMb                 /                                           /     Y89                             /                          MM         
     d'YM.    ___   ___  /M       _____   ___  __    __      ___     /M     ___   _____   ___  __          /M       _____     _____    MM   ____  
    ,P `Mb    `MM    MM /MMMMM   6MMMMMb  `MM 6MMb  6MMb   6MMMMb   /MMMMM  `MM  6MMMMMb  `MM 6MMb        /MMMMM   6MMMMMb   6MMMMMb   MM  6MMMMb\
    d'  YM.    MM    MM  MM     6M'   `Mb  MM69 `MM69 `Mb 8M'  `Mb   MM      MM 6M'   `Mb  MMM9 `Mb        MM     6M'   `Mb 6M'   `Mb  MM MM'    `
   ,P   `Mb    MM    MM  MM     MM     MM  MM'   MM'   MM     ,oMM   MM      MM MM     MM  MM'   MM        MM     MM     MM MM     MM  MM YM.     
   d'    YM.   MM    MM  MM     MM     MM  MM    MM    MM ,6MM9'MM   MM      MM MM     MM  MM    MM        MM     MM     MM MM     MM  MM  YMMMMb 
  ,MMMMMMMMb   MM    MM  MM     MM     MM  MM    MM    MM MM'   MM   MM      MM MM     MM  MM    MM        MM     MM     MM MM     MM  MM      `Mb
  d'      YM.  YM.   MM  YM.  , YM.   ,M9  MM    MM    MM MM.  ,MM   YM.  ,  MM YM.   ,M9  MM    MM        YM.  , YM.   ,M9 YM.   ,M9  MM L    ,MM
_dM_     _dMM_  YMMM9MM_  YMMM9  YMMMMM9  _MM_  _MM_  _MM_`YMMM9'Yb.  YMMM9 _MM_ YMMMMM9  _MM_  _MM_        YMMM9  YMMMMM9   YMMMMM9  _MM_MYMMMM9 
                                                                                                                                                                                                              

(Header generated by https://www.kammerl.de/ascii/AsciiSignature.php - using georgi16)

.SYNOPSIS
  Get all the webhooks from an automation account and saves them to local drive

.DESCRIPTION
    First logs on to AzureAccount
    Then gets all the webhooks from an automation account
    Then loops through each webhook and downloads the Draft, then if there is a published version, it will overwrite the draft.

.INPUTS
  N/A

.OUTPUTS
  Writes sourcefiles from Automation account to preset destination
  - destination can be moved to param
  
.NOTES
  Version:        1.0
  Author:         Steen Snorrason
  Creation Date:  2024.01.04
  Purpose/Change: Initial script development
  
.EXAMPLE
  .\Get-AllRunBookSourceFiles.ps1 -SubscriptionId "db5844eb-c35d-4cc9-bab2-12a9a5184826" -automationAccountName "aa-automation" -resourceGroupName "rg-automation"
#>

Param(
    [Parameter(Mandatory = $true)]
    [String] $SubscriptionId = "", # you can set the ID here for your primary Subscription
    [Parameter(Mandatory = $true)]
    [String] $automationAccountName = "", # you can set the name of your primary AccountName 
    [Parameter(Mandatory = $true)]
    [String] $resourceGroupName = "" # and the resource Group name 

)
# Set Error Action to continue
$ErrorActionPreference = "stop"
function Enter-Subscription($SubscriptionId)
{
    $context = Get-AzContext
    if (!$context -or ($context.Subscription.Id -ne $SubscriptionId)) 
    {
        Write-Host "you are not loged in to the correct subscription" -ForegroundColor Red
        Write-Host "use browser popup to login to the correct subscription" -ForegroundColor Red
        Connect-AzAccount -Subscription $SubscriptionId
    } 
    else 
    {
        Write-Host "You Are connects" -ForegroundColor Green
    }
}
# Connect to your Azure account
Enter-Subscription -SubscriptionId $SubscriptionId
$rootfolder = "C:\Dev" #where to save the source 
# Get the runbook
$runbooks = Get-AzAutomationRunbook -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName 

foreach ($runbook in $runbooks) {
  # Export the runbook source code to the TempFolder
  try {
      Write-Host "Exporting runbook source code for runbook: " $runbook.Name -ForegroundColor Green
      Write-Host "first we load drafts" -ForegroundColor Green
      Export-AzAutomationRunbook -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName  -Name $runbook.Name -Slot "Draft" -OutputFolder $rootfolder -Force
  }
  catch {
      Write-Host "Failed to export draft code"  -ForegroundColor Red
  }
  try {
    Write-Host "next we load the published" -ForegroundColor Yellow
    Export-AzAutomationRunbook -ResourceGroupName $resourceGroupName -AutomationAccountName $automationAccountName  -Name $runbook.Name -Slot "Published" -OutputFolder $rootfolder -Force
  }
  catch {
      Write-Host "Failed to export published code"  -ForegroundColor Red
  }
}
