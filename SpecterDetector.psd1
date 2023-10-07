@{
    # Script module file associated with this manifest.
    ModuleToProcess = 'SpecterDetector.psm1'
    
    ModuleVersion = '1.0.0'

    Author = 'Michael Edie'

    Copyright = 'GPLv3'

    # Unique identifier for this module
    GUID = 'bd530c6c-fd09-4027-9310-fdb324c382a9'

    Description = 'A PowerShell module for detecting security threats.'

    # Minimum version of PowerShell required to use this module
    PowerShellVersion = '2.0'

    # Functions to export from this module
    FunctionsToExport = @('Install-Token', 'Remove-Token', 'Set-FileAuditAcl')

    # Private data to pass to the module loader
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('blue team', 'security', 'defense', 'detection')

            # License URI 
            LicenseUri = 'https://www.gnu.org/licenses/gpl-3.0.en.html'

            # Project URI 
            ProjectUri = 'https://github.com/tankmek/SpecterDetector'

        }
    }
}
