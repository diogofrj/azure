# Azure Fix Taxonomy 

* O Script pode ser utilizado para correção de taxonomia dos recursos de uma VM no Azure.
*  The Script can be used to correct taxonomy of a VM's resources in Azure.

### Antes da execução

* Linha 23: Insira o id da sua subscription / Enter your subscription id

```sh
subscription="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # SUBSCRIPTION
az account set -s $subscription
```

* Essas são as variaveis da VM nas linhas 26 e 27 que devem ser modificadas antes da execução do script
* These are the VM variables on lines 26 and 27 that must be modified before running the script

```sh
############ VARIAVEIS PRINCIPAIS ###################
vmsource="VM-CENTOS7"               # NOME DA VM ANTIGA
newvm="VM-RHEL"                     # NOME DA VM NOVA
############ -------------------- ###################