using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Define parameters from $Request
$Domain = ([uri]$Request.Headers.'x-ms-original-url').Host
$Slug = ([uri]$Request.Headers.'x-ms-original-url').Segments[1]

Write-Host "$($Domain) / $($Slug)"

# Create table context
$urlTableContext = New-TableContext -TableName 'shorturls'

try {
    # Check if the slug exists
    $urlObject = (Get-AzDataTableEntity -Filter "slug eq '$($Slug)'" -context $urlTableContext)
    if ($urlObject) {
        Write-Host "Found $($urlObject.Count) slugs"

        # Convert the domains cell to an object
        $urlDomains = ConvertFrom-Json -InputObject $urlObject.domains

        # Define the ExpiryDate if its filled
        $ExpiryDate = $urlObject.ExpiryDate

        # Check if the incoming slug and incoming domain matches the domains on the registered slug and if the slug hasn't expired
        if ($Domain -in $urlDomains -AND ($ExpiryDate -gt (Get-Date) -OR $ExpiryDate -eq $null)) {
            # Give a 302 response back
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::Found
                Headers     = @{ Location = $urlObject.originalURL }
                Body        = ''
            })
    
            # We're redirecting so set $count to true so the visit is counted
            $count = $true
        } else {
            # Get the notfound HTML content
            $datapath = (Join-Path -Path (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\Resources")) -ChildPath "notfound2.html")
            $data = Get-Content -Path $datapath -Raw
            $data = $data.Replace('{slugVariable}',$($Slug))
    
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::OK
                Headers     = @{ 'content-type' = 'text/html' }
                Body        = $data
            })
        }
    } else {
        # temp
        # Get the notfound HTML content
        $datapath = (Join-Path -Path (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\Resources")) -ChildPath "notfound2.html")
        $data = Get-Content -Path $datapath -Raw
        $data = $data.Replace('{slugVariable}',$($Slug))

        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode  = [HttpStatusCode]::OK
            Headers     = @{ 'content-type' = 'text/html' }
            Body        = $data
        })
    }

    # If the ExpiryDate is filled and its expired, remove the slug
    # Probably remove the visits too?
    # Or possibly just disable?
    if ($ExpiryDate -AND $ExpiryDate -lt (Get-Date)) {
        Write-Host "Deleting $($urlObject.RowKey) because the expiryDate is $($urlObject.ExpiryDate)"
        $urlObject | Remove-AzDataTableEntity -Context $urlTableContext
    }
} catch {
    throw "Error on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
}

if ($count) {
    Write-Host "$($Request.Headers.'X-Forwarded-For') | $($request.headers.'client-ip')"

    $visitsTableContext = New-TableContext -TableName 'visits'
    $visit = @{
        PartitionKey = $urlObject.RowKey
        RowKey = [string](New-Guid).Guid
        ClientIp = (($Request.Headers.'X-Forwarded-For').Split(',')[0].Trim() -split ':')[0] #$request.headers.'client-ip'
        UserAgent = $request.headers.'user-agent'
        Platform = $request.headers.'sec-ch-ua-platform'.Trim('"')
        Referer = $Request.headers.referer
        Raw = [string]($Request | ConvertTo-Json -Compress -Depth 20)
        #Raw = [string]($Request.Headers | ConvertTo-Json -Compress -Depth 20)
    }
    Add-AzDataTableEntity -Entity $visit -context $visitsTableContext

    # Increase visit count
    $urlObject.visitors++
    Update-AzDataTableEntity -Entity $urlObject -context $urlTableContext
}