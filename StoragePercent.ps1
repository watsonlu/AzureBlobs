#Make sure you set your execution policy

$SubscriptionName = "Visual Studio Enterprise"
$StorageAccountName = "lukesstorageaccount"
$Location = "North US"
$ContainerName = "mycontainer"
$imagePath = "C:\Users\luwat\Pictures\smirk.svg"
$ResourceGroup = "myresourcegrou"
$StorageKey = 0
$DirectoryToUpload = "C:\Users\luwat\Documents\Projects\Powershell\AzureBlobs\images"

#TODO: Do this programatically
#$account = Add-AzureAccount
#Set-AzureSubscription -SubscriptionName "Visual Studio Enterprise" -CurrentStorageAccountName $StorageAccountName
Login-AzureRmAccount
$account = Get-AzureRMStorageAccount -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroup
$key = (Get-AzureRMStorageAccountKey -ResourceGroup $ResourceGroup -StorageAccountName $StorageAccountName)[$StorageKey].value
$context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key


#Upload some garbage

Upload-TestBlobs -ContainerName $ContainerName -DirectoryToUpload $DirectoryToUpload

#Get-AzureStorageContainer -Name $ContainerName -Context ()
Get-AzureStorageBlob -Container $ContainerName -Context $context


function Upload-TestBlobs
{
    Param(
        [string]$ContainerName,
        [string]$DirectoryToUpload,
        [string]$Context
    )
    $images = Get-ChildItem $DirectoryToUpload
    foreach ($image in $images) {
        $BlobName = $image 
        $localFile = $image.FullName
        Set-AzureStorageBlobContent -File $localFile -Container $ContainerName -Blob $BlobName -Context $Context
    }

}
