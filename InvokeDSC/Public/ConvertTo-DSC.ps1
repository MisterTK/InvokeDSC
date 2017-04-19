function ConvertTo-DSC {
<#
.SYNOPSIS
    Converts json DSL files to PSCustomObject
.DESCRIPTION
    Converts json DSL files to PSCustomObjects that Invoke-DSCResource can consume. All property
    objects will be converted to hashtables for the property cmdlet of Invoke-DSCResource. ModuleName
    is discovered dynamically  from the resource name provided in the json.
.EXAMPLE
    ConvertTo-DSC -Path 'c:\json\example.json'
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    begin {
        $data = Get-Content -Path $path | ConvertFrom-Json
        $alldscObj = @()
    }

    process {
         foreach ($dscResource in $data.DSCResourcesToExecute) {

            $dscObj = New-Object psobject

            $resource = Get-DscResource -Name $dscResource.dscResourceName

            $module = $resource.ModuleName

            if ($dscResource.dscResourceName -eq 'file') {
                $module = 'PSDesiredStateConfiguration'
            }

            $Config = @{
            Name = ($dscResource.dscResourceName)
                Property = @{
                }
            }

            $configkeys = ($dscResource.psobject.Properties -notmatch '(dsc)?ResourceName')

            foreach ($configKey in $configKeys) {

                $prop = $resource.Properties | Where-Object {$_.Name -eq $configKey.Name}

                if ($ConfigKey.Value -is [array]) {

                    foreach ($key in $ConfigKey.Value) {

                        if ($key.psobject.Properties['CimType']) {
                            #Create new CIM object
                            $cimhash = @{}

                            $key.Properties.psobject.Properties | ForEach-Object {
                                $cimhash[$_.Name] = $_.Value
                            }

                            if ($prop.PropertyType -match '\[\w+\[\]\]') {
                                [ciminstance[]]$value += New-CimInstance -ClassName $key.CimType -Property $cimhash -ClientOnly
                            } else {
                                [ciminstance]$value = New-CimInstance -ClassName $key.CimType -Property $cimhash -ClientOnly
                            }
                        } else {
                            $value = $configKey.Value
                        }
                    }

                    $config.Property.Add($configKey.Name,$value)
                    $value = $null

                } else {
                    $config.Property.Add($configKey.Name,$configKey.Value)
                }
            }

            $dscObj | Add-Member -MemberType NoteProperty -Name resourceName -Value $dscResource.resourceName
            $dscObj | Add-Member -MemberType NoteProperty -Name dscResourceName -Value $dscResource.dscResourceName
            $dscObj | Add-Member -MemberType NoteProperty -Name ModuleName -Value $module
            $dscObj | Add-Member -MemberType NoteProperty -Name Property -Value $Config.Property

            $alldscObj += $dscObj

        }
    }

    end {
        return $alldscObj
    }
}

#$test = ConvertTo-DSC -Path $PSScriptRoot\..\..\examples\AppProvisioning.json