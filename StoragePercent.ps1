#Make sure you set your execution policy

$SubscriptionName = "Visual Studio Enterprise"
$StorageAccountName = "lukesstorageaccount"
$Location = "North US"
$ContainerName = "mycontainer"
$ResourceGroup = "myresourcegrou"
$StorageKey = 0
$DirectoryToUpload = $PSScriptRoot
$PercentageToPrint = 5
$UploadTestBlobs = $FALSE

Get-AuthenticatedWithAzure -SubscriptionName $SubscriptionName

$StorageKey = Get-StorageKey -IndexOfKeyToUse $StorageKey -StorageAccountName $StorageAccountName -ResourceGroup $ResourceGroup
$context = Get-StorageContext -StorageAccountName $StorageAccountName -StorageKey $StorageKey
if ($UploadTestBlobs -eq $TRUE)
{
    Upload-TestBlobs -ContainerName $ContainerName -DirectoryToUpload $DirectoryToUpload -Context $context
}
$AllBlobs = Get-AzureStorageBlob -Container $ContainerName -Context $context | sort Length -Descending
$TopIndexes = Get-TopPercentageOfIndexes -array $AllBlobs -PercentageOf $PercentageToPrint
$TopBlobs = ($AllBlobs | Select-Object -First $TopIndexes)
Print-BiggestBlobs -AllBlobs $TopBlobs -StorageAccountName $StorageAccountName -ContainerName $ContainerName -PercentageToPrint $PercentageToPrint

function Print-BiggestBlobs
{
    Param(
        [array]$AllBlobs,
        [string]$StorageAccountName,
        [string]$ContainerName,
        [int]$PercentageToPrint
    )
    Write-Host "Top $PercentageToPrint% of Blobs in '$StorageAccountName' in Container '$ContainerName' by size."
    $AllBlobs | Format-Table -Property Name, @{Name="Size (KBs)";Expression={[math]::Ceiling($_.Length / 1Kb)}}
}

function Get-StorageContext
{
    Param(
        [string]$StorageAccountName,
        [string]$StorageKey
    )
    return New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageKey
}

function Get-StorageKey
{
    Param(
        [int]$IndexOfKeyToUse,
        [string]$StorageAccountName,
        [string]$ResourceGroup
    )  
    return (Get-AzureRMStorageAccountKey -ResourceGroup $ResourceGroup -StorageAccountName $StorageAccountName)[$IndexOfKeyToUse].value
}

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
        Set-AzureStorageBlobContent -File $image.FullName -Container $ContainerName -Blob $image.Name -Context $Context -Force
    }

}
