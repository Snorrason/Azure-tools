<#
.SYNOPSIS
  Removes API permissions for the User assigned identety in the destination tenant

.PARAMETER MIName
  Name of the user-assigned managed service identity.
 
.PARAMETER Permission
  Name of the permission to remove from the User assigned identety in the destination tenant
  
.OUTPUTS
  Writes actions to console

.NOTES
  Version:        2.0
  Author:         Steen Snorrason
  Creation Date:  2024.01.31
  Purpose/Change: Initial script development
    Version 2.0:  Added support for PowerShell 7.2 and uses Microsoft.Graph
  
.EXAMPLE
  .\Remove-ApiPermissionsForUserAdminMI.ps1 -MIName "uami-name" -Permission "User.Read.All"

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
$Msgraph = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"
$role = $Msgraph.AppRoles | Where-Object {$_.Value -eq $Permission} 
$SPPermissions = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $ManagedIdentity.Id
try {
  $Assignment = $SpPermissions | Where-Object {$_.AppRoleId -eq $Role.Id}
  if($null -eq $Assignment){
    Write-Host "No API permission to remove" -ForegroundColor Red
    exit
  }
  else{
    Remove-MgServicePrincipalAppRoleAssignment -AppRoleAssignmentId $Assignment.Id -ServicePrincipalId $ManagedIdentity.Id
  }
}
catch {
    Write-Host "Failed to remove API permission" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

If ((Read-Host "Log of Graph? (y/n) ") -Like "y*") 
{
    Disconnect-MgGraph
}
