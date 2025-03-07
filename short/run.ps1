using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

if ($Request.body.slug) {
    $slug = $Request.body.slug
} else {
    $slug = (("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ToCharArray() | Get-Random -Count 6) -Join ""
}

try {
    try {
        $urlTableContext = New-TableContext -TableName 'shorturls'
    } catch {
        $StatusCode = [HttpStatusCode]::InternalServerError
        throw "Failed to create table context $($_.Exception.Message)"
    }

    $functions = @(
        'URLRedirect',
        'listurl',
        'short'
    )

    if ($Request.body.slug -in $functions) {
        $StatusCode = [HttpStatusCode]::BadRequest
        throw "slug is banned word"
    }

    if ($Request.body.slug.Count -lt 6) {
        $StatusCode = [HttpStatusCode]::BadRequest
        throw "not enough letters in the slug"
    }

    if (-Not $Request.body.url) {
        $StatusCode = [HttpStatusCode]::BadRequest
        throw "no url lol"
    }

    $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($slug)'" -context $urlTableContext)
    if ($urlObject) {
        $StatusCode  = [HttpStatusCode]::BadRequest
        throw "Slug already exists"
    }

    try {
        $result = @{
            PartitionKey = "URL"
            RowKey = $slug
            originalURL = $Request.body.url
            shortURL = "https://short.vdwegen.app/$slug"
            visitors = 0
        }
    
        Add-AzDataTableEntity -Entity $result -context $urlTableContext

        $result.Remove('PartitionKey')
        $result.Remove('RowKey')
        $result.Remove('visitors')
    } catch {
        $StatusCode = [HttpStatusCode]::InternalServerError
        throw "Failed to write to table: $($_.Exception.Message)"  
    }
} catch {
    $Result = $_.Exception.Message
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body       = $result
})