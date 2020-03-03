function test-cred {

    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Management.Automation.PSCredential]$credential,
        [parameter()][validateset('Domain','Machine','ApplicationDirectory')]
        [string]$context = 'Domain'
    )
    begin {
        Add-Type -assemblyname system.DirectoryServices.accountmanagement
        $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::$context) 
    }
    process {
        $DS.ValidateCredentials($credential.UserName, $credential.GetNetworkCredential().password)
    }
}

    #Schakel onderstaande regel in als je cross forest een controle wilt uitvoeren.
		#$RemoteForestUser = $host.ui.PromptForCredential("Remote Forest User", "Voer gebruikersnaam en wachtwoord in van remote forest admin.", "", "")
		$dc = (Get-ADDomainController -discover -Domain "contoso.local").Hostname #Voer domein in waarin je credentials wilt testen
		$CheckCreds = $host.ui.PromptForCredential("Check User", "Voer gebruikersnaam en wachtwoord in voor controle.", "", "")
		$testuitslag = invoke-command $dc -scriptblock ${function:test-cred} -argumentlist $mycreds # -Credential $MyCredential  # Schakel -Crendetial in om cross forest te controleren.
    
    if ($testuitslag -eq "Authenticated"){
    
          write-host "gebruikersnaam en wachtwoord kloppen, gebruiker is geauthenticeerd."
          
        } else {
        
          $username = $CheckCreds.UserName
          $lockedout = invoke-command $dc -scriptblock { Param( $username ) (Search-ADAccount -LockedOut | Where-Object {$_.SamAccountName -eq $username }).LockedOut } -argumentlist $username # -Credential $MyCredential   # Schakel -Crendetial in om cross forest te controleren. 
          
          If ($lockedout -eq "True"){
				    [System.Windows.Forms.MessageBox]::Show("Account is gelocked, meld het bij de helpdesk.","Account locked out!","OK","Error")
			    } else {
				    [System.Windows.Forms.MessageBox]::Show("Wachtwoord is onjuist, probeer het opnieuw.","Wachtwoord fout!","OK","Error")
			    }
          
        }
        
    
