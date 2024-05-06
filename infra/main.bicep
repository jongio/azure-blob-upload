targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

param resourceGroupName string = ''

var abbrs = loadJsonContent('./abbreviations.json')

var tags = {
  'azd-env-name': environmentName
}

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

module asp 'core/host/appserviceplan.bicep' = {
  scope: rg
  name: 'asp'
  params: {
    name: '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'S1'
      tier: 'Standard'
      size: 'S1'
    }
  }
}

module app 'core/host/appservice.bicep' = {
  scope: rg
  name: 'app'
  params: {
    name: '${abbrs.webSitesAppService}${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'app' })
    appServicePlanId: asp.outputs.id
    runtimeName: 'dotnetcore'
    runtimeVersion: '8.0'
    managedIdentity: true
    appSettings: {
      AZURE_STORAGE_ENDPOINT: storage.outputs.primaryEndpoints.blob
    }
  }
}

module storage 'core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
    containers: [
      {
        name: 'uploads'
        publicAccess: 'blob'
      }
    ]
  }
}

module userRole 'core/security/role.bicep' = {
  name: 'user-role'
  scope: rg
  params: {
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalType: 'User'
    principalId: principalId
  }
}

module appRole 'core/security/role.bicep' = {
  name: 'app-role'
  scope: rg
  params: {
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalType: 'ServicePrincipal'
    principalId: app.outputs.identityPrincipalId
  }
}

output AZURE_LOCATION string = location
output AZURE_STORAGE_ENDPOINT string = storage.outputs.primaryEndpoints.blob
output AZURE_TENANT_ID string = tenant().tenantId
