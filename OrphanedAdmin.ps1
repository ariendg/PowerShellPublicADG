#Requires -Version 3.0
#Requires -Module ActiveDirectory

Function Get-OrphanAdminSdHolderUser {
    [CmdletBinding()]	
    Param()
    Begin {}
    Process {
    }
    End {	
        $UsersInAdminGroups = (Get-ADGroup -LDAPFilter '(adminCount=1)') | 
        ForEach-Object {
            # Get all users from all admin groups recursively
            Get-ADGroupMember $_ -Recursive | Where-Object {$_.ObjectClass -eq 'User'}
            # ...then sort them by distinguishedName to ensure accurate -Unique results (because some users might be in multiple protected groups)
        }  | Sort-Object distinguishedname | Select-Object -Unique
    
        #Get List of Admin Users (Past and Present) = $UsersFlaggedAsAdmin
        #Compare $UsersFlaggedAsAdmin to $Admins and place in appropriate hash table
        Get-ADUser -LDAPFilter '(adminCount=1)' |
        ForEach-Object {
            If ($_.samAccountName -notin $UsersInAdminGroups.samAccountName) {
                Write-Verbose -Verbose -Message ("ORPHAN`t`t{0}" -f $_.samAccountName)
                $_
            } else {
                Write-Verbose -Verbose -Message ("STILL ADMIN`t{0}" -f $_.samAccountName)
            }
        }
    }
    <#
        .SYNOPSIS
            Detects Orphaned SD Admin users
    
        .DESCRIPTION
            Get all users that are members of protected groups within AD and compares membership with users
            that have the AD Attribute AdminCount=1 set. If the user has the AdminCount=1 enabled but is 
            not a member of a protected group then the user is considered an orphaned admin user.
    
    #>
    }
    
    Function Clear-OrphanAdminSdHolderUser {
    [CmdletBinding(SupportsShouldProcess,ConfirmImpact='High')]
    Param(
       [parameter(Mandatory,ValueFromPipeline)]
       [Microsoft.ActiveDirectory.Management.ADPrincipal[]]$OrphanUser
    )
    Begin {}
    Process {
        $OrphanUser |
        Where-Object { $_.SamAccountName -ne 'krbtgt' } |
        ForEach-Object {
            $user = $_
            if ($pscmdlet.ShouldProcess($_,'Clear AdminCount and reset permissions inheritance')) {
                try {
                    $user | Set-ADUser -Clear {AdminCount} -ErrorAction Stop
                    Write-Verbose -Message ('Clearing AdminCount for {0}' -f $user.SamAccountName)
                } catch {
                    Write-Warning -Message "Failed to clear admincount property for $($user.SamAccountName) because $($_.Exception.Message)"
                }
            
                try  {
                    $Acl = Get-ACL -Path ('AD:\{0}' -f $user.DistinguishedName) -ErrorAction Stop
                    If ($Acl.AreAccessRulesProtected) {
                        $Acl.SetAccessRuleProtection($False, $True)
                        Set-ACL -AclObject $ACL -Path ('AD:\{0}' -f $user.DistinguishedName) -ErrorAction Stop
                        Write-Verbose -Message ('Enabling Inheritence for {0}' -f $user.SamAccountName)
                    } else {
                        Write-Verbose -Message ('Inheritence already set for {0}' -f $user.SamAccountName)
                    }
                } catch {
                    Write-Warning -Message "Failed to enable inheritence for $($user.SamAccountName) because $($_.Exception.Message)"
                }
            }
        }
    }
    End {}
    <#
        .SYNOPSIS
            Resets admin count attribute and enables inheritable permissions on AD user
    
        .DESCRIPTION
            The AdminCount attributed is cleared and inheritable permissions are reset
    
        .PARAMETER OrphanUser
            A list or array of ADUser objects
    
        .EXAMPLE
            Get-OrphanAdminSdHolderUser| Select -First 1 | Clear-OrphanAdminSdHolderUser -WhatIf
    
        .EXAMPLE
            Get-OrphanAdminSdHolderUser | Clear-OrphanAdminSdHolderUser
    #>
    }