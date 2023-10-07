function Set-FileAuditAcl {
    <#
    .SYNOPSIS
    Configures Object Access Audit ACL on local and remote files.
    .DESCRIPTION
    This function enables auditing of read access for both successful and
    failed attempts on specified files by the Everyone identity.
    Triggering Windows Security Event ID 4663 requires the corresponding
    Group Policy Object (GPO) to be enabled.
    .PARAMETER TokenPath
    The path(s) to the file(s) on which to configure the Audit ACL.
    Accepts a single file path, multiple file paths, or wildcards like "*".
    .PARAMETER Session
    (Optional) The PSSession object representing the remote host (for remote file configurations).
    .EXAMPLE
    Set-FileAuditAcl -TokenPath 'C:\Path\To\Your\Local\File.txt'
    Set-FileAuditAcl -TokenPath 'C:\Path\To\Your\Local\Files\*'  # Use wildcard for multiple files
    Set-FileAuditAcl -TokenPath 'C:\Path\To\Remote\File.txt' -Session $session
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Path")]
        [string[]]$TokenPath,

        [Parameter(Mandatory = $false, Position = 1)]
        [System.Management.Automation.Runspaces.PSSession]$Session
    )

    process {
        # Create a new audit rule
        $AuditFlags = [System.Security.AccessControl.AuditFlags]::Success, [System.Security.AccessControl.AuditFlags]::Failure
        $AuditRule = New-Object System.Security.AccessControl.FileSystemAuditRule(
            'Everyone',   # Specify the identity to audit (Everyone in this example)
            [System.Security.AccessControl.FileSystemRights]::Read, # Audit Read operations
            $AuditFlags # Success and Failure
        )

        try {
            foreach ($Path in $TokenPath) {
                if ($Session) {
                    # Use Invoke-Command to resolve the path in the remote session
                    $ResolvedPaths = Invoke-Command -Session $Session -ScriptBlock {
                        Resolve-Path $using:Path
                    }
                } else {
                    # Resolve the path locally
                    $ResolvedPaths = @(Resolve-Path $Path)
                }
                
                foreach ($ResolvedPath in $ResolvedPaths) {
                    $DestinationPath = $ResolvedPath.Path

                    # Check if the destination path exists, handling remote and local paths
                    $PathExists = $false
                    if ($Session) {
                    # For remote paths, we use Test-Path in the remote session
                        $PathExists = Invoke-Command -Session $Session -ScriptBlock {
                        Test-Path -Path $using:DestinationPath
                        }
                    } else {
                        # For local paths, we use Test-Path directly
                        $PathExists = Test-Path -Path $DestinationPath
                    }

                if ($PathExists -and ($Session -or -not (Test-Path -PathType Container -Path $DestinationPath))) {
                    $FileSecurity = New-Object System.Security.AccessControl.FileSecurity
                    $FileSecurity.AddAuditRule($AuditRule)

                        # Apply the modified security descriptor to the file
                        if ($Session) {
                            Invoke-Command -ScriptBlock {
                                Set-Acl -Path $using:DestinationPath -AclObject $using:FileSecurity -ErrorAction Stop
                            } -Session $Session
                        } else {
                            Set-Acl -Path $DestinationPath -AclObject $FileSecurity -ErrorAction Stop
                        }

                        Write-Host "Audit ACL configured for $DestinationPath" -ForegroundColor Green
                    } else {
                        Write-Host "File $DestinationPath does not exist. Skipping audit ACL configuration." -ForegroundColor Yellow
                    }
                }
            }
        } catch {
            Write-Error "Failed to configure Audit ACL: $_"
        }
    }
}
