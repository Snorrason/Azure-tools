<#
.SYNOPSIS
  List all API permissions for the User assigned identety

.PARAMETER MIName
  Name of the user-assigned managed identity.
 
.OUTPUTS
  Writes information to console

.NOTES
  Version:        2.0
  Author:         Steen Snorrason
  Creation Date:  2024.01.31
  Purpose/Change: Initial script development
    Version 2.0:  Added support for PowerShell 7.2 and uses Microsoft.Graph
  
.EXAMPLE
  .\List-APIPermisionsApplication.ps1 -MIName "uami-name"
#>
#requires -Version 7.2
param (
    [Parameter(Mandatory = $true)]
    [string]$MIName
)
if(Get-module -Name Microsoft.Graph.Applications -ListAvailable){
    # All good
    Import-Module Microsoft.Graph.Applications
}
else{
    Write-Host "Microsoft.Graph.Applications module is not installed. Installing..." -ForegroundColor Yellow
    Install-Module -name Microsoft.Graph.Beta.Applications -Force
}
#Connect to Graph
Connect-MgGraph -NoWelcome 
$ManagedIdentity = Get-MgServicePrincipal -Filter "displayName eq '$MIName'"
$MSGraph = Get-MgServicePrincipal -Filter "AppId eq '00000003-0000-0000-c000-000000000000'"
$graphRoles = $MSGraph.AppRoles 
$assigendRoles =  Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId  $ManagedIdentity.ID -all | 
                    where-object -Property ResourceDisplayName -eq 'Microsoft Graph' | 
                    select-object -ExpandProperty AppRoleId 

Write-Host "The following roles are assigned to the UserAssigned Identety: " -ForegroundColor White -NoNewline
Write-Host $ManagedIdentity.PrincipalDisplayName -ForegroundColor Green
Write-Host " " -ForegroundColor White
foreach ($role in $assigendRoles) {
    $GraphRoleInfo =  $graphRoles | Where-Object {$_.ID -eq $role}
    Write-Host "Role: $($GraphRoleInfo.Value)" -ForegroundColor Yellow
    Write-Host "Description: $($GraphRoleInfo.Description)" -ForegroundColor Gray
}
Write-Host "Log of Graph? (y/n)" -ForegroundColor Green -NoNewline
If ((Read-Host) -Like "y*") 
{
    Disconnect-MgGraph
}
