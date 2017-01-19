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
    <#
        .Synopsis
            Prints out the contents of $AllBlobs in a pretty way
        .Example
            Print-BiggestBlobs -AllBlobs <ArrayOfBlobs> -StorageAccountName "mystorageaccountname" -ContainerName "mycontainername" -PercentageToPrint 5

            This prints out the blobs supplied in a nicely formatted way
    #>
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
    <#
        .Synopsis
            Gets the storage context from the supplied key and account name
        .Example
            Get-StorageContext -StorageAccountName "myaccountname" -StorageKey "qwewqek23k213k1233="

            This returns the storage context.
    #>
    Param(
        [string]$StorageAccountName,
        [string]$StorageKey
    )
    return New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageKey
}

function Get-StorageKey
{
    <#
        .Synopsis
            Get the storage key from the supplied account and Resource Group. By default it gets the first key from the account, but you can set the index to 1 to get the second key.
        .Example
            Get-StorageKey -IndexOfKeyToUse 0 -ResourceGroup "myresourcegroup" -StorageAccountName "myaccountname"

            This returns the storage key.
    #>
    Param(
        [int]$IndexOfKeyToUse,
        [string]$StorageAccountName,
        [string]$ResourceGroup
    )  
    return (Get-AzureRMStorageAccountKey -ResourceGroup $ResourceGroup -StorageAccountName $StorageAccountName)[$IndexOfKeyToUse].value
}

function Get-AuthenticatedWithAzure
{
    <#
        .Synopsis
            Checks to see if the session is logged in. If its not, a log in window appears to authenticate to Azure.

            If set AzureSubscription fails, the session needs to be authenticated and the window appears.

            If set AzureSubscription succeeds, we're already connected and do not need to authenticate again.

            Authentication is cached for a couple of hours, in an automated system we would need to implement a way to store the Azure credentials permanently.
            This should be done with a Config management tool like Chef (Secure Data-Bags), or by supplying secure environment variables using a tool like GoCD.

        .Example
            Get-AuthenticatedWithAzure -SubscriptionName "mysubname"

            This ensures that there is an authenticated connection with Azure.
    #>
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
    <#
        .Synopsis
            Returns the first X of elements in the supplied array, where X is the percentage supplied by $PercentageOf

        .Example
            Get-TopPercentageOfIndexes -array < array of objects > -PercentageOf 5

            This returns the first five percent of the supplied array.
    #>
    Param(
        [array]$array,
        [int]$PercentageOf
    )   
    return [math]::Ceiling(($PercentageOf * $array.Count) / 100)
}


function Upload-TestBlobs
{
    <#
        .Synopsis
            Uploads all the files in $DirectoryToUpload to $Container.

            Existing files are overwritten

        .Example
            Upload-TestBlobs -ContainerName "mycontainer" -DirectoryToUpload <Absolute Path to Folder"

            This uploads all files in the supplied directory.
    #>
    Param(
        [string]$ContainerName,
        [string]$DirectoryToUpload,
        [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext]$Context
    )
    foreach ($image in Get-ChildItem $DirectoryToUpload) {
        Set-AzureStorageBlobContent -File $image.FullName -Container $ContainerName -Blob $image.Name -Context $Context -Force
    }

}
