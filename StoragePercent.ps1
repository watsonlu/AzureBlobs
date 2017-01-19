#Make sure you set your execution policy

$SubscriptionName = "Visual Studio Enterprise"
$StorageAccountName = "lukesstorageaccount"
$Location = "North US"
$ContainerName = "mycontainer"
$imagePath = "C:\Users\luwat\Pictures\smirk.svg"
$ResourceGroup = "myresourcegrou"
$StorageKey = 0
$DirectoryToUpload = "C:\Users\luwat\Documents\Projects\Powershell\AzureBlobs\images"



Get-AuthenticatedWithAzure -SubscriptionName $SubscriptionName
$key = (Get-AzureRMStorageAccountKey -ResourceGroup $ResourceGroup -StorageAccountName $StorageAccountName)[$StorageKey].value
$context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key


#Upload some garbage

Upload-TestBlobs -ContainerName $ContainerName -DirectoryToUpload $DirectoryToUpload -Context $context
$blobs = Get-AzureStorageBlob -Container $ContainerName -Context $context | sort Length -Descending
$TopIndexes = Get-TopPercentageOfIndexes -array $blobs -PercentageOf 5
$blobs | Select-Object -First $TopIndexes

function Get-AuthenticatedWithAzure
{
    Param(
        [string]$SubscriptionName
    )  
    Try
    {
        Set-AzureSubscription -SubscriptionName $SubscriptionName
    }
    Catch{
        Add-AzureRmAccount
        Set-AzureSubscription -SubscriptionName $SubscriptionName
    }
}


function Get-TopPercentageOfIndexes
{
    Param(
        [array]$array,
        [int]$PercentageOf
    )   
    return [math]::Ceiling(($PercentageOf * $array.Count) / 100)
}


function Upload-TestBlobs
{
    Param(
        [string]$ContainerName,
        [string]$DirectoryToUpload,
        [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext]$Context
    )
    foreach ($image in Get-ChildItem $DirectoryToUpload) {
        #Set-AzureStorageBlobContent -File $image.FullName -Container $ContainerName -Blob $image.Name -Context $Context -Force
    }

}
