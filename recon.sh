echo 'Enter the option you want to do:'
echo '1.Nmap'
echo '2.subfinder+httpx+nuclei'
read -p "Your choice:" choice
if [ "$choice" = '1' ]; then
 echo "[*]You have selected nmap."
 read -p "[*]Enter the target address to nmap scan:" target
 nmap -A -sV -p1-65535 $target
fi
if [ "$choice" = '2' ]; then
 echo '[*]About to start subfinder,httpx-toolkit and nuclei'
 read -p 'Enter the domain to search:' domain
 echo '*********'
 subfinder -d $domain -silent > /tmp/subdomain.txt
 echo 'Subdomain.txt created at /tmp/subdomain.txt'
 echo '[*]Running httpx-toolkit'
 httpx-toolkit -l /tmp/subdomain.txt >/tmp/httpx_output.txt
  httpx-toolkit -l /tmp/subdomain.txt -status-code -title -silent
 echo '[*]Httpx-toolkit output created at /tmp/httpx_output.txt'
 rm /tmp/subdomain.txt
 echo '[*] subdomain.txt removed'
 nuclei -l /tmp/httpx_output.txt
fi
