[cmdletbinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("DeployTokens", "RemoveTokens")][String] $Task = "DeployTokens"
)

function deployToken([hashtable]$endpoint) {
<#
.SYNOPSIS
Deploys honey tokens to remote machines using WinRM
Author: Michael Edie @tankmek (https://blog.edie.io)
License: BSD 3-Clause
Required Dependencies: None
Optional Dependencies: None
.DESCRIPTION
Deploys honey tokens to remote machines using hashtables for the each host
or a specific token can be deployed to a group of hosts in a single hashtable.
All communicaton to remote hosts uses WinRM.
.PARAMETER token_file
Path to the token file on the staging machine
.PARAMETER endpoint
Hashtable of computer hostnames as keys and an array of destination paths
#>

    foreach ($computer in $endpoint.keys){
        Write-Host "[-] Connecting to remote host: $computer" -ForegroundColor Green
        $session = (New-PSSession -ComputerName $computer -Credential $auth)
        foreach ($dest_file in $endpoint.$computer){
            $dest_path = Split-Path -Path $dest_file
            $token = Split-Path -Path $dest_file -Leaf
            $token_file = "$token_path$token"

            if (! (Invoke-Command -ScriptBlock {
                Test-Path -Path $using:dest_file } -Session $session)){

                #TODO: Add prompt if path does not exist
                if (! (Invoke-Command -ScriptBlock {
                    Test-Path -Path $using:dest_path } -Session $session)){

                    Invoke-Command -Command {
                        New-Item -ItemType Directory $using:dest_path
                    } -Session $session
                }
                # Check if token exists locally first
                Write-Host '[-] Validating local token(s)'
                if (! (Test-Path -Path $token_file)){
                    Write-Host "[-] Error: $token_file not found! Skipping"
                    #return $false
                    continue
                }
                # Copy token to destination
                Write-Host '[-] Dropping token:', $dest_file
                Copy-Item -Path $token_file -Destination $dest_file -ToSession $session
                # Set Audit ACL
                Write-Host '[-] Setting Audit ACL'
                Start-Sleep 3
                setTokenAcl $token_acl_tpl $session $dest_file
            } else {
                Write-Host "[-] Token: $dest_file already exists on $computer"
            }

        }
        Remove-PSSession $session
    }
}

function setTokenAcl(
<#
.SYNOPSIS
Sets the Audit ACL on specified honeytokens
Author: Michael Edie @tankmek (https://blog.edie.io)
License: BSD 3-Clause
Required Dependencies: None
Optional Dependencies: None
.DESCRIPTION
Sets Audit ACL on remote files
All communicaton to remote hosts uses WinRM.
.PARAMETER dest_file
Path a local file that has been configured with the desired audit acl
.PARAMETER session
PSSession of the host we have already established
.PARAMETER dest_file
Path to the honey token on the remote system
#>
        [string]$tokenAclTemplate,
        [System.Management.Automation.Runspaces.PSSession]$session,
        [string]$dest_file){

    $identity = "Everyone"
    $aclRights = "Read"
    $aclFlags  = 3 # Success & Failure

    $AuditRights = [System.Security.AccessControl.FileSystemRights]$aclRights
    $AuditFlags  = [System.Security.AccessControl.AuditFlags]$aclFlags

    # Remote Get-Acl does not produce the desired outputs
    #$auditAcl = Invoke-Command -ScriptBlock {Get-Acl -Path $using:file_path} -Session $session
    $auditAcl = Get-Acl -Path $tokenAclTemplate

    $accessRule = New-Object System.Security.AccessControl.FileSystemAuditRule($identity,
    $AuditRights, $AuditFlags)

    $auditAcl.SetAuditRule($accessRule)
    # TODO: Add try/catch
    Invoke-Command -ScriptBlock {
        Set-Acl -Path $using:dest_file -AclObject $using:auditAcl
    } -Session $session
}


function removeToken([hashtable]$remote_hosts){

    # TODO: add -Force if user wants to do this after a warning
    foreach ($computer in $remote_hosts.keys){
        Write-Host "[-] Connecting to remote host: $computer" -ForegroundColor Green
        $session = (New-PSSession -ComputerName $computer -Credential $auth)
        foreach ($dest_file in $remote_hosts.$computer){
            $dest_path = Split-Path -Path $dest_file
            # check if remote file is a directory
            #Write-Host '[-] Checking remote file'
            if (! (Invoke-Command -ScriptBlock {
                Test-Path -Path $using:dest_file } -Session $session)){
                Write-Host '[-] Remote token not found', $dest_file
                break
                # Does not remove directories by default
            } elseif ((Invoke-Command -ScriptBlock {
                Test-Path -Path $using:dest_file -PathType Container} -Session $session)) {
                Write-Host '[-] Warning: skipping directory token'
                break
            }
            # If we get here rm file
            # TODO: only prompt once for multiple files
            Write-Host '[-] Removing token(s)'
            Invoke-Command -ScriptBlock { Remove-Item -Path $using:dest_file } -Session $session

        }
        Remove-PSSession $session
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
# TODO: Add try/catch
$auth = Get-Credential
# Store token files here
$token_path = 'c:\users\mechanic\tokens\'
$token_acl_tpl = "$token_path" + 'token_tpl.txt'
# TODO: add option to read these from file
# List of tokens to choose
$key_terrain =@{}
# Hash values are lists of potential destinations
# TODO: capture hosts via AD OU
$key_terrain.Add('bruce', @())
$key_terrain.Add('hinata', @())
$key_terrain.Add('yagami', @())
# Destination on host to place tokens
# Script will create directories automatically
$key_terrain.hinata += 'c:\users\marcus.jones.sa\.aws\config'
$key_terrain.hinata += 'c:\users\marcus.jones.sa\.aws\credentials'
$key_terrain.bruce  += 'c:\backups\brocade_cfgs.zip'
$key_terrain.yagami += 'c:\admin_tools\keepass\servers.kdbx'

# Main
switch ($Task){
    "DeployTokens" { deployToken $key_terrain }
    "RemoveTokens" { removeToken $key_terrain }
}

# TODO: 
# Add feature to change file ownership to 
# match file location if necessary
