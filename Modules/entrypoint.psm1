function Receive-HttpTrigger {
    Param($Request, $TriggerMetadata)

    Set-Location (Get-Item $PSScriptRoot).Parent.Parent.FullName
    Write-Host (Get-Item $PSScriptRoot).Parent.Parent.FullName

    $FunctionName = 'Invoke-URLRedirect'

    $HttpTrigger = @{
        Request         = $Request
        TriggerMetadata = $TriggerMetadata
    }

    try {
        & $FunctionName @HttpTrigger
    } catch {
        throw "Failed to execute URL redirect: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @('Receive-HttpTrigger')