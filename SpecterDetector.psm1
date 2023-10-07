# Import individual function files from the "Public" directory
$functionFiles = Get-ChildItem -Path $PSScriptRoot\Public -Filter '*.ps1'
foreach ($file in $functionFiles) {
    . $file.FullName
}

# Export the functions to make them available to users
Export-ModuleMember -Function *



