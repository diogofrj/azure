#####   FILENAME:           gera_snapshot.ps1
#####   VERSION:            1.0
#####   DESCRIPTION:        Gera Snapshots de uma VM Azure e Exporta em VHD para um Blob
#####   CREATION DATE:      11/11/2020
#####   WRITTEN BY:         Diogo Fernandes
#####   E-MAIL:             dfernandes@4mstech.com
#####   DISTRIBUTION:       Windows/Linux
#####   REFERENCE:          https://docs.microsoft.com/pt-br/azure/virtual-machines/scripts/virtual-machines-powershell-sample-copy-managed-disks-vhd

############################# PERSONALIZADO ########################################
$VMName = "<VM_NAME>"
$savetoblob = 0         #-Deseja exportar o Snapshot para um blob? SIM = 1 e NÃO = 0
$snapdatadisks = 0      #-Deseja gerar o Snapshots dos DataDisks ? SIM = 1 e NÃO = 0
# -------------------------------------------------------------------------------- #

#################### ????? SALVAR SNAPSHOT NO BLOB ????? ###########################
#################### INFORMAÇÕES DO STORAGE + CONTAINER ###########################
$storageAccountName = "<STORAGE ACCOUNT>"
$storageContainerName = "<CONTAINER>"
# -------------------------------------------------------------------------------- #

$storageAccountKey = (((Get-AzStorageAccount)| Where-Object {$_.StorageAccountName -eq "$storageAccountName"}) | Get-AzStorageAccountKey | Where-Object {$_.KeyName -eq "key1"}).Value
$sasExpiryDuration = "3600"

$date = $(Get-Date -UFormat "%d%b%Y-%HH%MM")
$vm = Get-AzVM -Name $VMName
$rgName = $vm.ResourceGroupName

$osDiskName = $vm.StorageProfile.OSDisk.Name
$datadisks = $vm.StorageProfile.DataDisks
$OSDiskID = (Get-Azdisk -Name $osDiskName).id

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

