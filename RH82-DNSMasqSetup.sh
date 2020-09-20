#make sure the installation DVD is mounted
source ~/sitesetup/variables.sh

if [ ! -d /mnt/cdrom ] ; then mkdir /mnt/cdrom ; fi
if [ $(df | grep /mnt/cdrom | grep /dev/sr0 | wc -l) == 0 ]
then
  mount -o ro /dev/cdrom /mnt/cdrom
fi

yum -y install augeas dnsmasq

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

if [ $(cat /etc/hosts | grep -E "$IDMHOSTNAME|$IDMIP" | wc -l) != 0 ] 
then 
  cat > /tmp/hostsconfig << EOF
defvar mypath /files/etc/hosts
rm \$mypath/*[canonical="$IDMHOSTNAME"]
rm \$mypath/*[ipaddr="$IDMIP"]
save
EOF
augtool -s -f /tmp/hostsconfig
fi

cat > /tmp/hostsconfigIDM << EOF
defvar mypath /files/etc/hosts
ins 01 after \$mypath/2/
set \$mypath/01/ipaddr  $IDMIP
set \$mypath/01/canonical $IDMHOSTNAME
save
EOF
augtool -s -f /tmp/hostsconfigIDM

cat > /tmp/dnsmasqconfig << EOF
defvar mypath /files/etc/dnsmasq.conf
set \$mypath/no-dhcp-interface ens33
set \$mypath/bogus-priv
set \$mypath/domain $IDMDomain
set \$mypath/expand-hosts
set \$mypath/local /$IDMDomain/
set \$mypath/domain-needed
set \$mypath/no-resolv
set \$mypath/no-poll
set \$mypath/server[1] 8.8.8.8
set \$mypath/server[2] 4.2.2.4
save
EOF
augtool -s -f /tmp/dnsmasqconfig

if  [  $( firewall-cmd --query-service=dns) == 'no'  ]
then
  firewall-cmd --add-service=dns  --permanent
  firewall-cmd --reload
 fi

if [ $(systemctl is-enabled dnsmasq) == 'disabled'  ]
then
  systemctl enable dnsmasq
fi
 systemctl restart dnsmasq
