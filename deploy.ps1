[CmdletBinding()]
param(
  # Optional. When not provided, the tenant is selected interactively.
  [string] $TenantId,
  # Optional. When not provided, the subscription is selected interactively.
  [string] $SubscriptionId
)

$resourceGroup = 'module.bicep-naming.examples'
$location = 'Westeurope'

function Select-FromList {
  param(
    [Parameter(Mandatory)] [string] $Title,
    [Parameter(Mandatory)] [array] $Items,
    [Parameter(Mandatory)] [scriptblock] $Label
  )

  if ($Items.Count -eq 1) {
    return $Items[0]
  }

  Write-Host -ForegroundColor Yellow $Title
  for ($i = 0; $i -lt $Items.Count; $i++) {
    Write-Host ("  [{0}] {1}" -f ($i + 1), (& $Label $Items[$i]))
  }

  do {
    $choice = Read-Host -Prompt "Select [1-$($Items.Count)]"
  } until ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $Items.Count)

  return $Items[[int]$choice - 1]
}

# Login, when there is no active Azure context.
if (-not (Get-AzContext)) {
  Connect-AzAccount | Out-Null
}

# Select Tenant
if (-not $TenantId) {
  $tenants = @(Get-AzTenant)
  $TenantId = (Select-FromList -Title 'Select Tenant' -Items $tenants -Label { param($t) "$($t.Name) ($($t.Id))" }).Id
}

# Select Subscription
if (-not $SubscriptionId) {
  $subscriptions = @(Get-AzSubscription -TenantId $TenantId -WarningAction SilentlyContinue | Where-Object State -eq 'Enabled')

  # Tenants with conditional access (MFA) require an explicit login, the cached token is not sufficient.
  if ($subscriptions.Count -eq 0) {
    Write-Host -ForegroundColor Yellow "No token for tenant $TenantId. Logging in (MFA may be required)..."
    Connect-AzAccount -TenantId $TenantId -ErrorAction Stop | Out-Null
    $subscriptions = @(Get-AzSubscription -TenantId $TenantId | Where-Object State -eq 'Enabled')
  }

  if ($subscriptions.Count -eq 0) {
    throw "No enabled subscriptions found in tenant $TenantId."
  }
  $SubscriptionId = (Select-FromList -Title 'Select Subscription' -Items $subscriptions -Label { param($s) "$($s.Name) ($($s.Id))" }).Id
}

$context = Set-AzContext -TenantId $TenantId -SubscriptionId $SubscriptionId -ErrorAction Stop
Write-Host -ForegroundColor Green "Using subscription '$($context.Subscription.Name)' in tenant '$($context.Tenant.Id)'"

try {


  New-AzResourceGroup -Name $resourceGroup -Location $location -Force -Confirm:$false

  Write-Host -ForegroundColor Yellow "Example 1"
  .\examples\example.naming.001\deploy.ps1

  Write-Host
  Write-Host
  Write-Host
  Read-Host -Prompt "Continue?"



  Write-Host -ForegroundColor Yellow "Example Errors"
  .\examples\example.naming.errors\deploy.ps1

  Write-Host
  Write-Host
  Write-Host
  Read-Host -Prompt "Continue?"



  Write-Host -ForegroundColor Yellow "Example Subscription Scope"
  .\examples\example.naming.subsScope\deploy.ps1

  Write-Host
  Write-Host
  Write-Host
  Read-Host -Prompt "Continue?"
}
finally {
  Remove-AzResourceGroup -Name $resourceGroup -Force -Confirm:$false
}
