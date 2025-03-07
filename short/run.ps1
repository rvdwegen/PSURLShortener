using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$StatusCode = [HttpStatusCode]::OK

# account for multi-link creation
# filter for doubles before pushing to storage and returning data

try {
    $urlTableContext = New-TableContext -TableName 'shorturls'
} catch {
    throw $_.Exception.Message
}

try {
    if ($Request.body.slug) {
        $slug = $Request.body.slug
    } else {
        $slug = (("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ToCharArray() | Get-Random -Count 6) -Join ""
    }

    if (!$Request.body.url) {
        throw "no url lol"
    }
} catch {
    throw $_.Exception.Message
}

try {
    # Define the hashtable
    $result = @{
        PartitionKey = "URL"
        RowKey = $slug
        originalURL = $Request.body.url
        shortURL = "https://short.vdwegen.app/$slug"
        slug = $slug
        visitors = 0
    }

    $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($slug)'" -context $urlTableContext)

    if ($urlObject) {
        $StatusCode  = [HttpStatusCode]::BadRequest
    } else {
        #Add-AzDataTableEntity -Entity $result -context $urlTableContext

        Write-Host "Write directly to aztable"
        try {
            $result | fl
            #Push-OutputBinding -Name 'shorturls2' -Value $result

            Push-OutputBinding -Name TableBinding -Value @{
                PartitionKey = 'Test'
                RowKey = "1"
                Name = "Name 1"
            }
        } catch {
            throw $_.Exception.Message
        }

        $result.Remove('PartitionKey')
        $result.Remove('RowKey')
        $result.Remove('visitors')
    }

} catch {
    throw $_.Exception.Message
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body       = $result
})