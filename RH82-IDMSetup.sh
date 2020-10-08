source ~/sitesetup/variables.sh
yum module install -y idm:DL1/dns
yum -y install augeas

export HOSTNAME="$(hostname)"
export IP=${IP:="$(ip route get 8.8.8.8 | awk '{print $7; exit}')"}
if [ $(cat /etc/hosts | grep -E "$HOSTNAME|$IP" | wc -l) != 0 ] 
then 
  cat > /tmp/hostsconfig << EOF
defvar mypath /files/etc/hosts
rm \$mypath/*[canonical="$HOSTNAME"]
rm \$mypath/*[ipaddr="$IP"]
save
EOF
augtool -s -f /tmp/hostsconfig
fi


cat > /tmp/hostsconfig << EOF
defvar mypath /files/etc/hosts
ins 01 after \$mypath/2/
set \$mypath/01/ipaddr  $IP
set \$mypath/01/canonical $HOSTNAME
save
EOF
augtool -s -f /tmp/hostsconfig

#cat > /tmp/resolveconfig << EOF
#defvar mypath /files/etc/resolv.conf
#rm  \$mypath/nameserver
#set \$mypath/nameserver[last()+1] $ForemanIP
#save
#EOF
#augtool -s -f /tmp/resolveconfig
ReverseIP=$(echo ${IP} | awk -F. '{print $3"."$2"."$1".in-addr.arpa."}')
ipa-server-install --realm $IDMRealm --ds-password $IDMPass --admin-password $IDMPass --unattended --setup-dns --no-host-dns --auto-reverse --reverse-zone=$ReverseIP --forwarder $ForemanIP 

if  [  $( firewall-cmd --query-service=freeipa-ldap) == 'no'  ] ; then firewall-cmd --permanent --add-service=freeipa-ldap ; fi
if  [  $( firewall-cmd --query-service=freeipa-ldaps) == 'no'  ] ; then firewall-cmd --permanent --add-service=freeipa-ldaps ; fi
if  [  $( firewall-cmd --query-service=dns) == 'no'  ] ; then firewall-cmd --permanent --add-service=dns ; fi
if  [  $( firewall-cmd --query-service=ntp) == 'no'  ] ; then firewall-cmd --permanent --add-service=ntp ; fi
firewall-cmd --reload
if [ $(systemctl is-enabled chronyd) == 'disabled'  ]
then
  systemctl enable chronyd  
fi
systemctl restart chronyd
echo "$IDMPass" | kinit admin
ipa dnszone-mod $IDMDomain. --allow-sync-ptr=TRUE
ipa dnszone-mod $IDMDomain. --dnssec=false
ipa dnszone-mod $ReverseIP. --dnssec=false

sed -i -e 's/dnssec-enable yes;/dnssec-enable no;/' /etc/named.conf
sed -i -e 's/dnssec-validation yes;/dnssec-validation no;/' /etc/named.conf
ipactl restart
