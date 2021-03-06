###############################
#
# Tests to add/remove permissions
# Assumes a blank slate
#
###############################



"start"


$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;

$CurrentTest = "#1 Check current user has no rights on default template"
[string]$permission = Get-K2EnvironmentLibraryPermission -TemplateName "Default Template" -UserOrGroupName "K2:$currentUser"
if($permission.Equals("none") -eq $false) {Write-Error "currentuser should not have any rights on the server when these tests start"}
else {"$CurrentTest - SUCCESS"}

$CurrentTest = "#2 Give current user modify permission on default template and check"
Set-K2EnvironmentLibraryPermission -TemplateName "Default Template" -UserOrGroup "User" -PermissionType "modify" -UserOrGroupName "K2:$currentUser"
[string]$permission = Get-K2EnvironmentLibraryPermission -TemplateName "Default Template" -UserOrGroupName "K2:$currentUser"
if($permission.Equals("modify") -eq $false) {Write-Error "current user should now have modify rights"}
else {"$CurrentTest - SUCCESS"}

$CurrentTest = "#3 Give Administrators group read permission on default template and check"
Set-K2EnvironmentLibraryPermission -TemplateName "Default Template" -UserOrGroup "Group" -PermissionType "read" -UserOrGroupName "K2:DENALLIX\Administrators"
[string]$permission = Get-K2EnvironmentLibraryPermission -TemplateName "Default Template" -UserOrGroupName "K2:DENALLIX\Administrators"
if($permission.Equals("read") -eq $false) {Write-Error "current user should now have modify rights"}
else {"$CurrentTest - SUCCESS"}

$CurrentTest = "#4 Give current user modify permission on production environment on default template and check"
Set-K2EnvironmentLibraryPermission -TemplateName "Default Template" -EnvironmentName "Production"  -UserOrGroup "User" -PermissionType "modify" -UserOrGroupName "K2:$currentUser"
[string]$permission = Get-K2EnvironmentLibraryPermission -TemplateName "Default Template"  -EnvironmentName "Production" -UserOrGroupName "K2:$currentUser"
if($permission.Equals("modify") -eq $false) {Write-Error "current user should now have modify rights on production"}
else {"$CurrentTest - SUCCESS"}

$CurrentTest = "#5 Give Administrators group read permission on production environment on default template and check"
Set-K2EnvironmentLibraryPermission -TemplateName "Default Template" -EnvironmentName "Production" -UserOrGroup "Group" -PermissionType "read" -UserOrGroupName "K2:DENALLIX\Administrators"
[string]$permission = Get-K2EnvironmentLibraryPermission -TemplateName "Default Template" -EnvironmentName "Production"  -UserOrGroupName "K2:DENALLIX\Administrators"
if($permission.Equals("read") -eq $false) {Write-Error "Administrators Group should now have read rights on production"}
else {"$CurrentTest - SUCCESS"}

$CurrentTest = "#6 Remove all permissions and check
## Remove Administrators group read permission on production environment on default template and check"
Set-K2EnvironmentLibraryPermission -TemplateName "Default Template" -EnvironmentName "Production" -UserOrGroup "Group" -PermissionType "none" -UserOrGroupName "K2:DENALLIX\Administrators"
[string]$permission = Get-K2EnvironmentLibraryPermission -TemplateName "Default Template" -EnvironmentName "Production"  -UserOrGroupName "K2:DENALLIX\Administrators"
if($permission.Equals("none") -eq $false) {Write-Error "current user should no longer have modify rights"}
else {"$CurrentTest - SUCCESS"}

## Remove current user modify permission on production environment on default template and check
Set-K2EnvironmentLibraryPermission -TemplateName "Default Template" -EnvironmentName "Production"  -UserOrGroup "User" -PermissionType "none" -UserOrGroupName "K2:$currentUser"
[string]$permission = Get-K2EnvironmentLibraryPermission -TemplateName "Default Template"  -EnvironmentName "Production" -UserOrGroupName "K2:$currentUser"
if($permission.Equals("none") -eq $false) {Write-Error "current user should no longer have modify rights on production"}
else {"$CurrentTest - SUCCESS"}

## Remove Administrators group read permission on default template and check
Set-K2EnvironmentLibraryPermission -TemplateName "Default Template" -UserOrGroup "Group" -PermissionType "none" -UserOrGroupName "K2:DENALLIX\Administrators"
[string]$permission = Get-K2EnvironmentLibraryPermission -TemplateName "Default Template" -UserOrGroupName "K2:DENALLIX\Administrators"
if($permission.Equals("none") -eq $false) {Write-Error "current user should now have modify rights"}
else {"$CurrentTest - SUCCESS"}

## Remove current user modify permission on default template and check
Set-K2EnvironmentLibraryPermission -TemplateName "Default Template" -UserOrGroup "User" -PermissionType "none" -UserOrGroupName "K2:$currentUser"
[string]$permission = Get-K2EnvironmentLibraryPermission -TemplateName "Default Template" -UserOrGroupName "K2:$currentUser"
if($permission.Equals("none") -eq $false) {Write-Error "current user should no longer have modify rights"}
else {"$CurrentTest - SUCCESS"}

