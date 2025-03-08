using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$Slug = ([uri]$Request.Headers.'x-ms-original-url').Segments[1]

$urlTableContext = New-TableContext -TableName 'shorturls'

try {
    $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($Slug)'" -context $urlTableContext)

    if ($urlObject) {
        # Give a 302 response back
        $httpResponse = [HttpResponseContext]@{
            StatusCode  = [HttpStatusCode]::Found
            Headers     = @{ Location = $urlObject.originalURL }
            Body        = ''
        }

        $count = $true
    } else {
        # Get the notfound HTML content
        $datapath = (Join-Path -Path (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\Resources")) -ChildPath "notfound2.html")
        $data = Get-Content -Path $datapath -Raw
        $data = $data.Replace('{slugVariable}',$($Slug))

        $httpResponse = [HttpResponseContext]@{
            StatusCode  = [HttpStatusCode]::OK
            Headers     = @{ 'content-type' = 'text/html' }
            Body        = $data
        }
    }
} catch {
    throw "Error on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value (
    $httpResponse
)

Write-Host "after output"
if ($count) {
    $visitsTableContext = New-TableContext -TableName 'visits'
    $visit = @{
        PartitionKey = $urlObject.RowKey
        RowKey = [string](New-Guid).Guid
        ClientIp = $request.headers.'client-ip'
        UserAgent = $request.headers.'user-agent'
        Platform = $request.headers.'sec-ch-ua-platform'
    }
    Add-AzDataTableEntity -Entity $visit -context $visitsTableContext

    # Increase visit count
    $urlObject.visitors++
    Update-AzDataTableEntity -Entity $urlObject -context $urlTableContext
}