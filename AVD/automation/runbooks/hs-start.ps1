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
$azVMs = Get-AzureRMVM | Where-Object {$_.Tags.start_workday -eq '0700' -And $_.Tags.Application -eq 'WVD'}
try {
    ForEach ($VM in $azVMs) {
    Write-Output "Starting VM...: $($VM.Name)"
        Start-AzureRMVM -Name $VM.Name -ResourceGroupName $VM.ResourceGroupName
    Write-Output "$($VM.Name)..: Started Successfully. "
    }
}
catch {
    Write-Error -Message $_.Exception
    throw $_.Exception
}
