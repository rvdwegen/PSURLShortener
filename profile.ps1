# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution
 
# Import modules
@('Az.Accounts','AzBobbyTables') | ForEach-Object {
    try {
        Import-Module -Name $_ -ErrorAction Stop
    } catch {
        Write-LogMessage -message "Failed to import module $($_): $_.Exception.Message" -Sev 'debug'
        $_.Exception.Message
    }
}

$ProgressPreference = 'SilentlyContinue'

try {
    Disable-AzContextAutosave -Scope Process | Out-Null
}
catch {}

# Uncomment the next line to enable legacy AzureRm alias in Azure PowerShell.
# Enable-AzureRmAlias

# You can also define functions or aliases that can be referenced in any of your PowerShell functions.