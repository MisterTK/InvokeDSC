function Get-ModuleFromConfiguration {
<#
.SYNOPSIS
    Gathers module names from a specified json configuration file.
.DESCRIPTION
    Parses a json configuration file and extracts the module names.
    Duplicate module names will be removed outputting only unqiue module names.
.PARAMETER Path
    Specifies the path to the configuration file(s) to parse.
.PARAMETER Recurse
    Indicates that this cmdlet gets the items in the specified locations and in all child items of the locations.
.PARAMETER InputObject
    Specifies an InputObject containing json synatx
.EXAMPLE
    Get-ModuleFromConfiguration -Path c:\Configs\NewFile.json
.EXAMPLE
    Get-ModuleFromConfiguration -Path c:\Configs\ -Recurse
.EXAMPLE
    Get-ModuleFromConfiguration -InputObject $json-object
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'Path', Position = 0)]
        [string]$Path,[switch]$Recurse,
        [Parameter(Mandatory = $true, ParameterSetName = 'InputObject', Position = 1)]
        [object[]]$InputObject
    )
    begin {
        
        if (!($Recurse) -and ($PSBoundParameters.ContainsKey('Path')))
        {
            $data = Get-Content -Path $Path -Raw | ConvertFrom-Json
        }
        elseif ($PSBoundParameters.ContainsKey('Path')) {
            $data = Get-ChildItem -Path $Path -Recurse -File | Where-Object Name -Match '.json$' | Get-Content -Raw  | ConvertFrom-Json
        }
        else {
            $data = $InputObject | ConvertFrom-Json
        }
    }
    
    process {
        
        foreach ($module in $data.Modules) 
        {
            [string[]]$modules += $module
        }
    }
    
    end {
        $modules | Select-Object -Unique
    }
}