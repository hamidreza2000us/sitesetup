#!/bin/bash
#ntpserver="192.168.1.189"
mynet="192.168.0.0/16"
yum -y install augeas chrony
cat > /tmp/chronyconfig << EOF
defvar mypath /files/etc/chrony.conf
rm /files/etc/chrony.conf/server
set \$mypath/#comment[last()+1] "=========================="
set \$mypath/#comment[last()+1] "##########################"
set \$mypath/#comment[last()+1] "configured using augtool"
#set \$mypath/server[1] $ntpserver
#set \$mypath/server[1]/iburst
set \$mypath/allow $mynet
save
EOF
augtool -s -f /tmp/chronyconfig
if [ "$(systemctl is-enabled ntpd)" == "enabled" ] 
  then 
  systemctl stop ntpd  ;
  systemctl disable ntpd ; 
  systemctl mask ntpd  ;
fi
if [ "$(systemctl is-enabled chronyd)" == 'disabled'  ]
then
  systemctl enable chronyd  
fi
systemctl restart  chronyd

if  [  $( firewall-cmd --query-service=ntp) == 'no'  ] ; then firewall-cmd --permanent --add-service=ntp ; fi
firewall-cmd --reload
chronyc sources -v
