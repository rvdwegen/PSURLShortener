using namespace System.Net

function Receive-HttpTrigger {
    Param($Request, $TriggerMetadata)

    Set-Location (Get-Item $PSScriptRoot).Parent.Parent.FullName
    Write-Host (Get-Item $PSScriptRoot).Parent.Parent.FullName
    $APIName = $TriggerMetadata.FunctionName

    $FunctionName = 'Invoke-{0}' -f $APIName

    $HttpTrigger = @{
        Request         = $Request
        TriggerMetadata = $TriggerMetadata
    }

    & $FunctionName @HttpTrigger
}

function Invoke-URLRedirect {
    # Input bindings are passed in via param block.
    param($Request, $TriggerMetadata)
    
    try {
        Connect-AzAccount -Identity
        $urlTableContext = New-AzDataTableContext -TableName 'shorturls' -StorageAccountName 'stourlshort' -ManagedIdentity
    } catch {
        throw $_.Exception.Message
    }

    try {
        $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($Request.Params.URLslug)'" -context $urlTableContext)

        if ($urlObject) {
            $httpReply = [HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::Found
                Headers     = @{ Location = $urlObject.url }
                Body        = ''
            }
        } else {
            $httpReply = [HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::OK
                Headers     = @{'content-type' = 'text/html'}
                Body        = "<html><body>$($Request.Params.URLslug) was not found refer is: $($request.headers.Referer)</body></html>"
            }
        }

    } catch {
        $_.Exception.Message
        # $urlObject = [PSCustomObject]@{
        #     url = "https://microsoft.com"
        # }
    }

    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value (
        $httpReply
    )

}

Export-ModuleMember -Function @('Receive-HttpTrigger', 'Invoke-URLRedirect')