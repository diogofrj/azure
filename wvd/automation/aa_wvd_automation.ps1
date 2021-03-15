#####   FILENAME:           aa_wvd_automation.ps1
#####   VERSION:            1.0
#####   DESCRIPTION:        Gerenciamento de Custos e automação WVD: Cria um Automation Account + Runbook + Scripts START/STOP + Schedule + WebHook(START/STOP ON_DEMAND)
#####   CREATION DATE:      13/03/2021
#####   WRITTEN BY:         Diogo Fernandes
#####   E-MAIL:             dfernandes@4mstech.com
#####   DISTRIBUTION:       N/A
#####                       Invoke-ScriptAnalyzer -Path .\aa-wvd-automation.ps1 -ReportSummary -Fix
#####   REFERENCE:          https://docs.microsoft.com/en-us/azure/virtual-desktop/set-up-scaling-script

[string]$SubscriptionName = 'Sub (diogolab.com)'
[string]$Location = "East US 2"
[string]$ResourceGroupName = "RG_WVD_AUTOMATION"
[string]$AutomationAccountName = "aa-wvd-automation"
[string]$RunAsAccountName = "AzureRunAsConnection"
[string]$StartVMsRunbookName = "hs-start"
[string]$StopVMsRunbookName = "hs-stop"
[string]$StartVMsScheduleName = "ScheduledStartVMs"
[string]$StopVMsScheduleName = "ScheduledStopVMs"
[string]$StartTime = "07:00:00"
[string]$StopTime = "19:00:00"
[string]$TimeZoneId = "America/Sao_Paulo" #IANA Format
[System.DayOfWeek[]]$WeekDays = @([System.DayOfWeek]::Monday..[System.DayOfWeek]::Friday)
$tags = @{
    "Application" = "WVD"
}
Set-AzContext -Name $SubscriptionName -Subscription $SubscriptionName -Force

$RG = $(Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue)
if ($null -eq $RG) {
    Write-Host -ForegroundColor Cyan "Creating Resource Group"
    New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tags $tags
}
#
$AA = $(Get-AzAutomationAccount -Name $AutomationAccountName -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue)
if ($null -eq $AA) {
    Write-Host -ForegroundColor Cyan "Creating Automation account"
    New-AzAutomationAccount -Name $AutomationAccountName -Location $Location -ResourceGroupName $ResourceGroupName -Tags $tags
    Start-Sleep 10
    Write-Host -ForegroundColor Cyan "Deleting Tutorial Runbooks"
    (Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName | where-object {$_.Name -like "*Tutorial*"}) | Remove-AzAutomationRunbook -Force
}
# Ensure that the Run As Account exists:
$AutomationConnection = Get-AzAutomationConnection `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -Name $RunAsAccountName `
    -ErrorAction SilentlyContinue
if (!$AutomationConnection) {
    Write-Host -ForegroundColor Red "Could not find Automation Connection: $($RunAsAccountName). You must create a Run As Account before using this Automation Account."
    exit
}
Write-Host -ForegroundColor Cyan "Deploying runbooks..."
#
$AllRunbookFileNames = Get-ChildItem "runbooks" | ForEach-Object { $_.Name }
foreach ($RunbookFileName in $AllRunbookFileNames) {
    Write-Host -ForegroundColor Cyan "Importing $RunbookFileName"
    $RunbookName = $RunbookFileName.Replace(".ps1", "")

    Import-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName -Path "runbooks/$RunbookFileName" -Type PowerShell -Force
    Publish-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Name $RunbookName
}
Write-Host -ForegroundColor Green "Deploying runbooks Completed."

Write-Host -ForegroundColor Cyan "Deploying schedules..."

# Create or update the start schedule
$StartTime = (Get-Date $StartTime).AddDays(1)
New-AzAutomationSchedule `
    -AutomationAccountName $AutomationAccountName `
    -ResourceGroupName $ResourceGroupName `
    -Name $StartVMsScheduleName `
    -StartTime $StartTime `
    -DaysOfWeek $WeekDays `
    -WeekInterval 1 `
    -Description "Agendamento de Start das VMs" `
    -TimeZone $TimeZoneId

