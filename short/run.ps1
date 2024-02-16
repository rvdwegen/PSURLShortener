using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$StatusCode = [HttpStatusCode]::OK

$slug = (("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ToCharArray() | Get-Random -Count 8) -Join ""

$hosts = (Get-AzWebApp -Name vdwegen-urlshort).HostNames

$obj = [pscustomobject]@{
    originalURL = $Request.Query.
    shortURL = "https://short.vdwegen.app/$slug"
    description = ""
    slug = if ($customSlug) { $customSlug } else { $slug }
}

# write obj to table

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body       = $obj
})