"Environment Library permission tests complete."

"start - SmartObject Permissions"

$CurrentTest = "#1 Check current user has no rights for SmartObjects"
[K2SmartObjectPermission]$permission = Get-K2SmartObjectPermission -UserOrGroupName "K2:$currentUser"
if($permission -ne [K2SmartObjectPermission]::None) {Write-Error "currentuser should not have any rights on the server when these tests start"}
else {"$CurrentTest - SUCCESS"}

$CurrentTest = "#2 Give current user publish smo permission and check"
Set-K2SmartObjectPermission -UserOrGroup "User" -PermissionType "Publish" -UserOrGroupName "K2:$currentUser"
[K2SmartObjectPermission]$permission = Get-K2SmartObjectPermission -UserOrGroupName "K2:$currentUser"
if($permission -ne [K2SmartObjectPermission]::Publish) {Write-Error "current user should now have publish rights"}
else {"$CurrentTest - SUCCESS"}

$CurrentTest = "#3 Give current user publish AND Delete smo permission and check"
Set-K2SmartObjectPermission -UserOrGroup "User" -PermissionType "Publish, Delete" -UserOrGroupName "K2:$currentUser"
[K2SmartObjectPermission]$permission = Get-K2SmartObjectPermission -UserOrGroupName "K2:$currentUser"
if(!($permission -band [K2SmartObjectPermission]::Publish)) {Write-Error "current user should now have publish rights"}
if(!($permission -band [K2SmartObjectPermission]::Delete)) {Write-Error "current user should now have delete rights"}
else {"$CurrentTest - SUCCESS"}

$CurrentTest = "#4 Give current user delete smo permission and check"
Set-K2SmartObjectPermission -UserOrGroup "User" -PermissionType "Delete" -UserOrGroupName "K2:$currentUser"
[K2SmartObjectPermission]$permission = Get-K2SmartObjectPermission -UserOrGroupName "K2:$currentUser"
if($permission -ne [K2SmartObjectPermission]::Delete) {Write-Error "current user should now have Delete rights"}
else {"$CurrentTest PART 1- SUCCESS"}
if($permission -eq [K2SmartObjectPermission]::Publish) {Write-Error "current user should no longer have publish rights"}
else {"$CurrentTest PART 2- SUCCESS"}


$CurrentTest = "#5 Give Administrators group Publish permission and check"
Set-K2SmartObjectPermission -UserOrGroup "Group" -PermissionType "Publish" -UserOrGroupName "K2:DENALLIX\Administrators"
[K2SmartObjectPermission]$permission = Get-K2SmartObjectPermission -UserOrGroupName "K2:DENALLIX\Administrators"
if($permission -ne [K2SmartObjectPermission]::Publish) {Write-Error "Administrators group should now have publish rights"}
else {"$CurrentTest - SUCCESS"}

$CurrentTest = "#6 Give Administrators group Delete permission and check"
Set-K2SmartObjectPermission -UserOrGroup "Group" -PermissionType "Delete" -UserOrGroupName "K2:DENALLIX\Administrators"
[K2SmartObjectPermission]$permission = Get-K2SmartObjectPermission -UserOrGroupName "K2:DENALLIX\Administrators"
if($permission -ne [K2SmartObjectPermission]::Delete) {Write-Error "Administrators group should now have Delete rights"}
else {"$CurrentTest - SUCCESS"}

$CurrentTest = "#7 Remove all permissions and check"
## Remove Administrators group read permission on production environment on default template and check
Set-K2SmartObjectPermission -UserOrGroup "Group" -PermissionType "None" -UserOrGroupName "K2:DENALLIX\Administrators"
[K2SmartObjectPermission]$permission = Get-K2SmartObjectPermission -UserOrGroupName "K2:DENALLIX\Administrators"
if($permission -ne [K2SmartObjectPermission]::None) {Write-Error "Administrators group should no longer have SmO rights"}
else {"$CurrentTest - PART 1 SUCCESS"}

#remove current user publish AND Delete smo permission and check
Set-K2SmartObjectPermission -UserOrGroup "User" -PermissionType "None" -UserOrGroupName "K2:$currentUser"
[K2SmartObjectPermission]$permission = Get-K2SmartObjectPermission -UserOrGroupName "K2:$currentUser"
if($permission -band [K2SmartObjectPermission]::Publish) {Write-Error "current user should no longer have publish rights"}
else {"$CurrentTest - PART 2 SUCCESS"}
if($permission -band [K2SmartObjectPermission]::Delete) {Write-Error "current user should no longer have delete rights"}
else {"$CurrentTest - PART 3 SUCCESS"}

"SmartObject permission tests complete."




###Add-K2SmartObjectPermission -PermissionType "publish" -