# Create or update the stop schedule
$StopTime = (Get-Date $StopTime).AddDays(1)
New-AzAutomationSchedule `
    -AutomationAccountName $AutomationAccountName `
    -Name $StopVMsScheduleName `
    -ResourceGroupName $ResourceGroupName `
    -StartTime $StopTime `
    -DaysOfWeek $WeekDays `
    -WeekInterval 1 `
    -Description "Agendamento de Stop das VMs" `
    -TimeZone $TimeZoneId

#$RunbookParams = @{"VmNames" = $VmNames; "ResourceGroupName" = $VmsResourceGroupName }

# if a job schedule for the specified runbook and schedule already exists, remove it first.
$StartVMsScheduledRunbook = Get-AzAutomationScheduledRunbook `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -RunbookName $StartVMsRunbookName
if ($StartVMsScheduledRunbook) {
    Unregister-AzAutomationScheduledRunbook `
        -JobScheduleId $StartVMsScheduledRunbook.JobScheduleId `
        -ResourceGroupName $ResourceGroupName `
        -AutomationAccountName $AutomationAccountName `
        -Force
}
# register start vms
Write-Host -ForegroundColor Cyan "Registering Schedules..."
Register-AzAutomationScheduledRunbook -AutomationAccountName $AutomationAccountName -RunbookName $StartVMsRunbookName -ScheduleName $StartVMsScheduleName -ResourceGroupName $ResourceGroupName
#
$StopVMsScheduledRunbook = Get-AzAutomationScheduledRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -RunbookName $StopVMsRunbookName
if ($StopVMsScheduledRunbook) {
    Unregister-AzAutomationScheduledRunbook -JobScheduleId $StopVMsScheduledRunbook.JobScheduleId -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Force
}
# register stop vms
Register-AzAutomationScheduledRunbook -AutomationAccountName $AutomationAccountName -RunbookName $StopVMsRunbookName -ScheduleName $StopVMsScheduleName -ResourceGroupName $ResourceGroupName
#
(Get-AzAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName | where-object {$_.Name -like "*Tutorial*"}) | Remove-AzAutomationRunbook -Force
Write-Host -ForegroundColor Green "Deploying schedules Completed"
#
$CHECK_STARTHOOK = (Get-AzAutomationWebhook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName | where-object { $_.RunbookName -like "*start*" })
if ($null -eq $CHECK_STARTHOOK) {
    Write-Output "Deploying WebHook..."
    $STARTHOOK = New-AzAutomationWebhook -Name $StartVMsRunbookName-webhook -RunbookName $StartVMsRunbookName -IsEnabled $true -ExpiryTime (Get-Date).AddYears(1) -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Force
    Write-Output "ATENTION....: Save info about Start Webhook"
    Write-Host -ForegroundColor Cyan "Name..............:" $STARTHOOK.Name
    Write-Host -ForegroundColor Cyan "ExpiryTime........:" $STARTHOOK.ExpiryTime
    Write-Host -ForegroundColor Cyan "WebhookURI........:" $STARTHOOK.WebhookURI "`n"
}
$CHECK_STOPHOOK = (Get-AzAutomationWebhook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName | where-object { $_.RunbookName -like "*stop*" })
if ($null -eq $CHECK_STOPHOOK) {
    $STOPHOOK = New-AzAutomationWebhook -Name $StopVMsRunbookName-webhook -RunbookName $StopVMsRunbookName -IsEnabled $true -ExpiryTime (Get-Date).AddYears(1) -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Force
    Write-Output "ATENTION....: Save info about Stop Webhook"
    Write-Host -ForegroundColor Blue "Name..............:" $STOPHOOK.Name
    Write-Host -ForegroundColor Blue "ExpiryTime........:" $STOPHOOK.ExpiryTime
    Write-Host -ForegroundColor Blue "WebhookURI........:" $STOPHOOK.WebhookURI "`n"

    Write-Host -ForegroundColor Green "Deploying Webhooks Completed.`n"

    Write-Output "HOW TO USE via POWERSHELL....:"
    Write-Host -ForegroundColor Yellow "Ex. START....: Invoke-WebRequest -Method Post -Uri" $STARTHOOK.WebhookURI
    Write-Host -ForegroundColor Yellow "Ex. STOP.....: Invoke-WebRequest -Method Post -Uri" $STOPHOOK.WebhookURI
}
# Optional
# (Remove-AzAutomationWebhook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName | where-object {$_.RunbookName -like "*start*"})
# (Remove-AzAutomationWebhook -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName | where-object {$_.RunbookName -like "*stop*"})
