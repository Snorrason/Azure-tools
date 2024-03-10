<#
.SYNOPSIS
  Grants API permissions for the User assigned identety

.PARAMETER MIName
  Name of the user-assigned managed identity.
 
.PARAMETER Permission
  Name of the permission to grant to the User assigned identety
  
.OUTPUTS
  Writes actions to console

.NOTES
  Version:        2.0
  Author:         Steen Snorrason
  Creation Date:  2024.01.31
  Purpose/Change: Initial script development
    Version 2.0:  Added support for PowerShell 7.2 and uses Microsoft.Graph
  
.EXAMPLE
  .\Grant-ApiPermissionsForUserAdminMI.ps1 -MIName "uami-name" -Permission "User.Read.All"
#>

#requires -Version 7.2
param (
    [Parameter(Mandatory = $true)]
    [string]$MIName,
    [Parameter(Mandatory = $true)]
    [string]$Permission
)
if(Get-module -Name Microsoft.Graph.Applications -ListAvailable){
    # All good
}
else{
    Write-Host "Microsoft.Graph.Applications module is not installed. Installing..." -ForegroundColor Yellow
    Install-Module -name Microsoft.Graph.Applications -Force
}
Connect-MgGraph -NoWelcome 
$ManagedIdentity = Get-MgServicePrincipal -Filter "displayName eq '$MIName'"
$MSGraph = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"
$role = $MSGraph.AppRoles | Where-Object {$_.Value -eq $Permission} 
$AppRoleAssignment = @{
  "PrincipalId" = $ManagedIdentity.Id
  "ResourceId" = $MSGraph.Id
  "AppRoleId" = $Role.Id }

try {
  New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentity.id -BodyParameter $AppRoleAssignment
}
catch {
  Write-Host "Failed to grant API permission" -ForegroundColor Red
  Write-Host $_.Exception.Message -ForegroundColor Red
}
Write-Host "Log of Graph? (y/n)" -ForegroundColor Green -NoNewline
If ((Read-Host) -Like "y*") 
{
    Disconnect-MgGraph
}
