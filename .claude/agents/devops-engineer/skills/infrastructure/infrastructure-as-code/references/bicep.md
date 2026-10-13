# Azure Bicep Reference

Bicep compiles to ARM JSON but is authored in a much terser DSL; use it over raw ARM templates for any new Azure IaC.

## Structure

```bicep
param environment string
param location string = resourceGroup().location

@allowed(['dev', 'staging', 'prod'])
param env string

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: 'vnet-${env}'
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
    subnets: [
      { name: 'app', properties: { addressPrefix: '10.0.1.0/24' } }
    ]
  }
}

output vnetId string = vnet.id
```

## Modules

```bicep
module network 'modules/network.bicep' = {
  name: 'networkDeploy'
  params: {
    env: env
    location: location
  }
}
```

Module files are plain `.bicep` files referenced by relative path (or a registry reference for shared modules across repos) — no separate packaging step needed, unlike Terraform's provider/module registry model.

## Scopes

Bicep deployments target a scope explicitly: `resourceGroup`, `subscription`, `managementGroup`, or `tenant`. Match the scope to what the template provisions — a template creating resource groups themselves must deploy at `subscription` scope, not `resourceGroup`.

## What-If

```bash
az deployment group what-if --resource-group rg-prod --template-file main.bicep --parameters env=prod
```

Bicep/ARM's equivalent of `terraform plan` — always run before `az deployment group create` against a shared environment, and read the Create/Modify/Delete breakdown the same way you'd read a Terraform plan's diff.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Hand-writing ARM JSON for new work | Author in Bicep, let the compiler produce ARM |
| Deploying without `what-if` first | Always run `what-if` against shared environments |
| Wrong deployment scope for what's being created | Match scope (`resourceGroup`/`subscription`/etc.) to the resources declared |
