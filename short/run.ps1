using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$StatusCode = [HttpStatusCode]::OK

if ($Request.Query.slug) {
    $slug = $Request.Query.slug
} else {
    $slug = (("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ToCharArray() | Get-Random -Count 4) -Join ""
}

# account for multi-link creation
# filter for doubles before pushing to storage and returning data

try {
    Connect-AzAccount -Identity
    $urlTableContext = New-AzDataTableContext -TableName 'shorturls' -StorageAccountName 'stourlshort' -ManagedIdentity
} catch {
    throw $_.Exception.Message
}

try {
    $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($slug)'" -context $urlTableContext)

    if ($urlObject) {
        $StatusCode  = [HttpStatusCode]::BadRequest
    } else {
        $result = @{
            PartitionKey = "URL"
            RowKey = $slug
            originalURL = $Request.Query.URL
            shortURL = "https://short.vdwegen.app/$slug"
            slug = $slug
            counter = 0
        }

        Add-AzDataTableEntity -Entity $obj -context $urlTableContext

        $result.Remove('PartitionKey')
        $result.Remove('RowKey')
    }

} catch {
    throw $_.Exception.Message
}

# write obj to table

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body       = $result
})