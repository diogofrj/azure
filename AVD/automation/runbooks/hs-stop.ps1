# Authenticate using ServicePrincipal RunAs Account and logging in
$ConnectionName = "AzureRunAsConnection"
try {
    # Get the connection "AzureRunAsConnection "
    $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName      
    Write-Output "Logging in to Azure..."
    $account = Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $ServicePrincipalConnection.TenantId `
        -ApplicationId $ServicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$ServicePrincipalConnection) {
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}
Write-Output $account
Write-Output "Running Filter WVD Tags..."
$azVMs = Get-AzureRMVM | Where-Object {$_.Tags.stop_workday -eq '1900' -And $_.Tags.Application -eq 'WVD'}
try {
    ForEach ($VM in $azVMs) {
    Write-Output "Stoping VMs...: $($VM.Name)"
        Stop-AzureRMVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName -Force
        Write-Output "$($VM.Name)..: Deallocated Successfully. "
    }
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}
