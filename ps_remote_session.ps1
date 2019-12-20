param (
	[alias('p')][switch]$encrypt_password = $false,
	[alias('h')][switch]$help = $false
)
# File to temporarily store encrypted password
$password_file = '.\enc_file.txt'

# Name of script
$script_name = $MyInvocation.MyCommand.Name


Write-Output 'You must be running this script as administrator.'
Write-Output "If you need help with this script, please run as follows: .\${script_name} -h"

function Secure-Password {
	Write-Output 'Please enter your password for this domain: '
	Read-Host -AsSecureString | ConvertFrom-SecureString | Out-File $password_file
}

function Print-Out-Help {
	Write-Output 'Help Section for Interactive PowerShell Remote Sessions'
	Write-Output '-------------------------------------------------------'
	Write-Output 'This script was born out of a need to minimise work for creating interactive remote sessions to servers via powershell.'
	Write-Output ''
	Write-Output 'Only one server can be accessed through an interactive session at a time. This script will pull the first server from the'
	Write-Output 'server_list.txt file, remove the server from that list and create an interactive session. When you next run this script, it will'
	Write-Output 'then choose the next server in that list. The server_list.txt file MUST reside in the same directory as this script.'
	Write-Output ''
	Write-Output 'CREATING ENCRYPTED PASSWORD FILE:'
	Write-Output 'Run this script with "-p" to encrypt your password for this domain once, which will then be applied for all servers in the'
	Write-Output 'list. This saves entering the password each time. Once the last server in the list has been accessed, the password file will be removed.'
	Write-Output ''
	Write-Output 'Be aware it may be the case that only servers in the same domain where the script is run from can be accessed via PS remote session.'
}

if($encrypt_password) {
	Secure-Password
	exit 0
}

if($help){
	Print-Out-Help
	exit 0
}

$username = $env:username


# List of servers to remote to
$server_list = '.\servers.txt'
# List of servers that have been completed
$completed_list = '.\completed_servers.txt'


# Server to remote to - first in the list of the file
$server = Get-Content $server_list -First 1



if ($server) {
	Write-Output "Remoting to ${server}."
} else {
	Write-Output "No servers left. Removing password file and exiting script."
	Remove-Item $password_file
	exit 0
}

# Store the current server in the file for completed servers
Add-Content -Path $completed_list -Value $server

# Get list of servers minus current server
$new_server_list = Get-Content $server_list | Select-Object -Skip 1 

# Update the content of the server_list file, removing the current server
Set-Content -Path $server_list -Value $new_server_list

# Get domain
if ($server -Match 'company_prod.domain') {
	$domain = 'company_prod'
	Write-Output "Domain: company_prod"
} elseif ($server -Match 'company_test.domain') {
	$domain = 'company_test'
	Write-Output "Domain: company_test"
} elseif ($server -Match 'company_proddmz.local') {
	$domain = 'company_proddmz'
	Write-Output "Domain: company_proddmz"
} elseif ($server -Match 'company_testdmz.local') {
	$domain = 'company_testdmz'
	Write-Output "Domain: company_testdmz"
} else {
	Write-Output "This server ${server} has a non-standard domain - script exiting now."
}

# Grab the encrypted password
$password = Get-Content $password_file | ConvertTo-SecureString

Write-Output "creds:"
Write-Output "${domain}\${username}"
Write-Output '-------------------'

# Create a credentials object for connecting 
$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "${domain}\${username}",$password

# Ensure psremoting is enabled
Enable-PSRemoting -Force

# Create interactive session
Enter-PSSession -ComputerName $server -Credential $credentials
