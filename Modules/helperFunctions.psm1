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
    
    #$randomSlug = (("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ToCharArray() | Get-Random -Count 8) -Join ""
    
    try {
        Connect-AzAccount -Identity
    } catch {
        $_.Exception.Message
        $ErrorMessage = $_.Exception.Message
        $StatusCode = [HttpStatusCode]::Unauthorized
    }

    $urlTableContext = New-AzDataTableContext -TableName 'shorturls' -StorageAccountName 'stourlshort' -ManagedIdentity

    $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($Request.Params.URLslug)'" -context $urlTableContext)
    if (!$urlObject) {
        $urlObject = [PSCustomObject]@{
            url = "https://microsoft.com"
        }
    }

    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode  = [HttpStatusCode]::Found
        Headers     = @{ Location = $urlObject.url }
        Body        = ''
    })

}

Export-ModuleMember -Function @('Receive-HttpTrigger', 'Invoke-URLRedirect')