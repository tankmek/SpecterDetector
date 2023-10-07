function Install-Token {
    <#
    .SYNOPSIS
    Deploys decoys to remote machines using a JSON configuration file.
    .DESCRIPTION
    Deploys decoys aka honeytokens to remote machines specified in a JSON configuration file.
    All communication to remote hosts uses WinRM.
    .PARAMETER ConfigFile
    The path to the JSON configuration file containing target hosts and token file paths.
    .EXAMPLE
    Deploy-Tokens -ConfigFile "C:\Path\To\Your\Config\config.json"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigFile
    )

    try {
        # Prompt the user for credentials
        $credential = Get-Credential

        # Load the JSON configuration file
        $config = Get-Content -Path $ConfigFile | ConvertFrom-Json

        # Create a hashtable to store sessions per computer
        $sessions = @{}
        $operations = @{}

        # Iterate through each file in the configuration
        foreach ($file in $config.Files) {
            $sourceFileName = [System.IO.Path]::GetFileName($file.SourcePath)
            foreach ($dest in $file.Destinations) {
                $computer = $dest.Computer
                $tokenPath = Join-Path -Path $dest.DestinationPath -ChildPath $sourceFileName
                
                # Check if a session already exists for this computer
                if (-not $sessions.ContainsKey($computer)) {
                    Write-Host "[-] Connecting to remote host: $computer" -ForegroundColor Green
                    $sessions[$computer] = New-PSSession -ComputerName $computer -Credential $credential
                }
                
                # Check if there are already operations for this computer
                if (-not $operations.ContainsKey($computer)) {
                    $operations[$computer] = @()
                }
                
                # Add the operation to the list for this computer
                $operations[$computer] += @{
                    SourcePath = $file.SourcePath
                    DestinationPath = $tokenPath
                }
            }
        }
        
        # Perform operations for each computer
        foreach ($computer in $operations.Keys) {
            Write-Host "[-] Performing operations on $computer" -ForegroundColor Yellow
            $session = $sessions[$computer]
            
            foreach ($operation in $operations[$computer]) {
                $sourcePath = $operation.SourcePath
                $destinationPath = $operation.DestinationPath
                
                Write-Host "[-] Deploying token to $destinationPath on $computer"
                Copy-Item -Path $sourcePath -Destination $destinationPath -ToSession $session -Recurse

                # Set Audit ACL
                Write-Host "[-] Setting Audit ACL for $destinationPath on $computer"
                Set-FileAuditAcl -TokenPath $destinationPath -Session $session
            }
            
            # Remove the session
            Remove-PSSession $session
        }
    } catch {
        Write-Error "An error occurred while deploying tokens: $_"
    }
}
