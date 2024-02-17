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


$response = Invoke-WebRequest -Uri $Request.Query.URL
$title = $response.ParsedHtml.title
$description = $response.ParsedHtml.getElementsByTagName('meta') | Where-Object { $_.name -eq 'description' } | Select-Object -ExpandProperty content

Write-Host "Title: $title"
Write-Host "Description: $description"

$obj = [pscustomobject]@{
    PartitionKey = "URL"
    RowKey = $slug
    originalURL = $Request.Query.URL
    shortURL = "https://short.vdwegen.app/$slug"
    title = $title
    description = $description
    slug = $slug
    counter = 0
}

# write obj to table

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body       = $obj
})