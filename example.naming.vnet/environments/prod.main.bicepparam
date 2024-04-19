using '../main.bicep'

param environment = 'prod'

param virtualNetwork = {
  name: 'demo'
  addressPrefix: [
    '10.0.0.0/16'
  ]
  subnets: [
    '10.0.0.0/28'
    '10.0.0.16/28'
    '10.0.0.32/28'
  ]
}
