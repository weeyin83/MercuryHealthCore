# This IaC script provisions and configures the web stite hosted in azure
# storage, the back end function and the cosmos db
#
[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipal,

    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipalSecret,

    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipalTenantId,

    [Parameter(Mandatory = $True)]
    [string]
    $azureSubscriptionName,

    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupName,

    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupNameRegion,

    [Parameter(Mandatory = $True)]  
    [string]
    $serverName,

    [Parameter(Mandatory = $True)]  
    [string]
    $dbLocation,

    [Parameter(Mandatory = $True)]  
    [string]
    $adminLogin,

    [Parameter(Mandatory = $True)]  
    [string]
    $adminPassword,
    
    [Parameter(Mandatory = $True)]  
    [string]
    $startip,

    [Parameter(Mandatory = $True)]  
    [string]
    $endip,

    [Parameter(Mandatory = $True)]  
    [string]
    $dbName,

    [Parameter(Mandatory = $True)]  
    [string]
    $webAppName,

    [Parameter(Mandatory = $True)]  
    [string]
    $environment
)


#region Login
# This logs in a service principal
#
Write-Output "Logging in to Azure with a service principal..."
az login `
    --service-principal `
    --username $servicePrincipal `
    --password $servicePrincipalSecret `
    --tenant $servicePrincipalTenantId
Write-Output "Done"
Write-Output ""

# This sets the subscription to the subscription I need all my apps to
# run in
#
Write-Output "Setting default azure subscription..."
az account set `
    --subscription $azureSubscriptionName
Write-Output "Done"
Write-Output ""
#endregion



    #region Create Resource Group
    # # This creates the resource group used to house all of Mercury Health
    # #
    Write-Output "Creating resource group $resourceGroupName in region $resourceGroupNameRegion..."
    az group create `
        --name $resourceGroupName `
        --location $resourceGroupNameRegion
    Write-Output "Done creating resource group"
    Write-Output ""
    #endregion


    #region Create Sql Server and database
    # Create a logical sql server in the resource group
    # 
    Write-Output "Creating sql server..."
    try {
        az sql server create `
        --name $serverName `
        --resource-group $resourceGroupName `
        --location $dbLocation  `
        --admin-user $adminLogin `
        --admin-password $adminPassword
    }
    catch {
        Write-Output "SQL Server already exists"
    }
    Write-Output "Done creating sql server"
    Write-Output ""

    # Configure a firewall rule for the server
    #
    Write-Output "Creating firewall rule for sql server..."
    try {
        az sql server firewall-rule create `
        --resource-group $resourceGroupName `
        --server $serverName `
        -n AllowYourIp `
        --start-ip-address $startip `
        --end-ip-address $endip 
    }
    catch {
        Write-Output "firewall rule already exists"
    }
    Write-Output "Done creating firewall rule for sql server"
    Write-Output ""

    # Create a database in the server with zone redundancy as false
    #
    Write-Output "Create sql db $dbName..."
    try {
        az sql db create `
        --resource-group $resourceGroupName `
        --server $serverName `
        --name $dbName `
        --edition GeneralPurpose `
        --family Gen4 `
        --zone-redundant false `
        --capacity 1
    }
    catch {
        Write-Output "sql db already exists"
    }
    Write-Output "Done creating sql db"
    Write-Output ""
    #endregion
