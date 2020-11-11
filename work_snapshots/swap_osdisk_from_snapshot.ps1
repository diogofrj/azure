#####   NOME:               swap_osdisk_from_snapshot.ps1
#####   VERSÃO:             1.0
#####   DESCRIÇÃO:          Gera Snapshots de uma VM Azure.
#####   DATA DA CRIAÇÃO:    11/11/2020
#####   WRITTEN BY:         Diogo Fernandes
#####   E-MAIL:             dfernandes@4mstech.com
#####   DISTRIBUTION:       Windows/Linux
#####   REFERENCE:          https://docs.microsoft.com/pt-br/azure/virtual-machines/scripts/virtual-machines-powershell-sample-copy-managed-disks-vhd

############################# PERSONALIZADO ########################################
$VMName = "vmwindows"
$diskSize = '128'
$storageType = 'Standard_LRS'   # Standard_LRS, StandardSSD_LRS, Premium_LRS
# -------------------------------------------------------------------------------- #
$date = $(Get-Date -UFormat "%d%b%Y-%HH%MM")
$vm = Get-AzVM -Name $VMName
$osDiskName = $vm.StorageProfile.OSDisk.Name
$rgName = $vm.ResourceGroupName
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

Write-Host -ForegroundColor Blue "Listando os SnapShots existentes..."
    (Get-AzSnapshot -SnapshotName "*$VMName*").Name
    $snapshotName = read-host "Please enter Snapshot Name............" 
    $diskName = read-host "Please enter OSDiskName............"
    $snapshot = Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName 
    $diskConfig = New-AzDiskConfig -SkuName $storageType -Location $vm.Location -CreateOption Copy -SourceResourceId $snapshot.Id
Write-Host -ForegroundColor Blue "Criando disco gerenciado..."
    $newosdisk = New-AzDisk -Disk $diskConfig -ResourceGroupName $rgName -DiskName $diskName

Write-Host -ForegroundColor Blue "Desligando a VM..." $vm.Name
    Stop-AzVM -ResourceGroupName $rgName -Name $vm.Name -Force
    Set-AzVMOSDisk -VM $vm -ManagedDiskId $newosdisk.Id -Name $newosdisk.Name 
    Set-AzVMBootDiagnostics -VM $vm -Disable

Write-Host -ForegroundColor Blue "Fazendo o Swap do disco do S.O..." $osDiskName "para" $newosdisk.Name
    Update-AzVM -ResourceGroupName $rgName -VM $vm 

Write-Host -ForegroundColor Blue "Ligando a VM..." $vm.Name
    Start-AzVM -Name $vm.Name -ResourceGroupName $rgName
