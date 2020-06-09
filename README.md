# Learning Azure Storage REST APIs

## Prerequisites

### Software

- [Visual Studio Code](https://code.visualstudio.com/)
- [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client)

1. Copy [.env.sample.txt] and create a new file called `.env`.
2. Retrieve a [bearer token](https://docs.microsoft.com/rest/api/azure/#authorization-code-grant-interactive-clients) for your Azure account and paste the value in the `BEARER_TOKEN` environment variable.

    > **Note:** A bearer token can be retrieved through the REST API, the [Azure CLI](https://docs.microsoft.com/cli/azure/account?view=azure-cli-latest#az-account-get-access-token) or through [Azure PowerShell](https://gist.github.com/ciphertxt/1a7257f03cb04ad71b09e2415a3150eb).

    **PowerShell**

    ```powershell
    $tokenPoSh = ((New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient([Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile)).AcquireAccessToken((Gaz account get-access-tokenId)).AccessToken
    Write-Output $tokenPosh
    ```

    **Bash**

    ```sh
    tokenCLI=$(az account get-access-token --query "accessToken")
    echo $tokenCLI
    ```

3. Verify you can access your Azure subscription using the token by executing [getsubscriptions.http](getsubscriptions.http).
4. In the response, find the target `subscriptionId` and past the value into the `SUBSCRIPTION_ID` value in your `.env` file.
5. Populate the remaining values in your `.env` file, including:

    - **LOCATION** - Valid location name from [listlocations.http](listlocations.http)
    - **RESOURCE_GROUP_NAME** - Name for a new resource group that will be created with [createresourcegroup.http](createresourcegroup.http) or the name of an existing resource group
    - **STORAGE_ACCOUNT_NAME** - Name for a new storage account created with [createstorageaccount.http](createstorageaccount.http) or the name of an existing storage account
    - **CONTAINER_NAME** -  Name for a new container created with [createblobcontainer.http](createblobcontainer.http) or the name of an existing container

    > **Note:** If you have an existing resource group and storage account you can use those values or you can use the samples in this repository to create the resources

## Samples

- [Create a resource group](createresourcegroup.http)
- [Create a storage account](createstorageaccount.http)
  - [Create a blob container](createblobcontainer.http)
- [Get subscriptions](getsubscriptions.http)
- [List locations](listlocations.http)