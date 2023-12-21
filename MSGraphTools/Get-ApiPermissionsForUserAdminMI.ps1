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
                                                                                                
___       ___  ____      ____                               ___             __________                     ___         
`MMb     dMM' 6MMMMb\   6MMMMb/                             `MM             MMMMMMMMMM                     `MM         
 MMM.   ,PMM 6M'    `  8P    YM                              MM             /   MM   \                      MM         
 M`Mb   d'MM MM       6M      Y ___  __    ___    __ ____    MM  __             MM       _____     _____    MM   ____  
 M YM. ,P MM YM.      MM        `MM 6MM  6MMMMb   `M6MMMMb   MM 6MMb            MM      6MMMMMb   6MMMMMb   MM  6MMMMb\
 M `Mb d' MM  YMMMMb  MM         MM69 " 8M'  `Mb   MM'  `Mb  MMM9 `Mb           MM     6M'   `Mb 6M'   `Mb  MM MM'    `
 M  YM.P  MM      `Mb MM     ___ MM'        ,oMM   MM    MM  MM'   MM           MM     MM     MM MM     MM  MM YM.     
 M  `Mb'  MM       MM MM     `M' MM     ,6MM9'MM   MM    MM  MM    MM           MM     MM     MM MM     MM  MM  YMMMMb 
 M   YP   MM       MM YM      M  MM     MM'   MM   MM    MM  MM    MM           MM     MM     MM MM     MM  MM      `Mb
 M   `'   MM L    ,M9  8b    d9  MM     MM.  ,MM   MM.  ,M9  MM    MM           MM     YM.   ,M9 YM.   ,M9  MM L    ,MM
_M_      _MM_MYMMMM9    YMMMM9  _MM_    `YMMM9'Yb. MMYMMM9  _MM_  _MM_         _MM_     YMMMMM9   YMMMMM9  _MM_MYMMMM9 
                                                   MM                                                                  
                                                   MM                                                                  
                                                  _MM_                                                                 

(Header generated by https://www.kammerl.de/ascii/AsciiSignature.php - using georgi16)

.SYNOPSIS
  Get the API permissions for the User assigned identety in the destination tenant

.DESCRIPTION
  first the script makes hure you are running PowerShell 5.1 since this function is not supported in PowerShell 7 (December 2023)
  then it connects to Azure AD in the destination tenant, grabs all the roles from the graph app and grabs all the roles assigned to the UAMI
  then it loops through the roles and display the role name and description

.INPUTS
  Name of the user-assigned managed service identity.

.OUTPUTS
  Writes to console the API permissions for the User assigned identety in the destination tenant

.NOTES
  Version:        1.0
  Author:         Steen Snorrason
  Creation Date:  2023.12.20
  Purpose/Change: Initial script development
  
.EXAMPLE
  .\Get-ApiPermissionsForUserAdminMI.ps1 -MsiName "uami-name"
#>


#requires -Version 5.1

<# dispays permisions that has ben granted to the UserAssigned Identety in the destination tenant
.Parameter MsiName
    # Name of user-assigned managed service identity. 
#>

param (
    [Parameter(Mandatory=$false)]
    [string]$MsiName  
)

# Set Error Action Preference to Stop
$ErrorActionPreference = "Stop"

If ($PSVersionTable.PSVersion.Major -gt 5) {
    Write-Host "This script requires PowerShell 5.1" -ForegroundColor Red
    exit
}

# Connect to Azure AD in the destination tenant
## ToDo change the TenantID
$DestinationTenantId = "6c61ff57-5f40-4269-9672-400eb17aa27d" # Tenant ID - set this to your Tenant ID

# Make sure user is connected to AzureAD
try { 
    $var = Get-AzureADTenantDetail 
    Write-Host "You are loged into AzureAD (Microsoft Entra) " -ForegroundColor Green
    $var.DomainName
} 
   catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] { 
    Write-Host "You're not connected to AzureAD" -ForegroundColor Yellow
    Write-Host "Please connect to AzureAD - using the Popup window" -ForegroundColor Yellow
    try {
        Connect-AzureAD -TenantId $DestinationTenantId 
    }
    catch {
        Write-Host "Failed to connect to Azure AD in the destination tenant"  -ForegroundColor Red
        Write-Host $_.Exception.Message  -ForegroundColor Red
        exit
    }
}



$GraphAppId = "00000003-0000-0000-c000-000000000000" # Don't change this - it is default GUID for MSGraph.

$oMsi = (Get-AzureADServicePrincipal -Filter "displayName eq '$MsiName'").ObjectId
$oGraphSpn = (Get-AzureADServicePrincipal -Filter "appId eq '$GraphAppId'")

# grab all the roles from the graph app
$graphRoles = $oGraphSpn.AppRoles

# Grab all the roles assigned to the MSI
$assigendRoles =  Get-AzureADServiceAppRoleAssignedTo -ObjectId $oMsi -all $true | where-object -Property ResourceDisplayName -eq 'Microsoft Graph' | select-object -ExpandProperty Id 

Write-Host "The following roles are assigned to the UserAssigned Identety: " -ForegroundColor White -NoNewline
Write-Host $MsiName -ForegroundColor Green

Write-Host " " -ForegroundColor White

# Loop through the roles and display the role name and description
foreach ($role in $assigendRoles) {
    $grapgRole =  $graphRoles | Where-Object {$_.Id -eq $role}

    Write-Host "Role: $($grapgRole.Value)" -ForegroundColor Yellow
    Write-Host "Description: $($grapgRole.Description)" -ForegroundColor Gray

}