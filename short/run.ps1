using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$StatusCode = [HttpStatusCode]::OK

if ($Request.Query.slug) {
    $slug = $Request.Query.slug
} else {
    $slug = (("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ToCharArray() | Get-Random -Count 4) -Join ""
}

$hosts = (Get-AzWebApp -Name vdwegen-urlshort).HostNames

$obj = [pscustomobject]@{
    originalURL = $Request.Query.URL
    shortURL = "https://short.vdwegen.app/$slug"
    description = $Request.Query.Description
    slug = $slug
}

# write obj to table

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body       = $obj
})