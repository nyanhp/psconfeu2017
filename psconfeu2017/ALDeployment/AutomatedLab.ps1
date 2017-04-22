$labName = 'psconfeu2017jhp'
$defaultLocation = 'west europe'
$azureContext = 'D:\Jhp.azurermsettings'
$domainName = 'poshjhp.com'

# Lab definition
New-LabDefinition -Name $labname -DefaultVirtualizationEngine Azure

Add-LabAzureSubscription -Path $azureContext -DefaultLocationName $defaultLocation

# Optional step. Fully sync everything except for OS ISOs by calling Sync-LabazureLabSources without parameters
Sync-LabAzureLabSources -SkipIsos -MaxFileSizeInMb 1

# Define a domain
Add-LabDomainDefinition -Name $domainName -AdminUser 'jhp' -AdminPassword 'Somepass1'

$PSDefaultParameterValues = @{
    'Add-LabMachineDefinition:DomainName' = $domainName
    'Add-LabMachineDefinition:OperatingSystem' = 'Windows Server 2012 R2 SERVERDATACENTER'
}

# Add a DC with post-installation scripts for user creation
$roles = @()
$roles += Get-LabMachineRoleDefinition -Role RootDC
#$roles += Get-LabMachineRoleDefinition -Role CaRoot
Add-LabMachineDefinition -Name 'jhp-dc01' -MinMemory 1GB -Roles $roles

# Add a SQL 2014 server
$role = Get-LabMachineRoleDefinition -Role SQLServer2014
Add-LabMachineDefinition -Name 'jhp-sql01' -MinMemory 1GB  -Roles $role

# Add a simple web server
Add-LabMachineDefinition -Name 'jhp-web01' -Roles 'WebServer'

Install-Lab

$machines = Get-LabMachine
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\Notepad++.exe -CommandLine /S -AsJob
Install-LabSoftwarePackage -ComputerName $machines -Path $labSources\SoftwarePackages\winrar.exe -CommandLine /S -AsJob
Get-Job -Name 'Installation of*' | Wait-Job | Out-Null

Show-LabDeploymentSummary