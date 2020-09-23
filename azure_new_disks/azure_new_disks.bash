#!/bin/bash
# Color Output Variables: http://kedar.nitty-witty.com/blog/how-to-echo-colored-text-in-shell-script #
txtrst=$(tput sgr0) # Text reset
txtred=$(tput setaf 1) # Red
txtgrn=$(tput setaf 2) # Green

echo -e "${txtred}#---------------Listagem das Luns--------------------#${txtrst}"
        echo -e "`ls -l /dev/disk/azure/scsi1/ | awk '{ print $9 $10 $11}'`\n"
echo -e "${txtred}#---------------Listagem dos discos e tamanhos-------#${txtrst}"
        echo -e "`lsblk -i -o size,name,state,type,label,model,serial | grep -E 'Virtual Disk|SERIAL|part' | grep -vE 'sda|sdb'`\n"

######## Execução Interativa ########
#read -p "Digite a LUN: Ex: 'lun0, lun1, lun12' " lun
#read -p "Digite a pasta de montagem: Ex:'/dados01' " mountpoint

######## Parametros obrigatórios em tempo de execução ##########
lun="$1"
mountpoint="$2"

######## Pre-configurados ##########
#lun="lun1"
#mountpoint="/dados01"


disk="/dev/`ls -l /dev/disk/azure/scsi1/ | grep -w $lun | awk -F "/" '{ print $4 }'| head -n1`"
disksize=`parted $disk -s print | grep $disk | awk '{ print $3 }' | tr -d  'GB'`

function checaparam {
    echo -e "${txtred}Usage.....: azure_new_disk.bash < lunX > < mountfolder >${txtrst}(Caminho absoluto)"
    echo -e "${txtred}Usage.....: EX: azure_new_disk.bash lun1 /data01${txtrst}"
    exit
}
# Checa se os argumentos existem
if [[ $1 = "" ]] | [[ $2 = "" ]]; then
checaparam
fi

        if [ -d $mountpoint ] 
        then
                echo "Directory" $mountpoint "existe, escolha outro"
                exit
        fi

                if [ $disksize -ge "2048" ]
                then
                        mkdir $mountpoint
                        parted $disk --script mklabel gpt mkpart xfspart xfs 0% 100%
                        mkfs.xfs $disk'1' -f
                        partprobe $disk'1'
                        uuid=`blkid $disk'1' | awk '{ print $2}'`
                        echo -e "$uuid	\t	$mountpoint \t		xfs  defaults 0 0" | tee -a /etc/fstab
                        mount -a
                        df -H
                else
                        mkdir $mountpoint
                        (echo n; echo p; echo 1; echo ; echo ; echo w) | fdisk $disk
                        mkfs.xfs $disk'1' -f
                        partprobe $disk'1'
                        uuid=`blkid $disk'1' | awk '{ print $2}'`
                        echo -e "$uuid	\t	$mountpoint \t		xfs  defaults 0 0" | tee -a /etc/fstab
                        mount -a
                        df -H
                fi
       


