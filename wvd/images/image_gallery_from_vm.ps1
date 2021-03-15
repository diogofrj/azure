<#
   FILENAME:           image_gallery_from_vm.ps1
   VERSION:            1.0
   DESCRIPTION:        O Script se propoe a automatizar decisões de gerenciamento de imagens a partir de uma VM Generalizada
   CREATION DATE:      06/03/2021
   WRITTEN BY:         Diogo Fernandes
   E-MAIL:             dfernandes@4mstech.com
   DISTRIBUTION:       N/A
   REFERENCE:          https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-customize-master-image
#>
##########################  VARIAVEIS GERAIS  #############################
$vmName = "VMGOLDEM01"
$rgName = "RG_WVD_IMAGES"
$location = "EastUS2"
$imageName = "IMG-WVD-032021"

$galleryname = "wvd_gallery"                  # Ex:  wvd_gallery, wvdgallery (não usar - no nome)
$imgdef = "Windows-10-WVD-Template"        # Escolha um nome de definição da imagem
$ImageVersionName = "1.0.0"                  # Para uma galeria nova, iniciar com um numero de versao
#-------------------------------------------------------------------------#
##########################  VARIAVEIS DE DECISÃO  #########################
$new_gallery = '0'
$exist_gallery = '0'
$only_new_image = '1'
#------------ Somente uma das variaveis pode ter o valor 1 ---------------#

###### SESSION: ONLY NEW IMAGE
if ($new_gallery -eq '0' -And $exist_gallery -eq '0' -And $only_new_image -eq '1') {

   ### Create Image
   Write-Host -ForegroundColor Cyan "Deallocating VM...................................:" $vmName
   Stop-AzVM -ResourceGroupName $rgName -Name $vmName -Force
   Write-Host -ForegroundColor Cyan "Generalizing VM...................................:" $vmName 
   Set-AzVm -ResourceGroupName $rgName -Name $vmName -Generalized

   $vm = Get-AzVM -Name $vmName -ResourceGroupName $rgName
   $image = New-AzImageConfig -Location $location -SourceVirtualMachineId $vm.Id

   Write-Host -ForegroundColor Cyan "Creating Image from VM............................:" $vmName  
   $managedImage = New-AzImage -Image $image -ImageName $imageName -ResourceGroupName $rgName
   Write-Host -ForegroundColor Green "Created the Image.................................:" $managedImage.Name
   ## End Image
}
### END SESSION

###### SESSION: NEW GALLERY
if ($new_gallery -eq '1' -And $exist_gallery -eq '0' -And $only_new_image -eq '0') {

   ### Create Image
   Write-Host -ForegroundColor Cyan "Deallocating VM...................................:" $vmName
   Stop-AzVM -ResourceGroupName $rgName -Name $vmName -Force
   Write-Host -ForegroundColor Cyan "Generalizing VM...................................:" $vmName 
   Set-AzVm -ResourceGroupName $rgName -Name $vmName -Generalized

   $vm = Get-AzVM -Name $vmName -ResourceGroupName $rgName
   $image = New-AzImageConfig -Location $location -SourceVirtualMachineId $vm.Id

   Write-Host -ForegroundColor Cyan "Creating Image from VM............................:" $vmName  
   $managedImage = New-AzImage -Image $image -ImageName $imageName -ResourceGroupName $rgName
   Write-Host -ForegroundColor Green "Created the Image.................................:" $managedImage.Name
   ## End Image

   Write-Host -ForegroundColor Cyan "Creating Share Image Gallery......................:" $galleryname
   ### Create Gallery
   $gallery = New-AzGallery `
      -GalleryName $galleryname `
      -ResourceGroupName $rgName `
      -Location $location `
      -Description 'Shared Image Gallery for WVD' 
   Write-Host -ForegroundColor Green "Created Share Image Gallery.......................:" $gallery.Name
   ## End Gallery

<#
#Share the gallery (Optional)
# Get the object ID for the user
$user = Get-AzADUser -StartsWith alinne_montes@contoso.com
# Grant access to the user for our gallery
New-AzRoleAssignment `
   -ObjectId $user.Id `
   -RoleDefinitionName Reader `
   -ResourceName $gallery.Name `
   -ResourceType Microsoft.Compute/galleries `
   -ResourceGroupName $gallery.ResourceGroupName 
#>

   Write-Host -ForegroundColor Cyan "Creating Image Definition.........................:" $imgdef
   ### Create Definition Image
   $imageDefinition = New-AzGalleryImageDefinition `
      -GalleryName $gallery.Name `
      -ResourceGroupName $gallery.ResourceGroupName `
      -Location $gallery.Location `
      -Name $imgdef `
      -OsState generalized `
      -OsType Windows `
      -Publisher 'MicrosoftWindowsDesktop' `
      -Offer 'Windows-10' `
      -Sku '20h2-evd'
   Write-Host -ForegroundColor Green "Created Image Definition..........................:" $imageDefinition.Name
   ## End Definition Image

<#
$managedImage = Get-AzImage `
   -ImageName WVD_IMAGE_V1 `
   -ResourceGroupName $rgName
#>
   ### Create Image Version
   Write-Host -ForegroundColor Cyan "Creating Image Version '$ImageVersionName' in Definition......:" $imageDefinition.Name 
   $region1 = @{Name = 'East US 2'; ReplicaCount = 1 }
   #  $region2 = @{Name='Brazil South';ReplicaCount=2}
   #  $targetRegions = @($region1,$region2)
   $targetRegions = @($region1)
   $job = $imageVersion = New-AzGalleryImageVersion `
      -GalleryImageDefinitionName $imageDefinition.Name `
      -GalleryImageVersionName $ImageVersionName `
      -GalleryName $gallery.Name `
      -ResourceGroupName $imageDefinition.ResourceGroupName `
      -Location $imageDefinition.Location `
      -TargetRegion $targetRegions  `
      -SourceImageId $managedImage.Id.ToString() `
      -asJob
      Write-Host -ForegroundColor Green "Created Image Version '$ImageVersionName' in Definition.......:" $imageDefinition.Name
      
      Write-Host "`nC"
      Write-Host "Follow Job State executing: '(Get-Job).State'"
      Write-Host "(((Get-AzGalleryImageVersion -ResourceGroupName $rgName -GalleryName $galleryname -GalleryImageDefinitionName $imgdef -GalleryImageVersionName $ImageVersionName -ExpandReplicationStatus).ReplicationStatus).Summary[0]) | Select-Object State,Progress"
   ## End Image Version
}
### END SESSION
 
