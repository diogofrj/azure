# Habilitando a aceleração de rede em uma VM Azure

* Esse script testa todos os Sizes que suportam rede acelerada 

## Antes da execução

* Para habilitar a rede acelerada é preciso que a VM esteja em modo Deallocated.

## Como usar o script

```sh
./acelera_nic.bash VM02
```
```sh
SIZE ( Standard_DS14_v2 ) COMPATIVEL PARA ACELERAÇÃO DE REDE
IMPORTANTE: A VM SERÁ DESLIGADA PARA ATUALIZAÇÃO DA NIC, DESEJA CONTINUAR?

1) Yes
2) No
#? 1
Desligando VM....................: VM02
Habilitando Aceleração na Nic....: vm0272
EnableAcceleratedNetworking    EnableIpForwarding    Location    MacAddress         Name    Primary    ProvisioningState    ResourceGroup    ResourceGuid
-----------------------------  --------------------  ----------  -----------------  ------  ---------  -------------------  ---------------  ------------------------------------
True                           False                 eastus2     00-0D-3A-DF-F9-F5  vm0272  True       Succeeded            VM01_GROUP       1c16d84c-d7da-4a61-ae96-d470556d45f2
Ligando a VM.....................: VM02
```

* Nesse exemplo o script testou o parametro "enableAcceleratedNetworking" da nic vm0272 como "false", quando a rede ja esta acelerada o script apenas informa e finaliza.
* Se o Size é incompativel é apenas finalizado informando o nome do size:

```sh
./acelera_nic.bash VM01
```

```sh
SIZE NAO COMPATIVEL: ( Standard_E2s_v3 ) 
```
