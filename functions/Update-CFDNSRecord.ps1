﻿Set-StrictMode -Version 2

function Update-CFDNSRecord 
{
    <# 
        .SYNOPSIS
        Creates specificed DNS entry in CloudFlare.

        .DESCRIPTION
        Creates the specified DNS Record within the specified DNZ Zone that is hosted within CloudFlare's infrastructure. You must specify your API Token and your Email addresses along with the Zone (full qualified).

        .PARAMETER APIToken
        This is your API Token from the CloudFlare WebPage (look under user settings).

        .PARAMETER Email
        Your email address you signed up to CloudFlare with.

        .PARAMETER Zone
        The zone you want to add this new record to. For example, poshsecurity.com.

        .PARAMETER Name
        The record you want to add. For example, www.poshsecurity.com. Use '@' to specify the root of the domain.

        .PARAMETER Content
        The content for the record, this would be an IP address for an A record, or another hostname for a CNAME, or Text for a TXT record. For MX or SRV this is your "target"

        .PARAMETER Type
        What type of record? Almost everything is supported here, including: A, CNAME, MX, TXT, SPF, AAAA, NS, SRV, LOC

        .PARAMETER EnableCloudFlare
        Status of CloudFlare Proxy, 1 = orange cloud, 0 = grey cloud. !!!! Currently doesn't function correctly !!! API accepts this, however ignores the setting.

        .PARAMETER TTL
        Time to live for this DNS record, defaults to 1 which is automatic.

        .PARAMETER Priority
        Required for MX and SRV records.

        .PARAMETER Service
        Required for SRV records. An example of a Service would be _sip.

        .PARAMETER Protocol
        Required for SRV records. Valid options are _tcp, _udp and _tls

        .PARAMETER Weight
        Required for SRV records. Weighting of the record.

        .PARAMETER Port
        Required for SRV records. Service port number.

        .INPUTS
        This takes no input from the pipeline

        .OUTPUTS
        System.Management.Automation.PSCustomObject containing the record information returned form the CloudFlare API.

        .EXAMPLE
        New-CFDNSRecord -APIToken '<My Token> -Email 'user@domain.com' -Zone 'domain.com' -Name 'www' -Content '123.123.123.123' -Type A
        Creates A record pointing www.domain.com to the ip address 123.123.123.123

        .EXAMPLE
        New-CFDNSRecord -APIToken '<My Token> -Email 'user@domain.com' -Zone 'domain.com' -Name 'mail' -Content 'mailserver.domain.com' -Type CNAME
        Creates a CNAME record directing mail.domain.com to mailserver.domain.com

        .EXAMPLE
        New-CFDNSRecord -APIToken '<My Token> -Email 'user@domain.com' -Zone 'domain.com' -Name '@' -Content 'mailserver.domain.com' -Type MX -Priority 10
        Creates a MX record definine mailserver.domain.com as a mail server for domain.com

        .EXAMPLE
        New-CFDNSRecord -APIToken '<My Token> -Email 'user@domain.com' -Zone 'domain.com' -Name '@' -Content 'sipdir.online.lync.com' -Type SRV -Priority 100 -Service '_sip' -Protocol _tls -Weight 1 -Port 443 -Verbose
        Creates a SRV record, this is a typical Office365 example. The full address created is _sip._tls.domain.com which points to sipdir.online.lync.com, with priority 100 and weight 1. This specifies protocol is tls and port is 443.

        .NOTES
        NAME: 
        AUTHOR: Kieran Jacobsen - Posh Security - http://poshsecurity.com
        LASTEDIT: 1/1/2015
        KEYWORDS: DNS, CloudFlare, Posh Security

        .LINK
        http://poshsecurity.com

        .LINK 
        http://https://github.com/poshsecurity/Posh-CloudFlare

    #>

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

        [Parameter(mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ID,

        [Parameter(mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Content,
   
        [Parameter(mandatory = $false)]
        [switch]
        $EnableCloudFlare,

        [Parameter(mandatory = $false)]
        [ValidateScript({
                    ($_ -eq 1) -or (($_ -ge 120) -and ($_ -le 86400))
                }
        )]
        [int]
        $TTL = 1,
        
        #"prio"[applies to MX/SRV] MX record priority.
        [Parameter(mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Priority,

        #"service"[applies to SRV] Service for SRV record
        [Parameter(mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Service,

        #"protocol"[applies to SRV] Protocol for SRV record. Values include: [_tcp/_udp/_tls].
        [Parameter(mandatory = $false)]
        [ValidateSet('_tcp', '_udp', '_tls')]
        [string]
        $Protocol,

        #"weight"[applies to SRV] Weight for SRV record.
        [Parameter(mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Weight,

        #"port"[applies to SRV] Port for SRV record
        [Parameter(mandatory = $false)]
        [ValidateRange(1, [UInt16]::MaxValue)]
        [UInt16]$Port

    )
    
    # Cloudflare API URI
    $CloudFlareAPIURL = 'https://www.cloudflare.com/api_json.html'

    # Build up the request parameters, we need API Token, email, command, dnz zone, dns record type, dns record name and content, and finally the TTL.
    $APIParameters = New-Object  -TypeName System.Collections.Specialized.NameValueCollection
    $APIParameters.Add('tkn', $APIToken)
    $APIParameters.Add('email', $Email)
    $APIParameters.Add('a', 'rec_edit')
    $APIParameters.Add('z', $Zone)
    $APIParameters.Add('id', $ID)
    $APIParameters.Add('name', $Name)
    $APIParameters.Add('content', $Content)
    $APIParameters.Add('ttl', $TTL)
    $APIParameters.Add('type', 'CNAME')
    
    #$APIParameters.Add('prio', $Priority)

    #$APIParameters.Add('service', $Service)
    #$APIParameters.Add('srvname', $Name)
    #$APIParameters.Add('protocol', $Protocol)
    #$APIParameters.Add('weight', $Weight)
    #$APIParameters.Add('port', $Port)
    #$APIParameters.Add('target', $Content)


    Write-Verbose -Message 'Determining service status'
    if ($EnableCloudFlare)
    {
        Write-Verbose -Message 'enabling service'
        $APIParameters.Add('service_mode', 1)
    }
    else
    {
        Write-Verbose -Message 'disabling service'
        $APIParameters.Add('service_mode', 0)
    }
        
    # Create the webclient and set encoding to UTF8
    $WebClient = New-Object  -TypeName Net.WebClient
    $WebClient.Encoding = [System.Text.Encoding]::UTF8

    # Post the API command
    $WebRequest = $WebClient.UploadValues($CloudFlareAPIURL, 'POST', $APIParameters)

    #convert the result from UTF8 and then convert from JSON
    $JSONResult = ConvertFrom-Json -InputObject ([System.Text.Encoding]::UTF8.GetString($WebRequest))
    
    #if the cloud flare api has returned and is reporting an error, then throw an error up
    if ($JSONResult.result -eq 'error') 
    {
        throw $($JSONResult.msg)
    }

    $JSONResult.response.rec.obj
}