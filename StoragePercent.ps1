#Make sure you set your execution policy

$SubscriptionName = "Visual Studio Enterprise"
$StorageAccountName = "lukesstorageaccount"
$Location = "North US"
$ContainerName = "mycontainer"
$imagePath = "C:\Users\luwat\Pictures\smirk.svg"
$ResourceGroup = "myresourcegrou"
$StorageKey = 0

#TODO: Do this programatically
#$account = Add-AzureAccount
#Set-AzureSubscription -SubscriptionName "Visual Studio Enterprise" -CurrentStorageAccountName $StorageAccountName
Login-AzureRmAccount
$account = Get-AzureRMStorageAccount -StorageAccountName $StorageAccountName -ResourceGroupName $ResourceGroup
$key = (Get-AzureRMStorageAccountKey -ResourceGroup $ResourceGroup -StorageAccountName $StorageAccountName)[$StorageKey].value
$context = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $key


#Upload some garbage

$BlobName = "smirk.svg" 
$localFile = $imagePath
#Set-AzureStorageBlobContent -File $localFile -Container $ContainerName -Blob $BlobName -Context $context

#Get-AzureStorageContainer -Name $ContainerName -Context ()
Get-AzureStorageBlob -Container $ContainerName -Context $context


#New-AzureStorageAccount –StorageAccountName $StorageAccountName