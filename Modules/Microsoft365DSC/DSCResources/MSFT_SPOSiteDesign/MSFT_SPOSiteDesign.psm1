function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Title,

        [Parameter()]
        [System.String[]]
        $SiteScriptNames,

        [Parameter()]
        [ValidateSet("CommunicationSite", "TeamSite")]
        [System.String]
        $WebTemplate,

        [Parameter()]
        [System.Boolean]
        $IsDefault,

        [Parameter()]
        [System.String]
        $PreviewImageAltText,

        [Parameter()]
        [System.String]
        $PreviewImageUrl,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.UInt32]
        $Version,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Write-Verbose -Message "Getting configuration for SPO SiteDesign for $Title"
    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $ConnectionMode = New-M365DSCConnection -Platform 'PNP' -InboundParameters $PSBoundParameters

    $nullReturn = @{
        Title                 = $Title
        SiteScriptNames       = $SiteScriptNames
        WebTemplate           = $WebTemplate
        IsDefault             = $IsDefault
        Description           = $Description
        PreviewImageAltText   = $PreviewImageAltText
        PreviewImageUrl       = $PreviewImageUrl
        Version               = $Version
        Ensure                = "Absent"
        GlobalAdminAccount    = $GlobalAdminAccount
        ApplicationId         = $ApplicationId
        TenantId              = $TenantId
        CertificatePassword   = $CertificatePassword
        CertificatePath       = $CertificatePath
        CertificateThumbprint = $CertificateThumbprint
    }

    Write-Verbose -Message "Getting Site Design for $Title"

    $siteDesign = Get-PnPSiteDesign -Identity $Title -ErrorAction SilentlyContinue
    if ($null -eq $siteDesign)
    {
        Write-Verbose -Message "No Site Design found for $Title"
        return $nullReturn
    }

    $scriptTitles = @()
    foreach ($scriptId in $siteDesign.SiteScriptIds)
    {
        $siteScript = Get-PnPSiteScript -Identity $scriptId -ErrorAction SilentlyContinue

        if ($null -ne $siteScript)
        {
            $scriptTitles += $siteScript.Title
        }
    }
    ## Todo need to see if we can get this somehow from PNP module instead of hard coded in script
    ## https://github.com/SharePoint/PnP-PowerShell/blob/master/Commands/Enums/SiteWebTemplate.cs
    $webtemp = $null
    if ($siteDesign.WebTemplate -eq "64")
    {
        $webtemp = "TeamSite"
    }
    else
    {
        $webtemp = "CommunicationSite"
    }

    return @{
        Title                 = $siteDesign.Title
        SiteScriptNames       = $scriptTitles
        WebTemplate           = $webtemp
        IsDefault             = $siteDesign.IsDefault
        Description           = $siteDesign.Description
        PreviewImageAltText   = $siteDesign.PreviewImageAltText
        PreviewImageUrl       = $siteDesign.PreviewImageUrl
        Version               = $siteDesign.Version
        Ensure                = "Present"
        GlobalAdminAccount    = $GlobalAdminAccount
        ApplicationId         = $ApplicationId
        TenantId              = $TenantId
        CertificatePassword   = $CertificatePassword
        CertificatePath       = $CertificatePath
        CertificateThumbprint = $CertificateThumbprint
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Title,

        [Parameter()]
        [ValidateSet("CommunicationSite", "TeamSite")]
        [System.String]
        $WebTemplate,

        [Parameter()]
        [System.String[]]
        $SiteScriptNames,

        [Parameter()]
        [System.Boolean]
        $IsDefault,

        [Parameter()]
        [System.String]
        $PreviewImageAltText,

        [Parameter()]
        [System.String]
        $PreviewImageUrl,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.UInt32]
        $Version,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Write-Verbose -Message "Setting configuration for SPO SiteDesign for $Title"
    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $ConnectionMode = New-M365DSCConnection -Platform 'PNP' -InboundParameters $PSBoundParameters

    $curSiteDesign = Get-TargetResource @PSBoundParameters

    # Get list of site script names
    $scriptIds = @()
    foreach ($siteScriptName in $SiteScriptNames)
    {
        $siteScript = Get-PnPSiteScript | Where-Object -FilterScript { $_.Title -eq $siteScriptName }
        $scriptIds += $siteScript.Id
    }

    $CurrentParameters = $PSBoundParameters
    $CurrentParameters.Remove("GlobalAdminAccount") | Out-Null
    $CurrentParameters.Remove("SiteScriptNames") | Out-Null
    $CurrentParameters.Remove("Ensure") | Out-Null
    $CurrentParameters.Remove("ApplicationId") | Out-Null
    $CurrentParameters.Remove("TenantId") | Out-Null
    $CurrentParameters.Remove("CertificatePath") | Out-Null
    $CurrentParameters.Remove("CertificatePassword") | Out-Null
    $CurrentParameters.Remove("CertificateThumbprint") | Out-Null
    $CurrentParameters.Add("SiteScriptIds", $scriptIds)

    if ($curSiteDesign.Ensure -eq "Absent" -and "Present" -eq $Ensure )
    {
        $CurrentParameters.Remove("Version")
        Write-Verbose -Message "Adding new site design $Title"
        Add-PnPSiteDesign @CurrentParameters
    }
    elseif (($curSiteDesign.Ensure -eq "Present" -and "Present" -eq $Ensure))
    {
        $siteDesign = Get-PnPSiteDesign -Identity $Title -ErrorAction SilentlyContinue
        if ($null -ne $siteDesign)
        {
            Write-Verbose -Message "Updating current site design $Title"
            Set-PnPSiteDesign -Identity $siteDesign.Id  @CurrentParameters
        }
    }
    elseif (($Ensure -eq "Absent" -and $curSiteDesign.Ensure -eq "Present"))
    {
        $siteDesign = Get-PnPSiteDesign -Identity $Title -ErrorAction SilentlyContinue
        if ($null -ne $siteDesign)
        {
            Write-Verbose -Message "Removing site design $Title"
            Remove-PnPSiteDesign -Identity $siteDesign.Id -Force
        }
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Title,

        [Parameter()]
        [ValidateSet("CommunicationSite", "TeamSite")]
        [System.String]
        $WebTemplate,

        [Parameter()]
        [System.String[]]
        $SiteScriptNames,

        [Parameter()]
        [System.Boolean]
        $isDefault,

        [Parameter()]
        [System.String]
        $PreviewImageAltText,

        [Parameter()]
        [System.String]
        $PreviewImageUrl,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.UInt32]
        $Version,

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Write-Verbose -Message "Testing configuration for SPO SiteDesign for $Title"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current Values: $(Convert-M365DscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-M365DscHashtableToString -Hashtable $PSBoundParameters)"

    $ValuesToCheck = $PSBoundParameters
    $ValuesToCheck.Remove('GlobalAdminAccount') | Out-Null
    $ValuesToCheck.Remove("ApplicationId") | Out-Null
    $ValuesToCheck.Remove("TenantId") | Out-Null
    $ValuesToCheck.Remove("CertificatePath") | Out-Null
    $ValuesToCheck.Remove("CertificatePassword") | Out-Null
    $ValuesToCheck.Remove("CertificateThumbprint") | Out-Null

    $TestResult = Test-Microsoft365DSCParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $ValuesToCheck.Keys

    Write-Verbose -Message "Test-TargetResource returned $TestResult"

    return $TestResult
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )
    $InformationPreference = 'Continue'
    #region Telemetry
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $MyInvocation.MyCommand.ModuleName)
    $data.Add("Method", $MyInvocation.MyCommand)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $ConnectionMode = New-M365DSCConnection -Platform 'PNP' -InboundParameters $PSBoundParameters

    $content = ''
    $i = 1

    [array]$designs = Get-PnPSiteDesign

    foreach ($design in $designs)
    {
        Write-Information "    [$i/$($designs.Length)] $($design.Title)"
        if ($ConnectionMode -eq 'Credential')
        {
            $params = @{
                GlobalAdminAccount = $GlobalAdminAccount
                Title              = $design.Title
            }
        }
        else
        {
            $params = @{
                Title                 = $design.Title
                ApplicationId         = $ApplicationId
                TenantId              = $TenantId
                CertificatePassword   = $CertificatePassword
                CertificatePath       = $CertificatePath
                CertificateThumbprint = $CertificateThumbprint
            }
        }

        if ($null -ne $TenantId)
        {
            $organization = $TenantId
            $principal = $TenantId.Split(".")[0]
        }

        $result = Get-TargetResource @params
        if ($ConnectionMode -eq 'Credential')
        {
            $result.GlobalAdminAccount = Resolve-Credentials -UserName "globaladmin"
        }
        $result = Remove-NullEntriesFromHashTable -Hash $result
        $content += "        SPOSiteDesign " + (New-GUID).ToString() + "`r`n"
        $content += "        {`r`n"
        $currentDSCBlock = Get-DSCBlock -Params $result -ModulePath $PSScriptRoot
        if ($ConnectionMode -eq 'Credential')
        {
            $content += Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "GlobalAdminAccount"
        }
        else
        {
            $content += $currentDSCBlock
            $content = Format-M365ServicePrincipalData -configContent $content -applicationid $ApplicationId `
                    -principal $principal -CertificateThumbprint $CertificateThumbprint
        }

        $content += "        }`r`n"
        $i++
    }
    return $content
}

Export-ModuleMember -Function *-TargetResource
