
param applicationName string = uniqueString(resourceGroup().id)
param location string = resourceGroup().location


var cosmosAccountName = toLower('hgCosmosAccountName01')

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-04-15'={
    name: cosmosAccountName
    location: location
    kind:  'GlobalDocumentDB'
    properties: {
        consistencyPolicy:{
          defaultConsistencyLevel: 'Session'
        }
        locations: [
          {
             locationName: location
             failoverPriority: 0
             isZoneRedundant: false
          }
        ]
        databaseAccountOfferType: 'Standard'   
    }
}

param appServciePlanTier string = 'S1'
param appServicePlanName string = toLower('${applicationName}-ASP')

@minValue(1)
@maxValue(3)
@description('App Service Plan\'s instance count')
param appServicePlanInstance int = 1

resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-01' = {
  name: appServicePlanName
  location: location  
  sku:{
     name: appServciePlanTier 
      capacity: appServicePlanInstance
  }
  kind: 'linux'
}

resource appService 'Microsoft.Web/sites@2021-01-01' = {
   name: applicationName
    location: location
     properties: {
        serverFarmId: appServicePlan.id
         httpsOnly: true
          siteConfig: {
            http20Enabled: true
            appSettings: [
              {
                 name: 'CosmosDb:Account'
                 value: cosmosAccount.properties.documentEndpoint
              }
              {
                name: 'CosmosDb:Key'
                value: listKeys(cosmosAccount.id, cosmosAccount.apiVersion).primaryMasterKey
              }
              {
                name: 'CosmosDb:DatabaseName'
                value:'Tasks'
              }
              {
                name: 'CosmosDb:ContainerName'
                value: 'Item'
              }
            ]
          }
     }
}

@description('Github repo URL of ToDo List ')
param repositoryUri string = 'https://github.com/Azure-Samples/cosmos-dotnet-core-todo-app.git'

resource srcControls 'Microsoft.Web/sites/sourcecontrols@2021-01-01' ={
   name: '${appService.name}/web'
   properties:{
      repoUrl: repositoryUri
      branch: 'main'
      isManualIntegration: true
  }  
}

