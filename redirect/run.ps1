using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$Domain = ([uri]$Request.Headers.'x-ms-original-url').Host
$Slug = ([uri]$Request.Headers.'x-ms-original-url').Segments[1]

$urlTableContext = New-TableContext -TableName 'shorturls'

try {
    Write-Host "slug is $($slug)"
    $urlObject = (Get-AzDataTableEntity -Filter "slug eq '$($Slug)'" -context $urlTableContext)
    if ($urlObject) {

        $urlDomains = ConvertFrom-Json -InputObject $urlObject.domains
        $ExpiryDate = $urlObject.ExpiryDate

        Write-Host "$($slug) / $($Domain) / $ExpiryDate "


        if ($Domain -in $urlDomains -AND $ExpiryDate -gt (Get-Date)) {
            # Give a 302 response back
            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::Found
                Headers     = @{ Location = $urlObject.originalURL }
                Body        = ''
            })
    
            $count = $true
        } else {
            Write-Host "$($ExpiryDate)"
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
    }

    if ($ExpiryDate -lt (Get-Date)) {
        Write-Hoat "Deleting $($urlObject.RowKey) because the expiryDate is $($urlObject.ExpiryDate)"
        $urlObject | Remove-AzDataTableEntity
    }
} catch {
    throw "Error on line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
}

Write-Host "after output"
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