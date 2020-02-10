# This script will take a list of servers and supply the IP addresses
# Input server list
$server_list='./server_list.txt'

# Output server and IP list
$output_file='./server_ips.txt'

foreach($line in Get-Content $server_list) {
	$ip_add = ((Test-Connection -comp $line -Count 1).ipv4address.ipaddressToString)
	"${line} : ${ip_add}" | Out-File -Append $output_file
}
