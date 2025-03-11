
$Deployment = @{
    Name              = "example.naming.subsScope"
    Location          = 'Westeurope'
    TemplateFile      = "$PSScriptRoot/main.bicep"
}
    
$deployment = New-AzSubscriptionDeployment @Deployment -Verbose

$deployment

Write-Host ($Deployment.outputs | ConvertTo-Json)
