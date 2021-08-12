#####   FILENAME:           tag_resources_wvd_vms.ps1
#####   VERSION:            2.0
#####   DESCRIPTION:        Aplicar Tags em Recursos associados em VMs e WVD
#####   CREATION DATE:      15/03/2021
#####   WRITTEN BY:         Diogo Fernandes
#####   E-MAIL:             dfs@outlook.com.br
#####   DISTRIBUTION:       N/A
#####   REFERENCE:          https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/decision-guides/resource-tagging/#resource-tagging-patterns

######################################## PERSONALIZADO ###########################################
#$SUB = (Get-AzContext).Subscription.Id                                                          #   
#Select-AzSubscription -SubscriptionId $SUB                                                      #
#$VMNAME = @((get-azvm).Name)               ## ALL VMs                                           #
$VMNAME = @("vmteste", "VM-HSBR-0")                                                              #
$OPERATION = "Merge"                        ## Operation: "Merge, Replace, Delete"               #
$TAG_RG = '0'                                                                                    #
$TAG_VM = '0'                                                                                    #
$TAG_DISKs = '0'                                                                                 #
$TAG_RESOURCES = '0'                                                                             #
$TAG_WVD_RESOURCES = '0'                    ## workspaces, hostpools e applicationgroups         #
##################################################################################################

$tags_vm = @{
    "start_workday" = "0700"
    "stop_workday"  = "1900"
    "Application"   = "WVD"
    "Hostpool"      = "HOSTPOOL-XPTO"
    "Workspace"     = "WORKSPACE-XPTO"
}
$tags_vm_resources = @{
    "Application"   = "WVD"
    "Hostpool"      = "HOSTPOOL-XPTO"
    "Workspace"     = "WORKSPACE-XPTO"
}
$tags_rg = @{
    "Application"       = "WVD"
    "owner"             = "Bill Smith"
    "owner-contact"     = "bsmith@contoso.com"
    "ar"                = "123456"
    "department"        = "TRAINNING"
    "technical-contact" = "dfernandes@4mstech.com"
}
$tags_wvd = @{
    "Application"       = "WVD"
    "department"        = "MARKETING"
    "owner"             = "DIOGO"
    "technical-contact" = "dfernandes@4mstech.com"
}
########################################################################################################################################################

foreach ($VM in $VMNAME) {
    $vm = Get-AzVM -Name $VM                                                                     
    $rgName = $vm.ResourceGroupName 
    
    if ($TAG_RG -eq '1') {
        Write-Host -ForegroundColor Green "Tagging Resource Group of the.................................:" $rgName
        Update-AzTag -Tag $tags_rg -ResourceId $((Get-AzResourceGroup -Name $rgName).ResourceId) -Operation $OPERATION  
    }
    if ($TAG_VM -eq '1') {
        $VMID = (Get-AzResource -ResourceGroupName $rgName -ResourceType Microsoft.Compute/virtualMachines | where-object { $_.Name -like "*$VMNAME*" }).Id
        Write-Host -ForegroundColor Green "Tagging VM....................................................:" $vm.Name
        Update-AzTag -Tag $tags_vm -ResourceId $vm.Id -Operation $OPERATION 
    }
    if ($TAG_DISKs -eq '1') {
        Write-Host -ForegroundColor Green "Tagging OS Disk associated with the VM........................:" $vm.Name
        $OSDISK = (get-azdisk -Name $($vm.StorageProfile.OsDisk.Name)).Id
        Update-AzTag -Tag $tags_vm_resources -ResourceId $OSDISK -Operation $OPERATION
    
        if ($($vm.StorageProfile.DataDisks) -ne $null) {
            Write-Host -ForegroundColor Green "Tagging DATADISKs associated with the VM......................:" $vm.Name
            foreach ($datadisks in $vm.StorageProfile.DataDisks) {
                $datadiskname = $datadisks.name
                $DatadiskID = (Get-Azdisk -Name $datadiskname).id
                Update-AzTag -Tag $tags_vm_resources -ResourceId $DatadiskID -Operation $OPERATION
            }
        }
    }
    if ($TAG_RESOURCES -eq '1') {    
        Write-Host -ForegroundColor Green "Tagging NICs associated with the VM...........................:" $vm.Name
        foreach ($nicUri in $vm.NetworkProfile.NetworkInterfaces.Id) {
            $nic = Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nicUri.Split('/')[-1]
            Update-AzTag -Tag $tags_vm_resources -ResourceId $nic.Id -Operation $OPERATION
            foreach ($ipConfig in $nic.IpConfigurations) {
                if ($ipConfig.PublicIpAddress -ne $null) {
                    Write-Host -ForegroundColor Green "Tagging PIPs associated with the VM's NIC.....................:" $vm.Name
                    Update-AzTag -Tag $tags_vm_resources -ResourceId $ipConfig.PublicIpAddress.Id -Operation $OPERATION
                }
            }
        }
        if ($null -ne $($vm.AvailabilitySetReference.Id)) {
            Write-Host -ForegroundColor Green "Tagging Availability Set associated with the VM...............:" $vm.Name
            Update-AzTag -Tag $tags_vm_resources -ResourceId $($vm.AvailabilitySetReference.Id) -Operation $OPERATION
            if ($null -ne $($vm.ProximityPlacementGroup.Id)) {
                Write-Host -ForegroundColor Green "Tagging Proximity Placement Group associated with the VM......:" $vm.Name
                Update-AzTag -Tag $tags_vm_resources -ResourceId $($vm.ProximityPlacementGroup.Id) -Operation $OPERATION
            }
        }
    }
}
if ($TAG_WVD_RESOURCES -eq '1') {
    Write-Host -ForegroundColor Green "Tagging WVD Resources........................................: Workspaces, Hostpools and App Groups" 
    $WVD_IDs = (Get-AzResource | Where-Object { $_.ResourceType -like "*DesktopVirtualization*" }).ResourceId
#   $ID_REGEX = (Get-AzResource | where-object { $_.ResourceType -like "*DesktopVirtualization*" }).ResourceId | Where-Object { $_ -like "*dfernandes*" }    
    foreach ($item in $WVD_IDs) {
        Update-AzTag -Tag $tags_wvd -ResourceId $item -Operation $OPERATION 
    }
}



#### Tag Examples ####
<#
$tags = @{
    "start_workday" = "on_demand"
    "stop_workday" = "on_demand"
    "start_workday" = "0700"
    "stop_workday" = "1900"
    "start_weekend" = "0900"
    "stop_weekend" = "1800"
}
#>
