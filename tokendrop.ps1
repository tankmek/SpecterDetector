function deployToken([string]$token_file, [hashtable]$endpoint) {
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
    # validate local file exists
    Write-Host '[-] Checking local file'
    if (! (Test-Path -Path $token_file)){
        Write-Host "[-] Error: $token_file not found!"
        return $false
    }
    $session = ""
    foreach ($computer in $endpoint.keys){
        Write-Host "[-] Accessing $computer" -ForegroundColor Green
        $session = (New-PSSession -ComputerName $computer -Credential $auth)
        foreach ($dest_file in $endpoint.$computer){
            $dest_path = Split-Path -Path $dest_file
            # check if remote file already exits
            Write-Host '[-] Checking remote file'
            if (! (Invoke-Command -ScriptBlock {
                 Test-Path -Path $using:dest_file } -Session $session)){
                Write-Host "[-] Remote file: $dest_file not present"
                Write-Host "[-] Checking path(s)"
                #TODO: Add prompt if path does not exist
                if (! (Invoke-Command -ScriptBlock {
                     Test-Path -Path $using:dest_path } -Session $session)){
                    Write-Host "[-] Creating remote file path"
                    Invoke-Command -Command {
                         New-Item -ItemType Directory $using:dest_path
                    } -Session $session
                }
                # Copy token to destination
                Write-Host '[-] Copying token to destination'
                Copy-Item -Path $token_file -Destination $dest_file -ToSession $session
                # Set Audit ACL 
                Write-Host '[-] Setting Audit ACL'
                sleep 3
                setTokenAcl $tokens.acl_tpl $session $dest_file
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
Deploys honey tokens to remote machines using hashtables for the each host
or a specific token can be deployed to a group of hosts in a single hashtable.
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
# $assets = @{}
$jump_box = @{}
$file_server = @{}
$admin_station_aws1 = @{}
$admin_station_aws2 = @{}
# Hash values are lists of potential destinations

$admin_station_aws1.Add('winblue1', @())
$admin_station_aws2.Add('winblue1', @())
$jump_box.Add('winblue2', @())
$file_server.Add('winblue3', @())
# Destinations for winblue1
$admin_station_aws1.winblue1 += 'c:\users\marcus.jones.sa\.aws\config'
$admin_station_aws2.winblue1 += 'c:\users\marcus.jones.sa\.aws\credentials'
# Destination for winblue2
$jump_box.winblue2 += 'c:\admin_tools\keepass\servers.kdbx'
# Destination for winblue3
$file_server.winblue3 += 'c:\backups\brocade_cfgs.zip'

# List of tokens to choose
$tokens = @{}
$tokens.Add('acl_tpl', 'c:\tokens\token_tpl.txt')
$tokens.Add('keepass', 'c:\tokens\servers.kdbx' )
$tokens.Add('brocade_cfg', 'c:\tokens\brocade_cfgs.zip')
$tokens.Add('aws_cfg', 'c:\tokens\.aws\config')
$tokens.Add('aws_creds', 'c:\tokens\.aws\credentials')

# Main
deployToken $tokens.aws_cfg $admin_station_aws1
deployToken $tokens.aws_creds $admin_station_aws2
deployToken $tokens.keepass $jump_box
deployToken $tokens.brocade_cfg $file_server

## TODO
# Add ability to change file ownership to 
# match file location if necessary
