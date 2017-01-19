#requires -version 5.0
#requires –runasadministrator
Param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionName,
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    [Parameter(Mandatory=$true)]
    [string]$ContainerName,
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,
    [string]$DirectoryToUpload = $PSScriptRoot,
    [int]$PercentageToPrint = 5,
    [boolean]$UploadTestBlobs = $FALSE,
    [int]$StorageKeyIndex = 0    
)


function Show-Output
{
    <#
        .Synopsis
            Prints out the contents of $AllBlobs in a pretty way
        .Example
            Show-Output -AllBlobs <ArrayOfBlobs> -StorageAccountName "mystorageaccountname" -ContainerName "mycontainername" -PercentageToPrint 5

            This prints out the blobs supplied in a nicely formatted way
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [array]$TopBlobs,
        [Parameter(Mandatory=$true)]
        [array]$AllBlobs,
        [Parameter(Mandatory=$true)]
        [string]$StorageAccountName,
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [int]$PercentageToPrint
    )
    Write-Output "Top $PercentageToPrint% of Blobs in '$StorageAccountName' in Container '$ContainerName' by size."
    Write-Output "Total Blobs: $($AllBlobs.Count)"
    $TopBlobs | Format-Table -Property Name, @{Name="Size (KBs)";Expression={[math]::Ceiling($_.Length / 1Kb)}}
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
        [Parameter(Mandatory=$true)]
        [string]$StorageAccountName,
        [Parameter(Mandatory=$true)]
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
        [Parameter(Mandatory=$true)]
        [int]$IndexOfKeyToUse,
        [Parameter(Mandatory=$true)]
        [string]$StorageAccountName,
        [Parameter(Mandatory=$true)]
        [string]$ResourceGroup
    )  

    $key = (Get-AzureRMStorageAccountKey -ResourceGroup $ResourceGroup -StorageAccountName $StorageAccountName)[$IndexOfKeyToUse].value
    return $key
}

function Get-AuthenticatedWithAzure
{
    <#
        .Synopsis
            Checks to see if there is an available AzureRMProfile. If there isn't, it opens a log in window.

            If the user successfully logs in, a profile is created on the disk that contains the session so they don't have to keep logging in.

            This profile eventually expires, so it will need to be updated.

            This can be automated properly using a configuration management tool like Chef (Secure Data Bags would do this for us).

        .Example
            Get-AuthenticatedWithAzure -SubscriptionName "mysubname"

            This ensures that there is an authenticated connection with Azure.
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [string]$SubscriptionName
    )
    $ProfilePath = "$PSScriptRoot\profile.txt"
    if ((Test-Path $ProfilePath) -eq $TRUE)
    {
        Select-AzureRmProfile -Path $ProfilePath
    }
    else
    {
        Add-AzureRmAccount
        Save-AzureRmProfile -Path $ProfilePath 
    }
}


function Get-PercentageOfElementsInArray
{
    <#
        .Synopsis
            Returns the first X of elements in the supplied array, where X is the percentage supplied by $PercentageOf

        .Example
            Get-PercentageOfElementsInArray -array < array of objects > -PercentageOf 5

            This returns the first five percent of the supplied array.
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [array]$array,
        [Parameter(Mandatory=$true)]
        [int]$PercentageOf
    )   
    return [math]::Ceiling(($PercentageOf * $array.Length + 1) / 100)
}


function Add-TestData
{
    <#
        .Synopsis
            Uploads all the files in $DirectoryToUpload to $Container.

            Existing files are overwritten

        .Example
            Add-TestData -ContainerName "mycontainer" -DirectoryToUpload <Absolute Path to Folder"

            This uploads all files in the supplied directory.
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [string]$DirectoryToUpload,
        [Parameter(Mandatory=$true)]
        [Microsoft.WindowsAzure.Commands.Common.Storage.AzureStorageContext]$Context
    )
    

    foreach ($image in Get-ChildItem $DirectoryToUpload) {
        $image
        Set-AzureStorageBlobContent -File $image.FullName -Container $ContainerName -Blob $image.Name -Context $Context -Force
    }

}

    #Make sure you set your execution policy
    Install-Module AzureRM
  
    Get-AuthenticatedWithAzure -SubscriptionName $SubscriptionName

    $StorageKey = Get-StorageKey -IndexOfKeyToUse $StorageKeyIndex -StorageAccountName $StorageAccountName -ResourceGroup $ResourceGroup
    $context = Get-StorageContext -StorageAccountName $StorageAccountName -StorageKey $StorageKey
    if ($UploadTestBlobs -eq $TRUE)
    {
        Add-TestData -ContainerName $ContainerName -DirectoryToUpload $DirectoryToUpload -Context $context
    }
    $AllBlobs = Get-AzureStorageBlob -Container $ContainerName -Context $context | Sort-Object Length -Descending
    $TopIndexes = Get-PercentageOfElementsInArray -array $AllBlobs -PercentageOf $PercentageToPrint
    $TopBlobs = ($AllBlobs | Select-Object -First $TopIndexes)
    Show-Output -TopBlobs $TopBlobs -AllBlobs $AllBlobs -StorageAccountName $StorageAccountName -ContainerName $ContainerName -PercentageToPrint $PercentageToPrint