if ($vm.StorageProfile.DataDisks.Count -gt '0' -And $snapdatadisks -ne '0') {
#-OSDISK
        $OSdestinationVHDFileName = "SNAP-$VMName-OSDisk-$date.vhd"
        $OSSnapshotConfig = New-AzSnapshotConfig -SourceUri $OSDiskID -CreateOption Copy -Location $vm.Location -OsType $vm.StorageProfile.OsDisk.OsType
        $OSSnapshot = New-AzSnapshot -Snapshot $OSSnapshotConfig -SnapshotName SNAP-$VMName-OSDisk-$date -ResourceGroupName $rgName
    Write-Host SNAP-$VMName-OSDisk-$date -ForegroundColor Green

#-EXPORT OSDISK TO BLOB
    if($savetoblob -eq '1'){
        $os_sas = Grant-AzSnapshotAccess -ResourceGroupName $rgName -SnapshotName $OSSnapshot.Name -DurationInSecond $sasExpiryDuration -Access Read
    #Write-Output $os_sas
        $destinationContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
        $containerSASURI = New-AzStorageContainerSASToken -Context $destinationContext -ExpiryTime(get-date).AddSeconds($sasExpiryDuration) -FullUri -Name $storageContainerName -Permission rw
    Write-Host "`nExporting SNAP-$VMName-OSDisk-$date Snapshot and Copy to Blob..." -ForegroundColor Red
        $containername,$sastokenkey = $containerSASURI -split "\?"
        $containerSASURI = "$containername/$OSdestinationVHDFileName`?$sastokenkey"
    azcopy copy $os_sas.AccessSAS $containerSASURI
    Write-Host "`n$OSdestinationVHDFileName Exported Sucessfully..." -ForegroundColor Red
    #Write-Host -ForegroundColor Cyan "azcopy copy" $os_sas.AccessSAS $containerSASURI
        Revoke-AzSnapshotAccess -ResourceGroupName $rgName -SnapshotName $OSSnapshot.Name
    }
#-DATADISKS
    $count = -1
    foreach ($datadisks in $vm.StorageProfile.DataDisks){
        $count++
        $d = "Datadisk"
    $datadiskname=$datadisks.name
    $DATAdestinationVHDFileName = "SNAP-$VMName-$d$count-$date.vhd"
    $DatadiskID = (Get-Azdisk -Name $datadiskname).id
    $SnapshotConfig = New-AzSnapshotConfig -SourceUri $DatadiskID -CreateOption Copy -Location $vm.Location 
    $DataSnapshot = New-AzSnapshot -Snapshot $SnapshotConfig -SnapshotName SNAP-$VMName-$d$count-$date -ResourceGroupName $rgName
    Write-Host SNAP-$VMName-$d$count-$date -ForegroundColor Cyan
    
#-EXPORT DATADISKS TO BLOB
    if($savetoblob -eq '1'){
        $data_sas = Grant-AzSnapshotAccess -ResourceGroupName $rgName -SnapshotName $DataSnapshot.Name -DurationInSecond $sasExpiryDuration -Access Read
    #Write-Output $data_sas
        $DATAdestinationContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
        $DATAcontainerSASURI = New-AzStorageContainerSASToken -Context $DATAdestinationContext -ExpiryTime(get-date).AddSeconds($sasExpiryDuration) -FullUri -Name $storageContainerName -Permission rw
    Write-Host "`nExporting SNAP-$VMName-$d$count-$date Snapshot and Copy to Blob..." -ForegroundColor Red
        $containername,$sastokenkey = $DATAcontainerSASURI -split "\?"
        $DATAcontainerSASURI = "$containername/$DATAdestinationVHDFileName`?$sastokenkey"
    azcopy copy $data_sas.AccessSAS $DATAcontainerSASURI
        Write-Host -ForegroundColor Red "`n$DATAdestinationVHDFileName Exported Sucessfully..." 
        #Write-Host -ForegroundColor Cyan "azcopy copy" $data_sas.AccessSAS $DATAcontainerSASURI
        Revoke-AzSnapshotAccess -ResourceGroupName $rgName -SnapshotName $DataSnapshot.Name
    }         
  }
}  else {
        $OSdestinationVHDFileName = "SNAP-$VMName-OSDisk-$date.vhd"
        $OSSnapshotConfig = New-AzSnapshotConfig -SourceUri $OSDiskID -CreateOption Copy -Location $vm.Location -OsType $vm.StorageProfile.OsDisk.OsType
        $OSSnapshot = New-AzSnapshot -Snapshot $OSSnapshotConfig -SnapshotName SNAP-$VMName-OSDisk-$date -ResourceGroupName $rgName
    Write-Host SNAP-$VMName-OSDisk-$date -ForegroundColor Green
    if($savetoblob -eq '1'){
        $os_sas = Grant-AzSnapshotAccess -ResourceGroupName $rgName -SnapshotName $OSSnapshot.Name -DurationInSecond $sasExpiryDuration -Access Read
    #Write-Output $os_sas
        $destinationContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
        $containerSASURI = New-AzStorageContainerSASToken -Context $destinationContext -ExpiryTime(get-date).AddSeconds($sasExpiryDuration) -FullUri -Name $storageContainerName -Permission rw
    Write-Host "`nExporting SNAP-$VMName-OSDisk-$date Snapshot and Copy to Blob..." -ForegroundColor Red
        $containername,$sastokenkey = $containerSASURI -split "\?"
        $containerSASURI = "$containername/$OSdestinationVHDFileName`?$sastokenkey"
        azcopy copy $os_sas.AccessSAS $containerSASURI
    Write-Host -ForegroundColor Red "`n$OSdestinationVHDFileName Exported Sucessfully..." 
    #Write-Host -ForegroundColor Cyan "azcopy copy" $sas.AccessSAS $containerSASURI
        Revoke-AzSnapshotAccess -ResourceGroupName $rgName -SnapshotName $OSSnapshot.Name
    }

}




(Get-AzSnapshot -SnapshotName "SNAP-$VMName*").Name
