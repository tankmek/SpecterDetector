
function deployToken([string]$token_file, [hashtable]$endpoint) {
<#
.SYNOPSIS
Deploys honey tokens to remote machines using WinRM
Author: Michael Edie @tankmek (https://blog.edie.io)
License: BSD 3-Clause
Required Dependencies: None
Optional Dependencies: None
.DESCRIPTION
Does a simple port scan using regular sockets, based (pretty) loosely on nmap
.PARAMETER token_file
Path to the token file on the staging machine
.PARAMETER endpoint
Hashtable of computer hostnames as keys and an array of destination paths
#>
    # validate local file exists
    Write-Host '[-] Checking local file'
    if (! (Test-Path -Path $token_file)){
        Write-Host "[-] Error: $token_file not found!"
        return $false
    }
    foreach ($computer in $endpoint.keys){
        Write-Host "[-] Accessing $computer" -ForegroundColor Green
        foreach ($dest_file in $endpoint.$computer){
            $dest_path = Split-Path -Path $dest_file
            # check if remote file already exits
            Write-Host '[-] Checking remote file'
            $session = (New-PSSession -ComputerName $computer -Credential $auth)
            if (! (Invoke-Command -command { Test-Path -Path $using:dest_file } -Session $session)){
                Write-Host "[-] Remote file: $dest_file not present"
                Write-Host "[-] Checking path"
                #TODO: Add prompt if path does not exist
                if (! (Invoke-Command -command { Test-Path -Path $using:dest_path } -Session $session)){
                    Write-Host "[-] Creating remote file path"
                    Invoke-Command -Command { New-Item -ItemType Directory $using:dest_path } -Session $session
                }
                # Copy token to destination
                Write-Host '[-] Copying token to destination'
                Copy-Item -Path $token_file -Destination $dest_file -ToSession $session
            } else {
                Write-Host "[-] Token: $dest_file already exists on $computer"
            }

            Remove-PSSession $session
        }
    }
}

Clear-Host
$banner = @'
  __          __                   __                   
 |  |_.-----.|  |--.-----.-----.--|  |.----.-----.-----.
 |   _|  _  ||    <|  -__|     |  _  ||   _|  _  |  _  |
 |____|_____||__|__|_____|__|__|_____||__| |_____|   __|
                                                 |__|   
@tankmek


'@

$banner
$auth = Get-Credential

$assets = @{}
# Values are list of potential destinations
$assets.Add('winblue1', @())
$assets.Add('winblue2', @())
$assets.Add('winblue3', @())
# Destinations for winblue1
$assets.winblue1 += 'c:\admin_tools\cisco-configs.zip'
$assets.winblue1 += 'c:\admin_tools\keepass\servers.kdbx'
$assets.winblue1 += 'c:\monkey\.aws\credentials'
$assets.winblue1 += 'c:\monkey\.aws\configs'
# Destination for winblue2
$assets.winblue2 += 'c:\monkey\ham\password.txt'
# Destination for winblue3
$assets.winblue3 += 'c:\monkey\vpn_configs.ovpn'
# List of tokens to choose
$tokens = @{}
$tokens.Add('keepass', 'c:\tokens\servers.kdbx' )
$tokens.Add('sshkey', '')
$tokens.Add('zipfile', 'c:\tokens\cisco-config.zip')
$tokens.Add('text_file', 'c:\tokens\yoda.txt')

# Main
deployToken $tokens.keepass $assets
