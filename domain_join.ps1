.  "C:\ProgramData\QRM\WriteToLog.ps1"

LogWrite "Starting..."

# if already joined then don't do it again
if ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain -eq $false ) 
{
    $domain_name = "awsad".ToUpper()
    $domain_tld = "local"
    $secrets_manager_secret_id = "Windows/ServiceAccount/DomainJoin"

    $var = Invoke-WebRequest -Uri http://169.254.169.254/latest/dynamic/instance-identity/document
    $doc = $var | ConvertFrom-Json
    $ou_qrm_hpc = $doc.accountId

    LogWrite "Getting secret start..."
    $secret_manager = Get-SecSecretValue -SecretId $secrets_manager_secret_id
    LogWrite "Getting secret done..."
    $secret = $secret_manager.SecretString | ConvertFrom-Json
    $username = $domain_name.ToUpper() + "\" + $secret.ServiceAccount
    LogWrite $username
    $password = $secret.Password | ConvertTo-SecureString -AsPlainText -Force
    LogWrite "Converting to secure string..."
    $credential = New-Object System.Management.Automation.PSCredential($username,$password)
    
    Add-Computer -DomainName "$domain_name.$domain_tld" -OUPath "OU=$ou_qrm_hpc,OU=$domain_name,DC=$domain_name,DC=$domain_tld" -Credential $credential -Passthru -Verbose -Force -Restart
}

LogWrite "Done"