function Receive-HttpTrigger {
    Param($Request, $TriggerMetadata)

    Set-Location (Get-Item $PSScriptRoot).Parent.Parent.FullName
    Write-Host (Get-Item $PSScriptRoot).Parent.Parent.FullName

    $FunctionName = 'Invoke-URLRedirect'

    $HttpTrigger = @{
        Request         = $Request
        TriggerMetadata = $TriggerMetadata
    }
    Write-Host "here in http1"
    try {
        & $FunctionName @HttpTrigger
        Write-Host "here in http2"
    } catch {
        throw "Failed to execute URL redirect: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @('Receive-HttpTrigger')