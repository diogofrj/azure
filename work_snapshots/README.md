# Trabalhando com Snapshots

- Scripts para auxiliar no trabalho de criação de snapshots em VMs do Azure.
- Opcão de gerar somente o snapshot do disco do S.O ou todos os discos de s.o/dados existentes de uma VM.
- Opção de exportar o Snapshot para um Storage Blob no formato VHD.

## Pre-requisitos



* AzCopy 

* Powershell 5.1

  

# Script: `gera_snapshot.ps1`



## Como Usar

* Altere a variável  **$VMName** com o nome da VM.
* Caso deseje gerar os snapshots também dos discos de dados, altere o valor da variavel **$snapdatadisks** para 1

* Caso deseje salvar os snapshots em um blob, altere o valor da variavel **$savetoblob** para 1 e escolha uma um Storage Account e um Container validos para as variáveis **$storageAccountName** e **$storageContainerName**

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
