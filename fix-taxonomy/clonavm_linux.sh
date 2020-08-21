#!/bin/bash  

#####	NOME:				clonavm_lnx.sh
#####	VERSÃO:				1.0
#####	DESCRIÇÃO:			Script para clone de VM no mesmo Resource Group com a finalidade de correcao de Taxonomia dos recursos de uma VM no Azure			
#####	DATA DA CRIAÇÃO:	18/08/2020
#####	ESCRITO POR:		Diogo Fernandes
#####	E-MAIL:				dfernandes@4mstech.com 			




# Color Output Variables: http://kedar.nitty-witty.com/blog/how-to-echo-colored-text-in-shell-script #
txtrst=$(tput sgr0) # Text reset
txtred=$(tput setaf 1) # Red
txtgrn=$(tput setaf 2) # Green
txtylw=$(tput setaf 3) # Yellow
txtblu=$(tput setaf 4) # Blue
txtpur=$(tput setaf 5) # Purple
txtcyn=$(tput setaf 6) # Cyan
txtwht=$(tput setaf 7) # White
echo -e "${txtblu}Script de Clonagem de VM e correção de taxonomia AZURE${txtrst}!\n"
subscription="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"                                                                                 # SUBSCRIPTION
az account set -s $subscription
############ VARIAVEIS PRINCIPAIS ###################
vmsource="VM-CENTOS7"                                                                                                               # NOME DA VM ANTIGA
newvm="VM-RHEL"                                                                                                                     # NOME DA VM NOVA
############ -------------------- ###################
rg=`az vm list --query '[].{Name:name,RG:resourceGroup}' --output tsv  | grep -i $vmsource | awk -F ' ' '{print $2}'`               # RG DA VM

nic=`az vm show -g $rg -n $vmsource --query "networkProfile.networkInterfaces[].id" -o tsv`                                         # ID DA NIC
nicnamesrc=`az vm show -g $rg -n $vmsource --query "networkProfile.networkInterfaces[].id" -o tsv | awk -F '/' '{print $9}'`        # NOME DA NIC
ip=`az network nic show --ids $nic --query 'ipConfigurations[0].privateIpAddress' -o tsv`                                           # IP DA ORIGEM
subnetid="`az network nic show --ids $nic --query 'ipConfigurations[0].subnet.id' -o tsv`"                                          # ID DA SUBNET
ipconfigsrc=`az network nic ip-config list -g $rg --nic-name $nicnamesrc --query '[].{Name:name}' --output tsv`                     # NOME IPCONFIG ORIGEM

NewDataDisk=(`az vm show -n $vmsource -g $rg --query storageProfile.dataDisks[*].name -o tsv`)                                      # PEGA DATADISKS
vmsize=`az vm show -g $rg -n $vmsource --query 'hardwareProfile.vmSize' -o tsv`                                                     # SIZE DE ORIGEM
diskossource=`az vm show -d -g $rg -n $vmsource --query "storageProfile.osDisk.managedDisk.id" -o tsv | awk -F "/" '{ print $9 }'`  # PEGA OSDISK

disksku="Standard_LRS"                                                                                                              # HDD = Standard_LRS, SSD = StandardSSD_LRS, PREMIUM = Premium_LRS,
newosdisk="$newvm-OsDisk"                                                                                                           # NOME DO NOVO OSDISK

az network nic create --resource-group $rg --name $newvm-nic1 --subnet $subnetid                                                    
echo -e "${txtblu}Criando a NIC da VM Destino:${txtrst} ${txtgrn}`echo $newvm-nic1:` `az network nic ip-config list -g $rg --nic-name $newvm-nic1 --query '[].{ip:privateIpAddress}' --output tsv`${txtrst}\n" 
ipconfignew=`az network nic ip-config list -g $rg --nic-name $newvm-nic1 --query '[].{Name:name}' --output tsv`                             # NOME IPCONFIG DESTINO

echo -e "${txtblu}Clonando o/os Discos da VM de Origem:${txtrst}\n"
az disk create --resource-group $rg --name $newosdisk --sku $disksku --source $diskossource
echo -e "\n"
comando="az vm create --resource-group $rg --name $newvm --nics $newvm-nic1 --os-type Linux --size $vmsize --attach-os-disk $newosdisk"     # ARMAZENA COMANDO INICIAL DE CRIAÇÃO DA VM SOMENTE COM OSDISK

for ((j=0; j < ${#NewDataDisk[*]}; j++))
    do
        newdatadisk="$newvm-LUN$j"
        az disk create --resource-group $rg --name $newdatadisk --sku $disksku --source ${NewDataDisk[$j]}
        if [ $j == 0 ]; then
                comando="$comando --attach-data-disk $newdatadisk"
        else
                comando="$comando $newdatadisk"
        fi
done
echo -e "\n"
echo -e "${txtblu}Criando a VM Nova:${txtrst}\n"
echo -e "\n"
$comando

# DELETA O RECURSO VM
echo -e "Excluindo a VM ANTIGA: ${txtylw}$vmsource${txtrst}\n"
az resource delete --resource-group $rg --resource-type Microsoft.Compute/virtualMachines --name $vmsource
# DELETA O RECURSO NIC
echo -e "Excluindo a NIC ANTIGA: ${txtylw}$nicnamesrc${txtrst}\n"
az resource delete --resource-group $rg --resource-type Microsoft.Network/networkInterfaces --name $nicnamesrc
# TROCANDO OS IPs
echo -e "Atualizando o IP para modo estático: ${txtgrn}$newvm-nic1: $ip${txtrst}\n"
az network nic ip-config update -g $rg --nic-name $newvm-nic1 -n $ipconfignew --private-ip-address $ip
echo -e "\n"
# EXCLUINDO DISCOS ANTIGOS
echo -e "Excluir os discos de origem:\n${txtgrn}`az disk list -g $rg --query "[?starts_with(name,'$vmsource')]".name -o tsv`${txtrst}\nDeseja continuar?\n"  
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) echo -e "Excluindo...\n"; 
            az disk list -g $rg --query "[?starts_with(name,'$vmsource')]".id --output tsv | xargs -L1 bash -c 'az disk delete --ids $0 --yes'
            echo -e "Discos excluidos\n"
            break;;
            No ) exit;;
        esac
    done
echo -e "${txtgrn}Clone da VM: $vmsource para $newvm foi finalizado com sucesso.${txtrst}\n"
