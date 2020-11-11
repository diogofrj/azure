# Trabalhando com Snapshots



### Casos de Uso.

Imagine que você precise fazer uma atividade programada em uma VM de produção, o primeiro passo é assegurar que se algo errado aconteça você consiga voltar a VM para seu estado inicial.

Sendo assim vamos utilizar 2 scripts, o primeiro ira gerar o Snapshot do disco do sistema operacional e o segundo desligará a VM e fará a troca com um novo disco criado a partir do Snapshot.



## Pre-requisitos

- AzCopy
- Powershell 5.1

# Script: `gera_snapshot.ps1`

## Como Usar

- Altere a variável **$VMName** com o nome da VM.
- Caso deseje gerar os snapshots também dos discos de dados, altere o valor da variavel **$snapdatadisks** para 1
- Caso deseje salvar os snapshots em um blob, altere o valor da variavel **$savetoblob** para 1 e escolha uma um Storage Account e um Container validos para as variáveis **$storageAccountName** e **$storageContainerName**

```
$VMName = "<VM_NAME>"
$savetoblob = 0         #-Deseja exportar o Snapshot para um blob? SIM = 1 e NÃO = 0
$snapdatadisks = 0      #-Deseja gerar o Snapshots dos DataDisks ? SIM = 1 e NÃO = 0
$storageAccountName = "<STORAGE ACCOUNT>"
$storageContainerName = "<CONTAINER>"
```

> ```
> (Get-AzSnapshot -SnapshotName "SNAP-$VMName*").Name
> SNAP-vmwindows-Datadisk0-11Nov2020-09H52M
> SNAP-vmwindows-Datadisk1-11Nov2020-09H52M
> SNAP-vmwindows-OSDisk-11Nov2020-09H52M
> ```





# Script: `swap_osdisk_from_snapshot.ps1`



## Como Usar

- Altere a variável **$VMName** com o nome da VM.
- Escolha o tamanho do disco, altere o valor da variável **$diskSize**
- Escolha o SKU do disco, altere o valor da variável **$storageType**. Ex: Standard_LRS, StandardSSD_LRS ou Premium_LRS

```
$VMName = "<VM_NAME>"
$diskSize = '128'
$storageType = 'Standard_LRS'   

```

* Variáveis interativas
  - Será listado os snapshots disponíveis e pedido para escolher.
  - Será pedido o nome do novo disco.

```
.\swap_osdisk_from_snapshot.ps1
Listando os SnapShots existentes...
SNAP-vmwindows-OSDisk-11Nov2020-20H14M
Please enter Snapshot Name............: SNAP-vmwindows-OSDisk-11Nov2020-20H14M
Please enter OSDiskName............: vmwindows-OSDisk
```

* Em seguida a VM será desligada, a troca do disco será feita e a VM será ligada novamente em seu estado inicial.

