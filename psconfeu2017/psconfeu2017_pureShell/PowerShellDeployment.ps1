[string]$SubscriptionPath = 'D:\jhp.azurermsettings'
[string]$SubscriptionName = 'AL4'
[string]$ResourceGroupName = "Test3"
[string]$Location = 'West Europe'
[string]$LabName = 'Test3'
[string]$PublisherName = 'MicrosoftWindowsServer'
[string]$OfferName = 'WindowsServer'
[string]$SkusName = '2016-Datacenter'  

Select-AzureRmProfile -Path $SubscriptionPath
Set-AzureRmContext -SubscriptionName $SubscriptionName


New-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue -Location $Location -Force
New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name automatedlabmfaxwkjw -ErrorAction SilentlyContinue -Location $Location -SkuName Standard_LRS
[object]$StorageContext = (Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name automatedlabmfaxwkjw).Context

$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name Subnet1 -AddressPrefix '192.168.4.0/24'
New-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Name $LabName -Location $Location -AddressPrefix '192.168.4.0/24' -Force -Subnet $subnetConfig


$Machines = @(
        @{
            Name = 'DC'
            IpV4Address = '192.168.4.7'
            Network = '192.168.4.0/24'
        }
        @{
            Name = 'WEB1'
            IpV4Address = '192.168.4.8'
            Network = '192.168.4.0/24'
        }
        @{
            Name = 'WEB2'
            IpV4Address = '192.168.4.79'
            Network = '192.168.4.0/24'
        }
)

foreach($machine in $Machines)
{

[object]$Disks = @()
[string]$Vnet = 'Test3'
[string]$RoleSize = 'Standard_D2'
[string]$AdminUserName = 'Install'
[string]$AdminPassword = 'Somepass1'
[string]$MachineResourceGroup = 'Test3'
[object]$DefaultIpAddress =  $Machine.IPV4Address
      


$subnet = (Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName |
Where-Object { $_.AddressSpace.AddressPrefixes.Contains($Machine.Network) })[0] |
Get-AzureRmVirtualNetworkSubnetConfig
                                     
$securePassword = ConvertTo-SecureString -String $AdminPassword -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($AdminUserName, $securePassword)

$machineAvailabilitySet = Get-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name ($Machine.Network)[0] -ErrorAction SilentlyContinue
if(-not ($machineAvailabilitySet))
{
    $machineAvailabilitySet = New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name ($Machine.Network)[0] -Location $Location -ErrorAction Stop   
}

$vm = New-AzureRmVMConfig -VMName $Machine.Name -VMSize $RoleSize -ErrorAction Stop -AvailabilitySetId $machineAvailabilitySet.Id
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $Machine.Name -Credential $cred -ProvisionVMAgent -EnableAutoUpdate -ErrorAction Stop -WinRMHttp
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName $PublisherName -Offer $OfferName -Skus $SkusName -Version "latest" -ErrorAction Stop
$defaultIPv4Address = $DefaultIpAddress

$nicProperties = @{
    Name = "$($Machine.Name.ToLower())nic0"
    ResourceGroupName = $ResourceGroupName
    Location = $Location
    Subnet = $subnet
    PrivateIpAddress = $defaultIPv4Address
    ErrorAction = "Stop"
}
        
$networkInterface = New-AzureRmNetworkInterface @nicProperties
        
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $networkInterface.Id -ErrorAction Stop
        
                                   
$DiskName = "$($machine.Name)_os"
$OSDiskUri = "$($StorageContext.BlobEndpoint)automatedlabdisks/$DiskName.vhd"
        
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $DiskName -VhdUri $OSDiskUri -CreateOption fromImage -ErrorAction Stop

New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $vm -ErrorAction Stop -Verbose
}