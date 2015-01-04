﻿Set-StrictMode -Version 2

function Clear-CFDNSZoneFileCache
{
    [OutputType([PSCustomObject])]
    [CMDLetBinding()]
    param
    (
        [Parameter(mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $APIToken,

        [Parameter(mandatory = $true)]
        [ValidateScript({
                    $_.contains('@')
                }
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $Email,

        [Parameter(mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Zone,

        [Parameter(mandatory = $true,
                   valuefrompipeline = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]
        $URL
    )

    begin
    {
        # Cloudflare API URI
        $CloudFlareAPIURL = 'https://www.cloudflare.com/api_json.html'

        # Build up the request parameters
        $APIParameters = New-Object  -TypeName System.Collections.Specialized.NameValueCollection
        $APIParameters.Add('tkn', $APIToken)
        $APIParameters.Add('email', $Email)
        $APIParameters.Add('a', 'zone_file_purge')
        $APIParameters.Add('z', $Zone)
        $APIParameters.Add('url', '') 

        # Create the webclient and set encoding to UTF8
        $webclient = New-Object  -TypeName Net.WebClient
        $webclient.Encoding = [System.Text.Encoding]::UTF8
    }

    Process
    {
        $APIParameters['url'] = $URL

        # Post the API command
        $WebRequest = $webclient.UploadValues($CloudFlareAPIURL, 'POST', $APIParameters)

        #convert the result from UTF8 and then convert from JSON
        $JSONResult = ConvertFrom-Json -InputObject ([System.Text.Encoding]::UTF8.GetString($WebRequest))
    
        #if the cloud flare api has returned and is reporting an error, then throw an error up
        if ($JSONResult.result -eq 'error') 
        {
            throw $($JSONResult.msg)
        }
    
        $JSONResult.response
    }
}
