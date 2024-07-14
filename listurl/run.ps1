using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$StatusCode = [HttpStatusCode]::OK

# account for multi-link creation
# filter for doubles before pushing to storage and returning data

try {
    Connect-AzAccount -Identity
    $urlTableContext = New-AzDataTableContext -TableName 'shorturls' -StorageAccountName 'stourlshort' -ManagedIdentity
} catch {
    throw $_.Exception.Message
}

try {

    $result = (Get-AzDataTableEntity -context $urlTableContext)

} catch {
    throw $_.Exception.Message
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body       = $result
})