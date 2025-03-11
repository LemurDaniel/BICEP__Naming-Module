
try {
    $resourceGroup = 'module.bicep-naming.examples'

    $Deployment = @{
        Name              = "example.naming.errors"
        ResourceGroupName = $resourceGroup
        TemplateFile      = "$PSScriptRoot/main.bicep"
    }
    
    $deployment = New-AzResourceGroupDeployment @Deployment -Confirm:$false -Force -Verbose

    $deployment

    Write-Host ($Deployment.outputs | ConvertTo-Json)
}
catch {
    $_
}