###### SESSION: EXISTENT GALLERY
if ($new_gallery -eq '0' -And $exist_gallery -eq '1' -And $only_new_image -eq '0') {

   ### Create Image
   Write-Host -ForegroundColor Cyan "Deallocating VM...................................:" $vmName
   Stop-AzVM -ResourceGroupName $rgName -Name $vmName -Force
   Write-Host -ForegroundColor Cyan "Generalizing VM...................................:" $vmName 
   Set-AzVm -ResourceGroupName $rgName -Name $vmName -Generalized

   $vm = Get-AzVM -Name $vmName -ResourceGroupName $rgName
   $image = New-AzImageConfig -Location $location -SourceVirtualMachineId $vm.Id

   Write-Host -ForegroundColor Cyan "Creating Image from VM............................:" $vmName  
   $managedImage = New-AzImage -Image $image -ImageName $imageName -ResourceGroupName $rgName
   Write-Host -ForegroundColor Green "Created the Image.................................:" $managedImage.Name
   ## End Image

   ### Getting SIG Infos
   Write-Host -ForegroundColor Cyan "Listing Existent Share Image Gallerie(s)..........:" 
   (Get-AzGallery).Name

   $SIGNAME = Read-Host "Select SIG........................................"
   $GALLERY = (Get-AzGallery -GalleryName $SIGNAME)
   $GALLERYRG = $GALLERY.ResourceGroupName

   Write-Host -ForegroundColor Cyan "Listing Image Definitions from SIG................:" $GALLERY.Name   
   $IMGDEFS = (Get-AzGalleryImageDefinition -ResourceGroupName $GALLERYRG -GalleryName $SIGNAME)
   Write-Output $IMGDEFS.Name
   $IMGDEF = Read-Host "Select Image Definition..........................."

   $IMGVER = Get-AzGalleryImageVersion -ResourceGroupName $GALLERYRG -GalleryName $SIGNAME -GalleryImageDefinitionName $IMGDEF # -GalleryImageVersionName 1.0.0

   Write-Host -ForegroundColor Cyan "Listing Image Versions from Image Definition......:" $IMGVER.Name
   Write-Output $IMGVER.Id

   $IMGID = Read-Host "Select the next version number: Ex: 2.1.1 ........"
   ## End SIG

   ### Create Image Version
   Write-Host -ForegroundColor Cyan "Creating Image Version ID '$IMGID' in Definition.......:" $IMGDEFS.Name
   $region1 = @{Name = 'East US 2'; ReplicaCount = 1 }
   #  $region2 = @{Name='Brazil South';ReplicaCount=2}
   #  $targetRegions = @($region1,$region2)
   $targetRegions = @($region1)
   $job = $imageVersion = New-AzGalleryImageVersion `
      -GalleryImageDefinitionName $IMGDEF `
      -GalleryImageVersionName $IMGID `
      -GalleryName $GALLERY.Name `
      -ResourceGroupName $GALLERY.ResourceGroupName `
      -Location $GALLERY.Location `
      -TargetRegion $targetRegions  `
      -SourceImageId $managedImage.Id.ToString() `
      -asJob
         
   Write-Host "`nPlease, wait for replication. You can use the commands bellow to see status of the Replications"
   Write-Host "`n(Get-Job).State"
   Write-Host "(((Get-AzGalleryImageVersion -ResourceGroupName $GALLERYRG -GalleryName $SIGNAME -GalleryImageDefinitionName $IMGDEF -GalleryImageVersionName $IMGID -ExpandReplicationStatus).ReplicationStatus).Summary[0]) | Select-Object State,Progress"
}
### END SESSION

if ($new_gallery -eq '0' -And $exist_gallery -eq '0' -And $only_new_image -eq '0') {
   Write-Host -ForegroundColor Green "Variaveis de Decisão iguais a '0', escolha uma unica ação" 
}
elseif ( ($new_gallery -ne '0' -and $exist_gallery -ne '0') -xor ($exist_gallery -ne '0' -and $only_new_image -ne '0') -xor ($new_gallery -ne '0' -and $only_new_image -ne '0') ) {
   Write-Host -ForegroundColor Green "Duas ou mais variaveis de decisão marcadas ou vazias, somente valores 1 ou 0 são aceitos, escolha uma." 
}


<# Optional
Remove-AzImage `
   -ImageName $managedImage.Name `
   -ResourceGroupName $managedImage.ResourceGroupName
#>
