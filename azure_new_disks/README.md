# Provisionando discos de dados no Linux sem acessar a VM 

* Esse script auxilia na entrega de discos de dados, criação do ponto de montagem e configuração do /etc/fstab.
*  É necessário informar a lun onde o disco foi criado e anexado a maquina.
*  É necessário informar um ponto de montagem no formato de caminho absoluto no linux, como melhor prática sugiro o seguinte exemplo: /data00 para o disco atachado na lun0

### Antes da execução

* Consulte os discos de dados

```sh
az vm show -n oraclelinux -g RG-CLOUD --query storageProfile.dataDisks
```
```sh
Lun    Name        Caching    WriteAcceleratorEnabled    CreateOption    DiskSizeGb    ToBeDetached
-----  ----------  ---------  -------------------------  --------------  ------------  --------------
0      datadisk    None       False                      Attach          32            False
1      datadisk1   None       False                      Attach          3200          False
11     datadisk11  None       False                      Attach          32            False
```

* Nesse exemplo vamos apresentar o disco de 3.2TB atachado na LUN1, o script vai criar o ponto de montagem informado no segundo parametro arg2, Ex: /data01
* Garanta que não tenha nenhuma configuração previa no linux referente a esse disco, ex: fstab e o ponto de montagem

```sh
Invoke-AzVMRunCommand -ResourceGroupName RG-CLOUD -Name oraclelinux -CommandId 'RunShellScript' -ScriptPath 'azure_new_disks.bash' -Parameter @{"arg1" = "lun1";"arg2" = "/data01"}
```
