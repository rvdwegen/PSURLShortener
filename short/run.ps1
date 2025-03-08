using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

try {
    try {
        $urlTableContext = New-TableContext -TableName 'shorturls'
    } catch {
        $StatusCode = [HttpStatusCode]::InternalServerError
        throw "Failed to create table context $($_.Exception.Message)"
    }

    switch ($Request.Method) {
        'POST' {
            if ($Request.body.slug) {
                $slug = $Request.body.slug
            } else {
                $slug = (("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ToCharArray() | Get-Random -Count 6) -Join ""
            }
    
            $functions = @(
                'list',
                'login',
                'logout'
            )
        
            if ($slug -in $functions) {
                $StatusCode = [HttpStatusCode]::BadRequest
                throw "slug $($Slug) is banned word"
            }
        
            if ($slug.Length -lt 6) {
                $StatusCode = [HttpStatusCode]::BadRequest
                throw "not enough letters in the slug $($Slug)"
            }
        
            if (-Not $Request.body.url) {
                $StatusCode = [HttpStatusCode]::BadRequest
                throw "no url lol"
            }

            $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($slug)'" -context $urlTableContext)
            if ($urlObject) {
                $StatusCode  = [HttpStatusCode]::BadRequest
                throw "Slug $($Slug) already exists"
            }

            try {
                $result = @{
                    PartitionKey = "URL"
                    RowKey = $slug
                    originalURL = $Request.body.url
                    shortURL = "https://short.vdwegen.app/$slug" # don't hardcode the url
                    visitors = 0
                }
            
                Add-AzDataTableEntity -Entity $result -context $urlTableContext
                $StatusCode = [HttpStatusCode]::OK
                $result.Remove('PartitionKey')
                $result.Remove('RowKey')
                $result.Remove('visitors')
            } catch {
                $StatusCode = [HttpStatusCode]::InternalServerError
                throw "Failed to write to table: $($_.Exception.Message)"  
            }
        }
        'PATCH' {
    
        }
        'DELETE' {
            Write-Host "link is $($Request.Headers.'x-ms-original-url')"
            $Slug = ([uri]$Request.Headers.'x-ms-original-url').Segments[3]

            $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($slug)'" -context $urlTableContext)
            $urlObject | Remove-AzDataTableEntity -context $urlTableContext
        }
        Default {}
    }
} catch {
    $Result = @{ message = $($_.Exception.Message) }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body       = $result
})