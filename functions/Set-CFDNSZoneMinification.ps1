﻿Set-StrictMode -Version 2

function Set-CFDNSZoneMinification
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

        [Parameter(mandatory = $false)]
        [switch]
        $JavaScript,

        [Parameter(mandatory = $false)]
        [switch]
        $CSS,

        [Parameter(mandatory = $false)]
        [switch]
        $HTML,

        [Parameter(mandatory = $false)]
        [ValidateRange(0,7)]
        [int]
        $MinifyInteger

    )

    # Cloudflare API URI
    $CloudFlareAPIURL = 'https://www.cloudflare.com/api_json.html'

    # Build up the request parameters
    $APIParameters = New-Object  -TypeName System.Collections.Specialized.NameValueCollection
    $APIParameters.Add('tkn', $APIToken)
    $APIParameters.Add('email', $Email)
    $APIParameters.Add('a', 'minify')
    $APIParameters.Add('z', $Zone)

    if ($MinifyInteger -ne $null)
    {

        $minify = 0

        if ($JavaScript)
        {
            $minify = $minify + 1
        } 

        if ($CSS)
        {
            $minify = $minify + 2
        } 

        if ($HTML)
        {
            $minify = $minify + 4
        } 
    
        $APIParameters.Add('v', $minify)
    }
    else
    {
        $APIParameters.Add('v', $minifyinteger)
    }

    # Create the webclient and set encoding to UTF8
    $webclient = New-Object  -TypeName Net.WebClient
    $webclient.Encoding = [System.Text.Encoding]::UTF8

    # Post the API command
    $WebRequest = $webclient.UploadValues($CloudFlareAPIURL, 'POST', $APIParameters)

    #convert the result from UTF8 and then convert from JSON
    $JSONResult = ConvertFrom-Json -InputObject ([System.Text.Encoding]::UTF8.GetString($WebRequest))
    
    #if the cloud flare api has returned and is reporting an error, then throw an error up
    if ($JSONResult.result -eq 'error') 
    {
        throw $($JSONResult.msg)
    }
    
    $JSONResult.result
}
