# open MS Graph explorer to get your AdminUser ID
# https://developer.microsoft.com/en-us/graph/graph-explorer
# login with your admin account
# run the following query   https://graph.microsoft.com/v1.0/me
# copy the userPrincipalName and id from the response

$adminUserId    = "masterblaster@conesto.onmicrosoft.com" # replace with your admin user id from the graph explorer "userPrincipalName"
$principalID    = "01fa9dbf-107d-4458-bf7d-14f38ebed937" # replace with your admin user id from the graph explorer "id"
               
$startTime      = Get-Date -Format o 
$subscription   = "b14df531-3d41-434d-b27a-bd20b41ecd11"  # replace with subscription id of the subscription you want to elevate
$tenantId       = "1f6f343d-0259-438c-bdc2-91bce86f5902" 

$DurationInHours = 17 - (get-date -format HH) # let you have it open past 16:00

# See if you are loged on to Azure
$AzContext=Get-AzContext
if ($null -eq $AzContext) {
    Connect-AzAccount -Tenant $tenantId -Subscription $subscription -AccountId $adminUserId
}

$ScopeTypes=@('subscription','resourcegroup')

$roles= @('Contributor') 
# to get roles, to activate run following while you have the PIM activated 
# Get-AzRoleEligibilitySchedule -Scope "/" -Filter "asTarget()" | fl


Get-AzRoleEligibilitySchedule -Scope "/" -Filter "asTarget()" `
| Where-Object { ($ScopeTypes -contains $_.ScopeType) -and ($roles -contains $_.RoleDefinitionDisplayName) } `
| Group-Object RoleDefinitionDisplayName, Scope `
| Select-Object @{ Expression = { $_.group[0] } ; Label = 'Item' } `
| Select-Object -ExpandProperty item `
| ForEach-Object {
    $p = @{
        Name                      = (New-Guid).Guid
        Scope                     = $_.Scope
        PrincipalId               = $principalID 
        RoleDefinitionId          = $_.RoleDefinitionId
        ScheduleInfoStartDateTime = $startTime
        ExpirationDuration        = "PT${DurationInHours}H"
        ExpirationType            = "AfterDuration"
        RequestType               = "SelfActivate"
        Justification             = "Today Work"
    }
    New-AzRoleAssignmentScheduleRequest @p  
}
